#!/usr/bin/env bash
# t-workflow installer — retrofit mode (issue #172, docs/architecture/adoption.md).
#
# Adopts the t-workflow delivery system into a repository that already has code,
# history, and a team. Run from inside that repository, on its trunk:
#
#   /path/to/a/t-workflow/checkout/installer/adopt.sh [options]
#
# It never touches installer/, site/, README.md, or LICENSE — those are genesis-only
# (docs/architecture/manifest.md) and have nothing in an existing repository to sync to.
# Everything else the template owns is either added, merged by a fixed mechanical rule,
# renamed, or refused — never silently dropped, and consumer content is never deleted.
#
# docs/architecture/adoption.md (#166) is the binding design this script implements;
# read it for the rationale behind every rule below. This file states the rules, not
# the reasoning.
#
# bash 3.2 compatible: macOS still ships it, same as install.sh and bootstrap.sh.
set -euo pipefail

die()  { printf 'adopt: %s\n' "$*" >&2; exit 1; }
note() { printf '%s\n' "$*" >&2; }

usage() {
  cat <<'EOF'
Retrofit the t-workflow delivery system into an existing repository, in one command.

Usage:
  adopt.sh [options]

Run from inside the repository being adopted, on a clean checkout of its trunk, up to
date with its remote. Nothing is written until every precondition passes and the whole
plan is computed with no refusals.

Options:
  --ref <tag>             The template release to adopt. Must be a tag (never a branch
                          — the manifest pins a tag, docs/architecture/manifest.md).
                          Default: the template source's own latest tag.
  --source <url|path>     Where to fetch the template from. Default: the public
                          t-workflow repository.
  --template <owner/name> The manifest's "template" field. Default: parsed from
                          --source when it is a github.com URL; required otherwise
                          (a local path has no owner/name of its own).
  --build-command <cmd>   This repository's build/test command. Fills AGENTS.md
                          section Checks item 1 and adds it as a CI step. Omitted by
                          default — that section keeps the template's own placeholder,
                          same as a freshly generated project until a person fills it.
  --dry-run               Compute and print the plan, then stop. Nothing is written,
                          no issue is created, nothing is committed.
  -h, --help              Print this and exit.

Preconditions, checked before anything else: inside a git repository with a clean
tree, on its trunk, up to date with its remote; a logged-in `gh`; --ref resolves to a
real tag.

On success: an adoption issue is opened, a new branch (wip/<id>-adopt-t-workflow) is
checked out from the trunk, the merged tree is committed there — never pushed. The
push, draft-PR, /t-plan, and /t-review commands, plus github-bootstrap.sh as the step
after the PR merges, are printed on exit. Nothing here pushes, opens a PR, or changes
any forge-wide setting.
EOF
}

# --- arguments ----------------------------------------------------------------------
readonly DEFAULT_SOURCE="https://github.com/haninaguib-devtools/t-workflow.git"

ref=""
source_repo="$DEFAULT_SOURCE"
template_override=""
build_command=""
dry_run=no

need_value() { [ "$2" -ge 2 ] || die "$1 needs a value (see --help)"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --ref)             need_value --ref $#;             ref="$2";               shift 2 ;;
    --ref=*)                                             ref="${1#*=}";          shift ;;
    --source)          need_value --source $#;           source_repo="$2";       shift 2 ;;
    --source=*)                                          source_repo="${1#*=}";  shift ;;
    --template)        need_value --template $#;         template_override="$2"; shift 2 ;;
    --template=*)                                        template_override="${1#*=}"; shift ;;
    --build-command)   need_value --build-command $#;    build_command="$2";     shift 2 ;;
    --build-command=*)                                   build_command="${1#*=}"; shift ;;
    --dry-run) dry_run=yes; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; die "unknown option: $1" ;;
  esac
done

# --- tools --------------------------------------------------------------------------
command -v git >/dev/null 2>&1 || die "git is required and was not found on PATH."
command -v gh  >/dev/null 2>&1 || die "gh (the GitHub CLI) is required and was not found on PATH."
command -v jq  >/dev/null 2>&1 || die "jq is required and was not found on PATH."

