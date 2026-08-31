# 97 — Stop review-gate.yml showing cold-review as failed on a freshly-opened draft PR
Issue: #97 · Part of: #93

## Asked
`review-gate.yml` runs `cold-review` on `pull_request: opened` (and `reopened`) — the
instant a draft PR exists, before any review could possibly have been posted. The check
then fails with "no review on this PR", so every protected task's required `cold-review`
check shows red for its entire work-in-progress window, from PR creation through however
many `/t-work` fix passes happen, until `/t-review` finally posts. That's misleading
noise on a required check. Narrow the `pull_request:` trigger to `synchronize` only,
relying on `pull_request_review: submitted` to produce the first real evaluation, so a
freshly-opened PR shows the check as pending/expected rather than failed.

## Done when
- `review-gate.yml`'s `pull_request:` trigger lists only `synchronize`.
- A freshly-opened draft PR on a protected surface no longer shows `cold-review` as
  failed; it shows as pending/expected until a review is submitted.
- A push after an existing review still re-triggers `cold-review` and still correctly
  fails it as stale.
- Merging with no review still blocked by branch protection (unchanged).

## Explicitly not
- Does not change `check-review-gate.sh`'s staleness/isolation logic.
- Does not change the required-status-checks list itself (`cold-review` stays required).

## Decisions made along the way
- Kept `synchronize` rather than removing the `pull_request:` trigger entirely: it's
  needed for the stale-review re-check (Done-when item 3) — confirmed at plan time
  (hani, 2026-08-30).

## Deviations / notes
- none
