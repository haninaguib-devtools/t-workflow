# 98 — Skip CI on draft PRs; run it on ready_for_review
Issue: #98 · Part of: #93

## Asked
`.github/workflows/ci.yml`'s jobs currently run on every `pull_request` push regardless
of draft state, so the entire work-in-progress window of a task — draft PR open, through
however many `/t-work` fix passes and `/t-review` passes — pays for a full hosted CI run
on every push, verifying largely what `/t-work` and `/t-review` already verified locally.
Skip the jobs while the triggering PR is a draft, and add `ready_for_review` to the
trigger types so the one hosted CI run that matters — the one gating an actual merge —
starts when the PR is marked ready.

This changes when CI starts relative to `/t-ship`, which currently reads CI status
(precondition 3) *before* marking the PR ready (Procedure step 1) — the same step that
will now be what starts CI. `/t-ship`'s ordering must be corrected so the merge gate
never shows "green" evidence that actually means "nothing ran yet". `/t-work`,
`/t-review`, and `/t-drive`'s Solo mode step 6 language (which assumes CI starts at
PR-open) get checked for the same assumption, and `docs/adr/007-solo-drive-defers-on-pending-ci.md`
gets read and, if its stated rationale is materially changed, addressed explicitly.

## Done when
- `.github/workflows/ci.yml`'s jobs (or the workflow itself) do not run while the
  triggering PR is a draft.
- `ready_for_review` is added to `ci.yml`'s `pull_request:` `types:`, and marking a draft
  PR ready is observed to start a CI run.
- Pushing new commits to a still-draft PR is observed to cost zero CI minutes.
- ADR-007 is read; if its stated rationale is materially changed by this task, that is
  addressed explicitly (an amendment note, a new ADR, or an explicit statement that the
  revisit trigger has not yet fired) rather than left silently stale.
- `/t-ship`'s ordering is corrected for the new CI timing — the CI reading happens (or is
  repeated) after `forge:pr-ready`, and a still-pending state is surfaced honestly at the
  merge gate, never read as green.
- `/t-work`, `/t-review`, and `/t-drive`'s Solo mode step 6 language is checked for any
  assumption this task breaks, and updated if so.

## Explicitly not
- Does not remove or weaken any required check.
- Does not change `review-gate.yml` (task #97 in this initiative covers that file).

## Decisions made along the way
- `/t-ship`'s CI-ordering fix takes the "watch to conclusion, attended" shape rather
  than "mark ready, one look, defer like ADR-007's solo pre-check" — the deferral
  shape was rejected because the one look happens seconds after `forge:pr-ready`
  starts CI while CI takes minutes, so it would find "pending" essentially every time,
  institutionalizing a double-`/t-ship`-invocation ritual on every protected ship (the
  human, 2026-08-30). Recorded as `docs/adr/008-attended-ci-wait-at-the-ship-gate.md`,
  narrowing ADR-007 to the case it actually fits (an unattended pre-check with nothing
  left to check once CI only starts at `ready_for_review`) rather than silently
  contradicting it.
- `/t-drive`'s Solo mode step 6 (ADR-007's CI pre-check before invoking `/t-ship`) is
  removed rather than reworded: once CI cannot have settled before `/t-ship` marks the
  PR ready, the pre-check has nothing left to decide — the wait relocates entirely into
  `/t-ship`'s own Procedure, uniformly for a human-invoked ship and a driven one, with
  the run's single stop (ADR-006 D3) unchanged (the human, 2026-08-30).
- ADR-007's own file is left unedited (`docs/adr/`'s append-only rule); the amendment
  lives in the new ADR-008 rather than as an edit to ADR-007's text.
- `t-work`/SKILL.md and `t-review`/SKILL.md carry no CI-timing assumption to update —
  neither reads or reasons about CI status anywhere in its text, confirmed by grep
  during planning and re-confirmed here before touching any file.

## Deviations / notes
- none yet