# --- preconditions --------------------------------------------------------------------
root=$(git rev-parse --show-toplevel 2>/dev/null) || die "not inside a git repository."
cd "$root"

[ -z "$(git status --porcelain)" ] || die "the working tree is not clean. Commit or stash your changes first, then re-run."

gh auth status >/dev/null 2>&1 || die "gh is not logged in. Run 'gh auth login' first."

# The trunk's name, read from the forge itself (github-bootstrap.sh's own reasoning):
# this repository's own .t-workflow/scripts/trunk-ref.sh does not exist yet — that is
# exactly what this run is about to add — and origin/HEAD is not guaranteed to be set
# on every existing clone the way it would be right after a fresh `git clone`.
trunk=$(gh repo view --json defaultBranchRef -q '.defaultBranchRef.name' 2>/dev/null || true)
[ -n "$trunk" ] || die "could not read this repository's default branch from 'gh repo view'. Is 'gh' pointed at the right repository?"

current_branch=$(git symbolic-ref --short -q HEAD || true)
if [ "$current_branch" != "$trunk" ]; then
  die "not on the trunk branch ('$trunk'). Currently on '${current_branch:-a detached HEAD}' — check out $trunk first."
fi

git fetch --quiet origin "$trunk" || die "could not fetch origin/$trunk. Is 'origin' configured?"
local_head=$(git rev-parse HEAD)
remote_head=$(git rev-parse "origin/$trunk" 2>/dev/null || true)
[ -n "$remote_head" ] || die "no origin/$trunk after fetching — is 'origin' this repository's real remote?"
if [ "$local_head" != "$remote_head" ]; then
  die "'$trunk' is not up to date with origin/$trunk (local $local_head, remote $remote_head). Pull or push first."
fi

# --ref must resolve to a tag, never a branch (the manifest pins a tag).
if [ -z "$ref" ]; then
  ref=$(git ls-remote --tags --refs --sort=-v:refname "$source_repo" 2>/dev/null | head -1 | sed -n 's#.*refs/tags/##p')
  [ -n "$ref" ] || die "--source ($source_repo) has no tags to default --ref to. Pass --ref explicitly."
  note "No --ref given — defaulting to the template's latest tag: $ref"
fi
git ls-remote --exit-code --tags --refs "$source_repo" "refs/tags/$ref" >/dev/null 2>&1 \
  || die "--ref '$ref' is not a tag at $source_repo. --ref must be a tag, never a branch."
if git ls-remote --exit-code --heads "$source_repo" "refs/heads/$ref" >/dev/null 2>&1; then
  die "--ref '$ref' is a branch at $source_repo, not a tag. --ref must be a tag, never a branch."
fi

if [ -n "$template_override" ]; then
  template_name="$template_override"
else
  case "$source_repo" in
    *github.com*) template_name=$(printf '%s' "$source_repo" | sed -E 's#.*github\.com[:/]##; s#\.git$##') ;;
    *)            die "--source '$source_repo' is not a github.com URL — pass --template <owner/name> explicitly." ;;
  esac
fi

# --- scratch clone --------------------------------------------------------------------
scratch=$(mktemp -d "${TMPDIR:-/tmp}/t-workflow-adopt.XXXXXX") || die "could not create a temporary directory."
trap 'rm -rf "$scratch"' EXIT HUP INT TERM

note "Fetching the template ($ref)..."
clone_from="$source_repo"
if [ -d "$source_repo" ]; then
  abs=$(cd "$source_repo" && pwd) || die "cannot read --source directory: $source_repo"
  clone_from="file://$abs"
fi
git clone --quiet --depth 1 --branch "$ref" "$clone_from" "$scratch/tpl" \
  || die "could not clone $source_repo at '$ref'."

tpl="$scratch/tpl"
[ -f "$tpl/installer/consumer-tree.sh" ] \
  || die "the clone has no installer/consumer-tree.sh — is $source_repo a t-workflow template?"

tpl_paths_file="$scratch/tpl_paths.txt"
( cd "$tpl" && bash .t-workflow/scripts/template-owned-paths.sh --list ) > "$tpl_paths_file" \
  || die "could not list the template's own paths at $ref."

