# 142 — Allow t-drive to stop before shipping
Issue: #142 · Part of: #139

## Asked
Allow an attended `/t-drive` run to carry a task through implementation and
independent review, then stop cleanly while the draft PR undergoes asynchronous
preview or contributor verification. The maintainer must be able to resume shipping
later without replaying completed stages unnecessarily.

## Done when
- `/t-drive` supports a documented stopping point after review and before `/t-ship`.
- The stopping point works for a standalone task and for initiative child tasks where
  appropriate.
- The command reports why work has paused and what evidence or action is awaited.
- A later invocation resumes from the correct stage.
- Stale review, changed commits, failed checks, and unresolved human verification are
  detected on resumption.
- The default behavior is documented clearly and does not accidentally bypass the
  human merge confirmation.
- Existing initiative-driving behavior remains compatible.

## Explicitly not
- Unattended merging.
- Keeping an agent session running while waiting for a contributor.
- Making previews mandatory.
- Replacing `/t-ship`.

## Origin
none — initiative #139 carries no `## Origin` section of its own to inherit
(corrected during aggregate-PR assembly; the original record incorrectly claimed
inheritance).

## Verification
none — this task builds the general mechanism; it declares no `verification:` entry
of its own.

## Feedback
none — no feedback pass has run against this task itself.

## Decisions made along the way
- **No new ADR** (haninaguib, via the driving session, 2026-09-06): ADR-010 §D6
  already names this exact task ("An attended `/t-drive` run may stop cleanly after
  review and before shipping … resuming later without replaying completed stages
  unnecessarily (#142)"). Adding a documented pause is a tightening
  (`docs/workflow.md` §11.2/§11.3), not a loosening, so it needs no ADR-grade
  rationale on its own.
- **The pause is implemented as "don't take the next chained step," not a new
  refusal mechanism**: solo mode simply does not invoke `/t-ship` while a required
  verification entry is unresolved or stale; initiative mode simply does not merge
  the child into the integration branch. Neither marks a PR ready, approves, or
  merges — the merge-confirmation gate is never reached in the paused case, which is
  what makes bypassing it structurally impossible rather than merely avoided by
  convention.
- **Reused `check-verification-gate.sh` and (for solo mode) `check-review-gate.sh`
  verbatim, added no new scripts.** Child mode's own staleness probe could not reuse
  `check-review-gate.sh` directly — that script's "not protected → OK, no review
  needed" branch is correct for solo mode (ADR-006 D5: review is conditional there)
  but wrong for child mode (ADR-004 Decision 1: review is unconditional there) — so
  child mode's probe is written out as the same two comparisons
  (`readiness: ready` present; latest review's `submittedAt` not older than the head
  commit) without delegating to that script.
- **A stale/missing review is treated as "review not yet run", never as a
  `not-ready` verdict** — it does not consume the one-bounded-retry budget
  ADR-004 Decision 2 / ADR-006 D4 reserve for fixing real findings. Only an actual
  `not-ready` verdict, or a failing named check, spends that retry — reached exactly
  as before, just possibly on a later invocation instead of the same one.
- **A held-for-verification child spends no retry and is never excluded** — it is a
  third "not yet eligible to merge" reason alongside the existing sibling-hold, using
  the same non-terminal shape; Phase 3's aggregate PR is not attempted while any
  child is in this state, so a driven run does not paper over an unresolved child by
  proceeding anyway.

## Deviations / notes
none.
