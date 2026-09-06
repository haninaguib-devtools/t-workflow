# 147 — Expose collaboration state through t-status
Issue: #147 · Part of: #139

## Asked
Extend `/t-status` so a maintainer can see, at a glance, where an externally
originated task sits — awaiting a preview, awaiting a human's verification, working
through feedback, waiting on a renewed review, or ready for `/t-ship` — derived from
the same workflow evidence the real gates already read, never a second manual status
field a human has to keep in sync.

## Done when
- `/t-status` can report that a task is awaiting preview, awaiting external
  verification, processing feedback, awaiting renewed review, or verified and ready
  for `/t-ship`.
- The displayed state identifies stale evidence caused by a newer commit.
- External-origin information is shown when present.
- Missing optional external systems do not prevent status reporting.
- Initiative summaries correctly derive progress from their task sub-issues.
- The precedence between blockers, failed checks, review findings, preview state, and
  human verification is documented and tested.
- Existing tasks continue to receive their current status classifications.

## Explicitly not
- Creating a separate workflow state database.
- Polling Proposarium.
- Allowing an observer to set t-workflow's authoritative state.
- Adding labels for every transient state.

## Origin
none

## Verification
none — this task declares no `verification:` entry of its own.

## Feedback
none — no feedback pass has run against this task itself.

## Decisions made along the way
- **One precedence table, in `docs/architecture/collaboration-state.md`, read by both
  `/t-status`'s prose and `derive-task-state.sh`'s fixtures** (haninaguib, via the
  driving session, 2026-09-06): the alternative — writing the ordering directly into
  `t-status/SKILL.md`'s prose with no separate script — would leave the trickiest part
  of this task (which of five simultaneously-true conditions wins) untestable by
  `plumbing-test.sh`, the same reasoning `check-verification-gate.sh` and
  `check-review-gate.sh` already follow for their own gates.
- **The preview-evidence channel is a PR comment carrying a fenced/flat JSON object
  matching `docs/adapters/PREVIEW.md`'s shape** (haninaguib, 2026-09-06): `PREVIEW.md`
  deliberately leaves the storage channel to each project's own tooling, so this task
  had to pick one to look in. A PR comment is the one channel that is already generic
  across forges, already part of `forge:pr-reviews`'s documented contract, and already
  named by ADR-010 §D7 as an evidence channel — so no new adapter operation was added
  for it. Documented as this task's own convention in
  `docs/architecture/collaboration-state.md`, not folded into `PREVIEW.md` itself as a
  retroactive requirement.
- **Mid-task re-plan: `.t-workflow/scripts/parse-task-record.sh` added as a second new
  script** (haninaguib, via the driving session, 2026-09-06), mirroring #145's own
  mid-task re-plan precedent. The first `/t-plan 147` did not anticipate that the
  markdown-parsing logic (a task record's `## Verification`/`## Feedback` sections,
  plus an issue's `## Plan` → `verification:` scope list) needed to be its own pure,
  fixture-testable script — the same testability boundary `check-verification-gate.sh`
  already draws between "pure classification, tested" and "live git/gh glue,
  untested" — rather than being buried, untestably, inside `status-snapshot.sh`'s own
  live preprocessing. Old Allowed paths (first plan): `.claude/skills/t-status/
  SKILL.md`, `.t-workflow/scripts/status-snapshot.sh`, `.t-workflow/scripts/
  derive-task-state.sh` (new), `.t-workflow/scripts/plumbing-test.sh`, `docs/
  architecture/collaboration-state.md` (new), this task's own record. New Allowed
  paths add exactly one line: `.t-workflow/scripts/parse-task-record.sh` (new).
  Re-planned via a second `/t-plan 147` before touching that file, per `/t-work`
  Phase 1 step 3's "work that grows onto a protected path stops for a plan."
- **`status-snapshot.sh`'s bulk PR query never requests GraphQL's `commits` field**
  (haninaguib, 2026-09-06): confirmed empirically against this repository — at
  `--limit 200`, `gh pr list --json ...,commits` traverses each commit's nested
  `authors` connection across every PR at once and exceeds GitHub's 500,000-node
  GraphQL ceiling. The head commit's timestamp is instead computed locally
  (`git show -s --format=%cI <sha>`) from the branch the same preprocessing loop has
  already fetched — no second GraphQL call, and no ceiling to hit regardless of how
  many PRs the repository accumulates.

## Deviations / notes
- none