# The shared exclusion library (#171): turns the scratch clone into a consumer tree in
# place before anything is copied out of it — defense in depth alongside
# template-owned-paths.sh's own exclusion of the same paths.
# shellcheck source=/dev/null
. "$tpl/installer/consumer-tree.sh"
strip_consumer_exclusions "$tpl"

# --- plan -------------------------------------------------------------------------
plan_lines="$scratch/plan_lines.txt"
refuse_lines="$scratch/refuse_lines.txt"
generic_add="$scratch/generic_add.txt"
: > "$plan_lines"; : > "$refuse_lines"; : > "$generic_add"

plan()   { printf '%s\n' "$*" >> "$plan_lines"; }
refuse() { printf 'REFUSE %s\n' "$*" >> "$refuse_lines"; plan "REFUSE $*"; }

# Splices <replacement-file> into the Nth <!-- local --> ... <!-- /local --> pair of
# <file> (1-based, in document order). The same marker regex check-manifest.sh uses —
# leading whitespace and an optional "#" tolerated — so a bare marker (Markdown) and a
# commented, indented one (YAML) both match. <replacement-file> may be empty or absent
# (an absent path leaves the pair's content empty).
splice_local_slot() {
  local file="$1" occ="$2" replfile="${3:-}" tmp
  tmp=$(mktemp "$scratch/splice.XXXXXX") || die "mktemp failed"
  awk -v occ="$occ" -v replfile="$replfile" '
    BEGIN { n = 0; skip = 0 }
    /^[[:space:]]*#?[[:space:]]*<!-- local -->[[:space:]]*$/ {
      n++; print
      if (n == occ) {
        skip = 1
        if (replfile != "") { while ((getline line < replfile) > 0) print line; close(replfile) }
      }
      next
    }
    /^[[:space:]]*#?[[:space:]]*<!-- \/local -->[[:space:]]*$/ {
      if (n == occ) skip = 0
      print; next
    }
    skip { next }
    { print }
  ' "$file" > "$tmp" && mv "$tmp" "$file"
}

# --- 1. the CLAUDE.md / AGENTS.md / GEMINI.md / copilot-instructions.md alias group --
notes_tmp="$scratch/project_notes.txt"; : > "$notes_tmp"
harvested_any=no
for p in CLAUDE.md GEMINI.md AGENTS.md .github/copilot-instructions.md; do
  if [ -f "$p" ] && [ ! -L "$p" ]; then
    harvested_any=yes
    { printf '### From %s\n\n' "$p"; cat "$p"; printf '\n\n'; } >> "$notes_tmp"
    plan "MERGE $p -> AGENTS.md's Project notes slot (moved verbatim; $p becomes the template's own alias symlink)"
  else
    plan "ADD $p"
  fi
done

# --- 2. .gitignore --------------------------------------------------------------------
gitignore_merge=no
if [ -f .gitignore ]; then
  gitignore_merge=yes
  cp .gitignore "$scratch/consumer-gitignore.txt"
  plan "MERGE .gitignore -> template .gitignore's trailing local slot (consumer entries appended verbatim)"
else
  plan "ADD .gitignore"
fi

# --- 3. .github/workflows/ci.yml -------------------------------------------------------
ci_target=".github/workflows/ci.yml"
ci_legacy=".github/workflows/ci-legacy.yml"
ci_had_own=no
if [ -f "$ci_target" ]; then
  if [ -e "$ci_legacy" ]; then
    refuse "$ci_target (rename target $ci_legacy already exists too — move it out of the way first)"
  else
    ci_had_own=yes
    plan "RENAME $ci_target -> $ci_legacy (kept running unmodified; folding its steps into the template's ci.yml build slot is a follow-up for this team, noted in the record)"
    plan "ADD $ci_target (the template's own, trunk name and check-manifest step filled in)"
  fi
else
  plan "ADD $ci_target"
fi

