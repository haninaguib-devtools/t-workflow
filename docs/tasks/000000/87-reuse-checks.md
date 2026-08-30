# 87 — Let a driven review reuse the checks just run on the same commit
Issue: #87 · Part of: #85

## Asked
`/t-work` Phase 3 step 1 runs the check set, then `/t-review` step 6 runs it again — the
same commands, against the same head commit, minutes apart. Under `/t-drive` that pairing
happens on every task, and a third time whenever the bounded retry fires, so the slowest
part of a task is paid two or three times for one unchanged tree. Let a review reuse a
check result when it can prove nothing changed underneath it: the checks were run on
exactly the head commit the review is reading, and the tree is clean. The review still
re-runs anything its own findings call into question, and still runs the checks itself
whenever that proof is unavailable — a review that cannot verify the provenance of a
result runs the check.

## Done when
- `/t-review` step 6 states the exact condition under which a check may be reported as
  already passing, and it requires the recorded head commit to match the one under review.
- A reused result is visible in the posted review body, distinguishable from a check the
  reviewer ran itself, so nobody reads "passing" without knowing where it came from.
- `AGENTS.md` §Checks still names one check set, unchanged.
- `./.t-workflow/scripts/consistency-check.sh` passes.
- Human judgment: the reuse condition cannot be satisfied by a stale or unproven result.

## Explicitly not
Never weakens a check or a finding's severity — `CONSTITUTION.md` §1.5 stands. Does not
apply to the CI run on the forge, which stays independent of anything a session claims.

## Decisions made along the way
- Plan widened Allowed paths to include `.claude/skills/t-work/SKILL.md` beyond the
  issue's own Scope line (`t-review`, `t-drive`) — the reuse condition needs provenance
  (which commit a check ran against), and the only place that can be written honestly is
  `/t-work` Phase 3, where the checks actually run. Recorded in the issue's `## Plan`
  Risks/constraints (`/t-plan`, 2026-08-30).
- `/t-drive 85`: #87 and #88 were both `blocked-by` #86 on the tracker, but #86 had
  already merged into the integration branch (not `main`, so its issue stayed open) —
  `/t-work`'s own blocker gate (`check-blocker-gate.sh`) does not treat an integration-
  branch merge as satisfying a blocker, only a completed close. Confirmed empirically:
  `check-blocker-gate.sh` failed for #87 with `#86 OPEN/null`. This affects any initiative
  with sequential `blocked-by` edges between siblings, not just this one. Human decided
  (2026-08-30, asked via `/t-drive`'s own session): remove the now-satisfied edges
  (`tracker:remove-blocker 87 86`, `tracker:remove-blocker 88 86`) and continue driving
  both normally, rather than excluding them per ADR-004's literal "unresolvable
  precondition" clause or stopping the whole run. Recommended as a follow-up in the
  closing report of #85's drive: `/t-drive` should do this itself for a driven run's own
  merges, since `check-blocker-gate.sh`, run unmodified inside `/t-work` per child, will
  otherwise trip on this exact case every time.

## Deviations / notes
- none
