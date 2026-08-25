#!/usr/bin/env bash
# Reports task/fix branches (`wip/*`, `fix/*`) that a merged or closed PR should have
# deleted but did not — see issue #13. `forge:pr-merge`/`forge:pr-close` delete the head
# branch as a side effect of the exact command run (`docs/adapters/FORGE.md`); a wrong
# command (typed from memory instead of copied) silently leaves the branch behind, and
# nothing else in the repo notices. This is that backstop.
#
# This script only reports. It never deletes a branch — that stays a human decision.
#
# Usage: scripts/stale-branches-check.sh [grace-minutes]
#   grace-minutes  Skip PRs merged/closed more recently than this (default 30). Gives an
#                   in-flight /t-ship, /t-fix, or /t-cancel run room to finish its own
#                   branch deletion before a scheduled run flags it.
#
# Exit 0: no stale branches (or none old enough to check). Exit 1: at least one found.
# Requires `gh`, authenticated, run from inside the repo (or GH_REPO set).
set -euo pipefail

grace_minutes="${1:-30}"
limit=500

repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
now_epoch=$(date -u +%s)
cutoff_epoch=$((now_epoch - grace_minutes * 60))

pr_count=$(gh pr list --state all --limit "$limit" --json number --jq 'length')
if [ "$pr_count" -eq "$limit" ]; then
  echo "stale-branches-check: hit the --limit of $limit PRs — this scan may be incomplete" >&2
fi

# One line per candidate: branch, PR number, PR url. Filtering (branch prefix, has a
# merge/close timestamp, older than the grace period) happens here so only real
# candidates reach the network round-trip below.
candidates=$(gh pr list --state all --limit "$limit" \
  --json number,headRefName,mergedAt,closedAt,url \
  --jq '.[]
    | select(.headRefName | test("^(wip|fix)/"))
    | select((.mergedAt // .closedAt) != null)
    | select(((.mergedAt // .closedAt) | fromdateiso8601) < '"$cutoff_epoch"')
    | [.headRefName, (.number | tostring), .url]
    | @tsv')

found_stale=0
while IFS=$'\t' read -r branch number url; do
  [ -z "$branch" ] && continue
  if gh api "repos/$repo/branches/$branch" >/dev/null 2>&1; then
    echo "STALE: $branch still exists on origin (PR #$number, $url)"
    found_stale=1
  fi
done <<< "$candidates"

if [ "$found_stale" -eq 1 ]; then
  echo "stale-branches-check: one or more merged/closed PRs left their branch behind" >&2
  exit 1
fi

echo "stale-branches-check: no stale branches found"
