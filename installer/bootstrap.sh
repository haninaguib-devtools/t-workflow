#!/usr/bin/env bash
# t-workflow installer — the part that runs after the clone.
#
# Never invoked directly by a person: installer/install.sh clones the template, resolves
# every answer (by flag or by prompt), and calls this with them in the environment. That
# is why nothing here prompts — by the time this runs, every question has an answer.
#
# Input (all set by install.sh):
#   TWORKFLOW_SRC         the clone to build the project from
#   TWORKFLOW_NAME        project name
#   TWORKFLOW_TARGET      directory to create
#   TWORKFLOW_REMOTE      yes | no
#   TWORKFLOW_VISIBILITY  private | public
#   TWORKFLOW_SOURCE_URL  where the clone came from, for the provenance line
#
# bash 3.2 compatible: macOS still ships it.
set -euo pipefail

die()  { printf 'installer: %s\n' "$*" >&2; exit 1; }
note() { printf '%s\n' "$*" >&2; }

src="${TWORKFLOW_SRC:?TWORKFLOW_SRC is not set — run installer/install.sh}"
name="${TWORKFLOW_NAME:?TWORKFLOW_NAME is not set}"
target="${TWORKFLOW_TARGET:?TWORKFLOW_TARGET is not set}"
remote="${TWORKFLOW_REMOTE:-no}"
visibility="${TWORKFLOW_VISIBILITY:-private}"
source_url="${TWORKFLOW_SOURCE_URL:-}"

[ -d "$src/.git" ] || die "$src is not a git clone."
[ -e "$target" ] && die "'$target' already exists."

# Read the provenance before the copy: .git is about to be deleted, and after that there
# is no way to say which version of the template this project came from.
ref=$(git -C "$src" rev-parse --short HEAD) || die "could not read the template's commit."
# The provenance line names a URL only when the template actually came from one. A
# --source pointing at a local path (how the test and local development run it) would
# otherwise stamp a temporary directory into the project's README as its origin.
case "$source_url" in
  http://*|https://*|git://*|ssh://*|*@*:*) browse_url="${source_url%.git}" ;;
  *)                                        browse_url="" ;;
esac

# --- the tree ---------------------------------------------------------------
# One wholesale copy, not a file-by-file reconstruction. `cp -R` copies a symlink as a
# symlink on both GNU and BSD, which is the whole point: CLAUDE.md, GEMINI.md,
# .agents/skills and .github/copilot-instructions.md are symlinks to the real files, and
# a copy that followed them would produce look-alike duplicates that then drift apart.
# From here on the target exists, so a failure must not leave a half-built tree behind:
# it would be a project with no commit and no explanation, and the next run would refuse
# because the directory already exists. One case opts out deliberately — see the git
# identity check below, which leaves the tree and tells the person how to finish it.
clean_target_on_failure=yes
cleanup_target() {
  status=$?
  if [ "$status" -ne 0 ] && [ "$clean_target_on_failure" = "yes" ]; then
    rm -rf "$target"
    printf 'installer: removed the partly built '\''%s'\'' — nothing was left half-done.\n' "$target" >&2
  fi
}
trap cleanup_target EXIT

cp -R "$src" "$target" || die "could not copy the template into '$target'."

# Everything the new project must not inherit.
#   .git       — this is a new project, not a fork of the template's history
#   LICENSE    — the template's MIT file names the template's copyright holder; putting
#                that on someone else's project would be wrong. They choose their own.
#   installer/ — a project does not ship the thing that made it, and
#   .github/workflows/installer.yml — nor the workflow that tests it. Left behind, that
#              workflow would reference ./installer/test.sh, which was just deleted, and
#              go red on the new project's first pull request for a reason its owner did
#              not cause and could not fix.
rm -rf "$target/.git" "$target/LICENSE" "$target/installer" \
       "$target/.github/workflows/installer.yml"

# Task records describe the template's own history. The shape of a record stays
# (TEMPLATE.md, README.md); the records themselves go.
if [ -d "$target/docs/tasks" ]; then
  find "$target/docs/tasks" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +
fi

