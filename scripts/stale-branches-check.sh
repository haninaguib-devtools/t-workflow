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
# Exit 0: scan completed and no stale branches found. Exit 1: a stale branch was found,
# the scan was cut off by the page limit, or a branch's existence could not be confirmed
# (auth/network/rate-limit failure) — none of these report as a clean pass. The whole
# point of this check is to catch a silent failure elsewhere; one that fails silently
# itself would defeat it, so an inconclusive result is treated the same as a bad one.
# Requires `gh`, authenticated, run from inside the repo (or GH_REPO set).
set -euo pipefail

grace_minutes="${1:-30}"
limit=500

repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
now_epoch=$(date -u +%s)
cutoff_epoch=$((now_epoch - grace_minutes * 60))

pr_count=$(gh pr list --state all --limit "$limit" --json number --jq 'length')
if [ "$pr_count" -eq "$limit" ]; then
  echo "stale-branches-check: hit the --limit of $limit PRs — this scan is incomplete, not reporting a clean result" >&2
  exit 1
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

# `gh api` exits non-zero both when a branch is confirmed gone (404) and when the
# request itself failed for an unrelated reason (bad/expired token, rate limit, network
# blip, insufficient scope). Treating both alike is exactly the silent-failure bug this
# script exists to catch: only a confirmed 404 means "not stale"; every other failure
# means "unknown", and unknown must never be reported as a clean pass.
found_stale=0
found_unknown=0
while IFS=$'\t' read -r branch number url; do
  [ -z "$branch" ] && continue
  if api_err=$(gh api "repos/$repo/branches/$branch" 2>&1 1>/dev/null); then
    echo "STALE: $branch still exists on origin (PR #$number, $url)"
    found_stale=1
  elif [[ "$api_err" == *"HTTP 404"* ]]; then
    : # confirmed deleted — the normal case
  else
    echo "UNKNOWN: could not confirm whether $branch still exists (PR #$number, $url): $api_err" >&2
    found_unknown=1
  fi
done <<< "$candidates"

if [ "$found_unknown" -eq 1 ]; then
  echo "stale-branches-check: one or more branch checks failed — not reporting a clean result" >&2
  exit 1
fi

if [ "$found_stale" -eq 1 ]; then
  echo "stale-branches-check: one or more merged/closed PRs left their branch behind" >&2
  exit 1
fi

echo "stale-branches-check: no stale branches found"
