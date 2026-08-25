#!/usr/bin/env bash
# Tests the installer by running it for real and asserting the project it produces.
#
# It clones the repository this file lives in, so it tests COMMITTED state — commit
# before running it locally, or you are testing the previous version of your change. In
# CI that is exactly right: the runner checks out the merge commit.
#
# Usage: installer/test.sh          (from anywhere; paths are resolved from this file)
# Exit 0 = every assertion passed.
set -uo pipefail

here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/.." && pwd)

pass=0
fail=0
ok()   { pass=$((pass + 1)); printf '  ok   %s\n' "$*"; }
bad()  { fail=$((fail + 1)); printf '  FAIL %s\n' "$*"; }
check() { # check <description> <command...>
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then ok "$desc"; else bad "$desc"; fi
}

work=$(mktemp -d "${TMPDIR:-/tmp}/t-workflow-test.XXXXXX") || exit 2
trap 'rm -rf "$work"' EXIT HUP INT TERM

# The generated project gets a commit, which needs an identity. A contributor's machine
# has one; a fresh CI runner does not. Setting it only for this test's environment leaves
# the caller's git configuration untouched.
export GIT_AUTHOR_NAME="${GIT_AUTHOR_NAME:-t-workflow installer test}"
export GIT_AUTHOR_EMAIL="${GIT_AUTHOR_EMAIL:-installer-test@example.invalid}"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

echo "Testing installer against $root"
echo

# Clone from a throwaway bare repository whose `main` is this working tree's HEAD,
# rather than from $root directly. `git clone` needs the source to have a resolvable
# branch, and a CI runner checks out a detached HEAD — pushing `HEAD:refs/heads/main`
# gives the installer a real branch to fetch whatever state the caller is testing.
srcrepo="$work/source.git"
git init --quiet --bare "$srcrepo" || exit 2
git -C "$root" push --quiet "$srcrepo" "HEAD:refs/heads/main" || {
  echo "could not stage the test source from $root — is HEAD committed?" >&2
  exit 2
}

# --- 1. --help works without touching the network ---------------------------
echo "--help"
help_out=$(bash "$root/installer/install.sh" --help 2>&1); help_rc=$?
[ "$help_rc" -eq 0 ] && ok "exits 0" || bad "exits 0 (got $help_rc)"
for flag in --name --dir --no-remote --remote --private --public --source --ref --help; do
  case "$help_out" in *"$flag"*) ok "documents $flag" ;; *) bad "documents $flag" ;; esac
done
echo

# --- 2. a full non-interactive run ------------------------------------------
echo "install --name demo --no-remote"
# stdin is closed on purpose: a prompt that read stdin instead of /dev/tty would show up
# here as a hang or an empty answer rather than passing quietly.
run_out=$(bash "$root/installer/install.sh" \
            --name demo --dir "$work" --no-remote \
            --source "$srcrepo" </dev/null 2>&1); run_rc=$?
if [ "$run_rc" -ne 0 ]; then
  bad "exits 0 (got $run_rc)"
  printf '%s\n' "$run_out" | sed 's/^/    /'
  echo
  echo "$pass passed, $((fail + 1)) failed"
  exit 1
fi
ok "exits 0 with no prompts"

demo="$work/demo"
check "creates the project directory"          test -d "$demo"
echo

# --- 3. what the generated project must not carry ----------------------------
echo "stripped"
check "no installer/ directory"                test ! -e "$demo/installer"
check "no LICENSE"                             test ! -e "$demo/LICENSE"
check "no leftover task records"               test -z "$(find "$demo/docs/tasks" -mindepth 1 -maxdepth 1 -type d)"
check "docs/tasks keeps TEMPLATE.md"           test -f "$demo/docs/tasks/TEMPLATE.md"
check "docs/tasks keeps README.md"             test -f "$demo/docs/tasks/README.md"
echo

# --- 4. symlinks survived the copy ------------------------------------------
# A copy that follows symlinks produces files that look right and then drift apart from
# the originals forever. This is the assertion that catches it.
echo "symlinks"
for link in CLAUDE.md GEMINI.md .agents/skills .github/copilot-instructions.md; do
  check "$link is still a symlink"             test -L "$demo/$link"