# --- the project's README ---------------------------------------------------
# The template's own README describes the template. The new project gets its own, with
# the provenance line saying which commit of t-workflow produced it.
tpl="$src/installer/templates/README.md"
[ -f "$tpl" ] || die "the clone has no installer/templates/README.md."
readme=$(cat "$tpl")
readme=${readme//\{\{PROJECT_NAME\}\}/$name}
readme=${readme//\{\{TWORKFLOW_REF\}\}/$ref}
if [ -n "$browse_url" ]; then
  readme=${readme//\{\{TWORKFLOW_URL\}\}/$browse_url}
else
  readme=${readme//" — {{TWORKFLOW_URL}}"/}
fi
printf '%s\n' "$readme" > "$target/README.md"

# --- the first commit -------------------------------------------------------
# `git init -b main` needs git 2.28; symbolic-ref does the same on every version.
git init --quiet "$target"
git -C "$target" symbolic-ref HEAD refs/heads/main

# `git var` respects GIT_AUTHOR_* / GIT_COMMITTER_* as well as config, which `git config
# user.email` does not. Checking the wrong one would refuse a perfectly valid CI run.
if ! git -C "$target" var GIT_COMMITTER_IDENT >/dev/null 2>&1; then
  # The one failure worth keeping the tree for: everything is built and only the commit
  # is missing, so deleting it would throw away work the person can finish in one command.
  clean_target_on_failure=no
  die "git has no author identity, so the first commit cannot be made.
  The project tree is at '$target' — set an identity and commit it:
    git config --global user.name  \"Your Name\"
    git config --global user.email \"you@example.com\"
    cd '$target' && git add -A && git commit -m 'Bootstrap the delivery system'"
fi

git -C "$target" add -A
git -C "$target" commit --quiet -m "Bootstrap $name from the t-workflow delivery template

Generated by the t-workflow installer from $ref.
Genesis (CONSTITUTION.md section 3): this commit is made outside the pipeline
because there is no tracker and no main to open a pull request against yet.
The exception ends here — every change from now on goes through the pipeline."

# --- the remote -------------------------------------------------------------
# Never a hard failure. A local project with printed instructions is a good outcome; a
# half-created remote is not.
remote_done=no
if [ "$remote" = "yes" ]; then
  if ! command -v gh >/dev/null 2>&1; then
    note "GitHub CLI (gh) not found — skipping the remote."
  elif ! gh auth status >/dev/null 2>&1; then
    note "GitHub CLI is not logged in — skipping the remote. Run: gh auth login"
  elif gh repo create "$name" "--$visibility" --source "$target" --remote origin --push; then
    remote_done=yes
    note ""
    note "Applying repository settings (labels, squash-only merges, branch protection)..."
    if ( cd "$target" && ./scripts/github-bootstrap.sh ); then
      :
    else
      note "scripts/github-bootstrap.sh did not finish cleanly. Re-run it from '$target'."
    fi
  else
    note "Could not create the repository — the local project at '$target' is fine."
  fi
fi

# --- what the person needs to know ------------------------------------------
cat >&2 <<EOF

Created '$name' at $target
Generated from t-workflow @ $ref

Two things this installer cannot know, left for you to fill in:

  1. CONSTITUTION.md   section 4 — your stack and architecture constraints,
                       each one ratified by an ADR in docs/adr/.
  2. AGENTS.md         section Checks — your build/test command. That section is
                       the only place the workflow reads it from; add the same
                       command to .github/workflows/ci.yml as a third job.

No LICENSE file was created. A project with no licence is "all rights reserved" by
default, which is the safe place to start — add the one you want before publishing.
EOF

# Which of these is true decides how those two fills may be made, so it is stated
# rather than left for the person to work out. CONSTITUTION.md section 3: the genesis
# exception ends when the first commit is pushed.
if [ "$remote_done" = "yes" ]; then
  cat >&2 <<EOF

The remote repository exists and main has been pushed, so the genesis exception has
closed. Both fills above are now ordinary work: open each one with /t-open and let it
go through the pipeline like any other change. CONSTITUTION.md and AGENTS.md are
protected surfaces, so each needs a plan and a review — and branch protection will
refuse a direct push to main anyway.

    cd $target
    /t-open

EOF
else
  cat >&2 <<EOF

Nothing has been pushed yet, so the genesis exception is still open: you may make both
fills above by hand and fold them into the first commit.

    cd $target
    \$EDITOR CONSTITUTION.md AGENTS.md
    git add -A && git commit --amend --no-edit

Then create the repository and apply its settings:

    gh repo create $name --$visibility --source . --remote origin --push
    ./scripts/github-bootstrap.sh

That push closes the genesis exception. Every edit to the tree after it goes through
the pipeline, starting with /t-open.

EOF
fi