# --- 4. .claude/skills/t-* reserved names ----------------------------------------------
tpl_skill_dirs=$(grep '^\.claude/skills/' "$tpl_paths_file" | sed -E 's#^\.claude/skills/([^/]+)/.*#\1#' | sort -u)
for d in $tpl_skill_dirs; do
  if [ -e ".claude/skills/$d" ]; then
    refuse ".claude/skills/$d (a skill directory already uses this reserved t-* name — the two cannot coexist)"
  else
    grep "^\.claude/skills/$d/" "$tpl_paths_file" >> "$generic_add"
    plan "ADD .claude/skills/$d/"
  fi
done

# --- 5. docs/adr/ numbering -------------------------------------------------------------
adr_collisions=""
if [ -d docs/adr ]; then
  for f in docs/adr/*.md; do
    [ -e "$f" ] || continue
    base=$(basename "$f")
    case "$base" in
      [0-9][0-9][0-9]-*)
        num=${base%%-*}
        if [ $((10#$num)) -lt 100 ]; then
          adr_collisions="${adr_collisions}${adr_collisions:+, }$base"
        fi
        ;;
    esac
  done
fi
if [ -n "$adr_collisions" ]; then
  refuse "docs/adr/* (this repository already numbers its own ADR(s) inside the template's 000-099 range: $adr_collisions — renumber them to 100 and up, then re-run)"
else
  grep '^docs/adr/' "$tpl_paths_file" >> "$generic_add"
  while IFS= read -r p; do plan "ADD $p"; done < <(grep '^docs/adr/' "$tpl_paths_file")
fi

# --- 6. everything else the template owns, add-if-absent / refuse-if-present -----------
handled="$scratch/handled.txt"
{
  printf '%s\n' CLAUDE.md GEMINI.md AGENTS.md .github/copilot-instructions.md .gitignore "$ci_target"
  grep '^\.claude/skills/' "$tpl_paths_file" || true
  grep '^docs/adr/' "$tpl_paths_file" || true
} > "$handled"

while IFS= read -r p; do
  [ -n "$p" ] || continue
  if [ -e "$p" ]; then
    refuse "$p (this template-owned path already exists here, with no automatic merge rule for it)"
  else
    printf '%s\n' "$p" >> "$generic_add"
    plan "ADD $p"
  fi
done < <(grep -v -F -x -f "$handled" "$tpl_paths_file" || true)

# --- print the plan, then stop on a refusal or --dry-run -------------------------------
note ""
note "Plan for adopting $template_name @ $ref:"
sed 's/^/  /' "$plan_lines" >&2
note ""

if [ -s "$refuse_lines" ]; then
  note "Refusing — nothing was written. Every collision above needs a person's judgment:"
  sed 's/^/  /' "$refuse_lines" >&2
  exit 1
fi

if [ "$dry_run" = yes ]; then
  note "--dry-run: nothing was written."
  exit 0
fi

# --- write: the tracker issue, then the branch (everything else needs the branch) ------
issue_body="$scratch/issue_body.md"
{
  echo "## Goal"
  echo "Retrofit this repository with the t-workflow delivery system (template $template_name @ $ref): its workflow skills, its constitution, and its document/record"
  echo "structure, merged in by \`installer/adopt.sh\` on this issue's own adoption branch (docs/architecture/adoption.md)."
  echo ""
  echo "## Done when"
  echo "- This branch's diff is planned (\`/t-plan\`) and independently reviewed (\`/t-review\`), then shipped like any other protected change."
  echo "- \`./.t-workflow/scripts/check-manifest.sh\` and \`./.t-workflow/scripts/consistency-check.sh\` both exit 0 on this branch."
  echo ""
  echo "## Scope"
  echo "Whatever \`installer/adopt.sh\` wrote or merged on this issue's own branch — the task record lists every decision it made."
  echo ""
  echo "## Non-goals"
  echo "- Pushing this branch, opening its pull request, or running \`.t-workflow/scripts/github-bootstrap.sh\` — \`installer/adopt.sh\` printed those as the next steps for a person to run."
  if [ "$ci_had_own" = yes ]; then
    echo "- Folding $ci_legacy's steps into the template's ci.yml build slot — left for this team; merging two CI files' semantics needs a person's judgment."
  fi
} > "$issue_body"

issue_title="Adopt t-workflow $ref"
issue_url=$(gh issue create --title "$issue_title" --body-file "$issue_body" --label enhancement) \
  || die "could not create the adoption issue."
issue_id=$(printf '%s' "$issue_url" | grep -oE '[0-9]+$' || true)
[ -n "$issue_id" ] || die "created an issue but could not parse its number from: $issue_url"
note "Opened issue #$issue_id: $issue_url"

marker="<!-- t-workflow:v1 (task=$issue_id) -->"
current_body=$(gh issue view "$issue_id" --json body -q .body 2>/dev/null || true)
gh issue edit "$issue_id" --body "$current_body

$marker" >/dev/null || die "issue #$issue_id was created but the correlation marker could not be written."

branch="wip/${issue_id}-adopt-t-workflow"
git checkout -b "$branch" || die "issue #$issue_id was created but the branch could not be created."

# --- write: the alias group ------------------------------------------------------------
rm -f CLAUDE.md GEMINI.md .github/copilot-instructions.md
mkdir -p .github
cp -R "$tpl/CLAUDE.md" CLAUDE.md
cp -R "$tpl/GEMINI.md" GEMINI.md
cp -R "$tpl/.github/copilot-instructions.md" .github/copilot-instructions.md
cp "$tpl/AGENTS.md" AGENTS.md
if [ "$harvested_any" = yes ]; then
  splice_local_slot AGENTS.md 4 "$notes_tmp"
fi
if [ -n "$build_command" ]; then
  cmd_line="$scratch/checks_item1.txt"
  printf '1. `%s` — this repository'"'"'s own build/test command; also run as the "Project checks" CI step below.\n' "$build_command" > "$cmd_line"
  splice_local_slot AGENTS.md 3 "$cmd_line"
fi

# --- write: .gitignore ------------------------------------------------------------------
cp "$tpl/.gitignore" .gitignore
if [ "$gitignore_merge" = yes ]; then
  splice_local_slot .gitignore 1 "$scratch/consumer-gitignore.txt"
fi

# --- write: ci.yml ------------------------------------------------------------------------
if [ "$ci_had_own" = yes ]; then
  mv "$ci_target" "$ci_legacy"
fi
mkdir -p .github/workflows
cp "$tpl/.github/workflows/ci.yml" "$ci_target"
if [ "$trunk" != "main" ]; then
  branches_line="$scratch/branches_line.txt"
  printf '    branches: [%s]\n' "$trunk" > "$branches_line"
  splice_local_slot "$ci_target" 1 "$branches_line"
fi
ci_tail="$scratch/ci_tail.txt"
: > "$ci_tail"
if [ -n "$build_command" ]; then
  {
    echo "      - name: Project checks"
    echo '        if: "!cancelled()"'
    printf '        run: %s\n' "$build_command"
  } >> "$ci_tail"
fi
{
  echo "      - name: Template manifest matches the working tree"
  echo '        if: "!cancelled()"'
  echo "        run: ./.t-workflow/scripts/check-manifest.sh"
} >> "$ci_tail"
splice_local_slot "$ci_target" 3 "$ci_tail"

# --- write: everything else the plan marked ADD ------------------------------------------
while IFS= read -r p; do
  [ -n "$p" ] || continue
  mkdir -p "$(dirname "$p")"
  rm -rf "$p"
  cp -R "$tpl/$p" "$p"
done < "$generic_add"

# --- write: the manifest, pinned to $ref -------------------------------------------------
all_final="$scratch/all_final.txt"
{
  cat "$generic_add"
  printf '%s\n' CLAUDE.md GEMINI.md AGENTS.md .github/copilot-instructions.md .gitignore "$ci_target"
} | sort -u > "$all_final"

migrations_applied=0
if [ -d "$tpl/migrations" ]; then
  for f in "$tpl"/migrations/V*__*.md; do
    [ -e "$f" ] || continue
    n=$(basename "$f" | sed -n 's/^V\([0-9][0-9]*\)__.*/\1/p')
    if [ -n "$n" ] && [ "$n" -gt "$migrations_applied" ]; then migrations_applied="$n"; fi
  done