done
echo

# --- 5. a fresh history, not the template's ---------------------------------
echo "git"
count=$(git -C "$demo" rev-list --count HEAD 2>/dev/null || echo x)
[ "$count" = "1" ] && ok "exactly one commit" || bad "exactly one commit (got $count)"
check "not a shallow clone"                    test ! -e "$demo/.git/shallow"
check "no origin remote"                       test -z "$(git -C "$demo" remote 2>/dev/null)"
branch=$(git -C "$demo" symbolic-ref --short HEAD 2>/dev/null || echo none)
[ "$branch" = "main" ] && ok "trunk is main" || bad "trunk is main (got $branch)"
check "working tree is clean"                  test -z "$(git -C "$demo" status --porcelain)"
echo

# --- 6. the README ----------------------------------------------------------
echo "README"
check "provenance line, matched by shape" \
  grep -qE '^Generated from t-workflow @ [0-9a-f]{7,}' "$demo/README.md"
check "carries the project name"               grep -q '^# demo$' "$demo/README.md"
check "no unsubstituted placeholders"          bash -c '! grep -q "{{" "$1"' _ "$demo/README.md"
check "differs from the template's own README" bash -c '! cmp -s "$1" "$2"' _ "$demo/README.md" "$root/README.md"
# --source pointed at a local directory here, so there is no origin URL to name. The
# provenance line must degrade to the hash alone rather than stamping a temporary path
# into the project's README as its origin.
check "no local source path in the provenance line" \
  bash -c '! grep -q "Generated from t-workflow @ .* — /" "$1"' _ "$demo/README.md"
echo

# --- 7. the generated project is internally consistent -----------------------
echo "consistency"
if ( cd "$demo" && ./scripts/consistency-check.sh ) >/dev/null 2>&1; then
  ok "scripts/consistency-check.sh passes inside the generated project"
else
  bad "scripts/consistency-check.sh passes inside the generated project"
  ( cd "$demo" && ./scripts/consistency-check.sh ) 2>&1 | sed 's/^/    /'
fi
check "installer/ is protected in the generated project" \
  bash "$demo/scripts/protected-paths.sh" installer/anything.sh
echo

# --- 8. the closing message says the two things it must ----------------------
echo "closing message"
case "$run_out" in *"No LICENSE file was created"*) ok "states that no LICENSE was created" ;;
                   *) bad "states that no LICENSE was created" ;; esac
case "$run_out" in *CONSTITUTION.md*) ok "names CONSTITUTION.md as a thing to fill in" ;;
                   *) bad "names CONSTITUTION.md as a thing to fill in" ;; esac
case "$run_out" in *AGENTS.md*) ok "names AGENTS.md as a thing to fill in" ;;
                   *) bad "names AGENTS.md as a thing to fill in" ;; esac
echo

# --- 9. refusing an existing directory --------------------------------------
echo "refusals"
if bash "$root/installer/install.sh" --name demo --dir "$work" --no-remote \
        --source "$srcrepo" </dev/null >/dev/null 2>&1; then
  bad "refuses to overwrite an existing directory"
else
  ok "refuses to overwrite an existing directory"
fi
if bash "$root/installer/install.sh" --name "../escape" --dir "$work" --no-remote \
        --source "$srcrepo" </dev/null >/dev/null 2>&1; then
  bad "rejects a path-traversing project name"
else
  ok "rejects a path-traversing project name"
fi
# Without a controlling terminal there is nowhere to prompt, so a missing --name must
# fail fast rather than block on a device that will never answer. Only assertable where
# there genuinely is no terminal — which is the case in CI, and not at a developer's
# shell.
if { true >/dev/tty; } 2>/dev/null; then
  echo "  skip a terminal is attached, so the no-tty refusal is not assertable here"
else
  runner=""
  command -v timeout >/dev/null 2>&1 && runner="timeout 30"
  if $runner bash "$root/installer/install.sh" --no-remote \
          --source "$srcrepo" </dev/null >/dev/null 2>&1; then
    bad "refuses to prompt when there is no terminal"
  else
    ok "refuses to prompt when there is no terminal"
  fi
fi
echo

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
