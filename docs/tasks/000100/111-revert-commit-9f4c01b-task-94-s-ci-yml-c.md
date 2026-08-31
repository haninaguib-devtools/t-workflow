# 111 — Revert commit 9f4c01b (task #94's ci.yml consolidation) — broke sibling #95 mid-review
Issue: #111 · Part of: #93

## Asked
Task #94's merge (`9f4c01b`, PR #109) consolidated `ci.yml`'s per-event job set into
one job per trigger and landed on `main` while three sibling tasks under initiative
#93 — #95, #96, #98 — were independently in flight, all editing
`.github/workflows/ci.yml`, with no ordering declared between them. It broke #95's
already-reviewed, ready-to-ship PR with a real merge conflict caught mid-rebase at its
`/t-ship` run. Revert `ci.yml` and `github-bootstrap.sh` to their state immediately
before `9f4c01b` (commit `a506471`), so the initiative's remaining children land
against a stable baseline. #94's consolidation idea is not rejected — it can be redone
later, sequenced against its siblings, as a fresh task.

## Done when
- `git diff a5064712b820c652b77b9124ccec89c4e8957669 HEAD --
  .github/workflows/ci.yml .t-workflow/scripts/github-bootstrap.sh` shows no
  differences.
- `./.t-workflow/scripts/consistency-check.sh` and
  `./.t-workflow/scripts/plumbing-test.sh` both pass against the reverted tree.
- A rebase of #95's branch onto the new `main` no longer conflicts on
  `.github/workflows/ci.yml` (human-verified once #95 resumes, post-merge).

## Explicitly not
- Does not re-litigate whether #94's consolidation is a good idea — only that it landed
  out of sequence. Redoing it, sequenced against #95/#96/#98, is a separate future
  task, opened later if/when the human wants it.
- Does not change #95, #96, or #98 themselves.
- Does not touch `docs/tasks/000000/94-consolidate-ci-yml-s-per-event-job-set-i.md` —
  kept, per the decision below.

## Decisions made along the way
- **Task #94's record is kept, not deleted** (agent at `/t-plan`, 2026-08-30, under the
  delegation in the issue's non-goals; ratified in the issue's `## Plan`). A revert adds
  a new commit — `9f4c01b` stays in `main`'s history and the record is its only account
  (`docs/tasks/README.md`; `CONSTITUTION.md` §1.3). So the implementation is a two-file
  restore from `a506471`, not a whole-commit `git revert`, which would also have deleted
  that record.
- **The required-status-contexts flip happens at the merge gate, by hand** (planned at
  `/t-plan`, 2026-08-30). Live branch protection requires the post-#94 contexts
  (`checks`, `cold-review`) with `enforce_admins: true`; this PR's CI runs the reverted
  six-job `ci.yml`, which never reports `checks`. At `/t-ship`'s gate the human flips
  the required contexts back to the pre-#94 seven, merges, then re-runs
  `./.t-workflow/scripts/github-bootstrap.sh` after `main`'s push CI has run. A
  forge-settings operation, no diff (`CONSTITUTION.md` §3).

## Deviations / notes
- none