fi

files_json=$(
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    h=$(./.t-workflow/scripts/check-manifest.sh --hash-file "$p") || die "could not hash $p for the manifest."
    printf '%s\t%s\n' "$p" "$h"
  done < "$all_final" \
  | jq -R -s 'split("\n") | map(select(length > 0) | split("\t")) | map({(.[0]): .[1]}) | add // {}'
)
jq -n --arg template "$template_name" --arg tag "$ref" --argjson migrations "$migrations_applied" --argjson files "$files_json" \
  '{template: $template, tag: $tag, migrations_applied: $migrations, files: $files}' \
  > .template-manifest.json

# --- write: the task record ---------------------------------------------------------------
bucket=$(printf '%06d' $(( (10#$issue_id / 100) * 100 )))
record_dir="docs/tasks/$bucket"
record_file="$record_dir/${issue_id}-adopt-t-workflow.md"
mkdir -p "$record_dir"
author=$(git config user.name 2>/dev/null || true)
[ -n "$author" ] || author="the person who ran installer/adopt.sh"
{
  echo "# $issue_id — Adopt t-workflow $ref"
  echo "Issue: #$issue_id"
  echo ""
  echo "## Asked"
  echo "Retrofit this repository with the t-workflow delivery system (template $template_name @ $ref), merging what could be merged mechanically and refusing on anything"
  echo "that needed a human's judgment (docs/architecture/adoption.md)."
  echo ""
  echo "## Done when"
  echo "- This branch is planned and independently reviewed like any other protected change, then shipped."
  echo "- \`./.t-workflow/scripts/check-manifest.sh\` and \`./.t-workflow/scripts/consistency-check.sh\` both exit 0 here."
  echo ""
  echo "## Explicitly not"
  echo "- Pushing this branch, opening its pull request, or running \`.t-workflow/scripts/github-bootstrap.sh\` — printed as the next steps for a person to run."
  if [ "$ci_had_own" = yes ]; then
    echo "- Folding $ci_legacy's steps into the template's ci.yml build slot — left for this team as their own follow-up."
  fi
  echo ""
  echo "## Origin"
  echo "none"
  echo ""
  echo "## Verification"
  echo "none"
  echo ""
  echo "## Feedback"
  echo "none"
  echo ""
  echo "## Decisions made along the way"
  echo "- \`installer/adopt.sh\` computed and applied the plan below automatically ($author, $(date -u +%Y-%m-%d)):"
  sed 's/^/  /' "$plan_lines"
  echo ""
  echo "## Deviations / notes"
  echo "none"
} > "$record_file"

# --- commit, never push --------------------------------------------------------------------
git add -A
git commit --quiet -m "Adopt t-workflow $ref into this repository

installer/adopt.sh merged the delivery system's skills, scripts, constitution, and
document structure per docs/architecture/adoption.md. Every decision it made is listed
in $record_file.

Task: #$issue_id"

# --- report ------------------------------------------------------------------------------
note ""
note "Adopted $template_name @ $ref onto a new branch — nothing pushed yet."
note ""
note "  Issue:   #$issue_id ($issue_url)"
note "  Branch:  $branch (checked out here, one commit)"
note "  Record:  $record_file"
note "  Manifest: .template-manifest.json"
note ""
note "CI's new gates land strict on this branch, same as a freshly generated project's"
note "(docs/architecture/adoption.md §3) — they block nothing on the forge until a person"
note "runs github-bootstrap.sh below, on their own schedule, after the adoption PR merges."
note ""
note "Next, in order:"
note "  git push -u origin $branch"
note "  gh pr create --draft --base $trunk --title \"[$issue_id] Adopt t-workflow $ref\" --body \"Closes #$issue_id\""
note "  /t-plan $issue_id"
note "  /t-review $issue_id"
note ""
note "After that PR merges (forge-wide settings only — never the tree, run once):"
note "  ./.t-workflow/scripts/github-bootstrap.sh"
