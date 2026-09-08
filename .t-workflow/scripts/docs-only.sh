#!/usr/bin/env bash
# Is a set of changed paths documentation-only? The executable form of AGENTS.md
# §Checks' rule for check 1 (ADR-012): the project's build/test command runs unless
# every file a task changed is documentation, because a build cannot be affected by
# files it never reads. Checks 2 and 3, and the cold review where a protected surface
# requires one, are never subject to this script.
#
# The documentation set is defined HERE and nowhere else:
#   *.md      any Markdown file, anywhere in the tree
#   docs/**   anything under docs/
# plus whatever globs a project lists in AGENTS.md §Checks' "Documentation-only paths"
# local slot (docs/architecture/local-slots.md), one `- `<glob>`` bullet per line — a
# consumer whose documentation also lives in, say, site/** adds it there. The slot only
# ADDS paths; nothing can pull a file out of the default set. Anything else — code,
# config, workflows, scripts, .t-workflow/**, .github/**, .claude/**, the manifest — is
# not documentation, however harmless it looks.
#
# Globs use bash's == pattern operator, exactly as protected-paths.sh does: `*` crosses
# `/`, so `docs/*` already means "anything under docs/"; `**` is accepted as a synonym
# for `*` so the natural spelling `site/**` works.
#
# Usage:
#   git -c core.quotePath=false diff --name-only <trunk>...HEAD | docs-only.sh --stdin
#   docs-only.sh <path>...        the same, from arguments
#   docs-only.sh --list           print the globs in force (defaults + slot), one per line
#
# Exit codes — callers MUST distinguish 1 from 2, the same discipline as
# protected-paths.sh:
#   0  every path is documentation — check 1 may be skipped (and reported as skipped)
#   1  at least one path is not documentation — it is echoed to stdout; run check 1
#   2  no paths were given at all — nothing was checked; run check 1
# Exit 2 exists because an empty pipe is a broken caller, never a documentation-only
# diff. Read 2 as "run the build", never as "skip it".
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"

defaults=(
  '*.md'
  'docs/**'
)

# Globs from AGENTS.md's slot. Scoped to the "### Documentation-only paths" sub-heading
# inside "## Checks" — the same section-scoping idiom consistency-check.sh uses for the
# pipeline table's slot — never by counting marker pairs, so the slot may move within
# the file without this breaking. A file with no such heading (a consumer not yet synced
# to the release that added it) contributes nothing, and that is not an error.
slot_globs() {
  local agents="$root/AGENTS.md"
  [ -f "$agents" ] || return 0
  awk '/^### Documentation-only paths/ { f = 1; next } /^##/ { f = 0 } f' "$agents" \
    | awk '/^<!-- local -->$/ { s = 1; next } /^<!-- \/local -->$/ { s = 0 } s' \
    | sed -n -E 's/^- `([^`]+)`.*$/\1/p'
}

patterns=("${defaults[@]}")
while IFS= read -r g; do
  [ -n "$g" ] && patterns+=("$g")
done < <(slot_globs)

if [ "${1:-}" = "--list" ]; then
  printf '%s\n' "${patterns[@]}"
  exit 0
fi

paths=()
if [ "${1:-}" = "--stdin" ]; then
  while IFS= read -r line; do
    [ -n "$line" ] && paths+=("$line")
  done
else
  paths=("$@")
fi

if [ "${#paths[@]}" -eq 0 ]; then
  echo "docs-only: no paths given — nothing was checked" >&2
  exit 2
fi

is_doc() {
  local p="$1" pat
  for pat in "${patterns[@]}"; do
    pat="${pat//\*\*/*}"
    # shellcheck disable=SC2053 -- pattern matching is the point
    if [[ "$p" == $pat ]]; then
      return 0
    fi
  done
  return 1
}

rc=0
for path in "${paths[@]+"${paths[@]}"}"; do
  p="${path#./}"
  # Un-quote a git-style quoted path (core.quotePath=true, git's default, octal-escapes
  # a non-ASCII name and wraps it in quotes) — the same tolerance protected-paths.sh has,
  # so a mis-quoted documentation path does not force a build it never needed.
  if [ "${p#\"}" != "$p" ] && [ "${p%\"}" != "$p" ]; then
    p=${p#\"}; p=${p%\"}
    p=$(printf '%b' "$p")
  fi
  if ! is_doc "$p"; then
    echo "$p"
    rc=1
  fi
done
exit "$rc"
