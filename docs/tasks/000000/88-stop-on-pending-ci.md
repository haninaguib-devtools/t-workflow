# 88 — Stop a driven run waiting silently on CI at the merge gate
Issue: #88 · Part of: #85

## Asked
`/t-ship` precondition 3 requires CI green, and precondition 4 retries an asynchronous
mergeability answer several times. Invoked by hand that wait is fine — the human chose the
moment. Chained by `/t-drive` in solo mode it lands inside the run, so the session sits
idle against remote CI with nothing to report and the terminal held. Make the wait
something a human can see and act on: either `/t-ship` says out loud that it is waiting,
for how long it will keep waiting, and returns control when it gives up, or solo mode
stops before `/t-ship` — as the initiative mode already does — when CI has not settled,
naming `/t-ship <id>` as the next command. Which of the two is right is the design
question this task settles; both keep the merge behind the human's confirmation.

## Done when
- A driven solo run whose CI is still pending ends in bounded time, having said plainly
  what it is waiting for and what to run next.
- `/t-ship`'s merge gate itself is unchanged — same wording, same refusals, same
  confirmation.
- ADR-006's "the run stops once" property is either preserved or amended by an ADR that
  says so explicitly.
- `./.t-workflow/scripts/consistency-check.sh` passes.
- Human judgment: the chosen option reads as deliberate rather than as a timeout bolted on.

## Explicitly not
Does not merge anything without the human's confirmation, and does not make a red or
missing CI result acceptable to ship on.

## Decisions made along the way
- Plan chose the "solo mode stops before `/t-ship`, naming it as the next command"
  option over "`/t-ship` itself waits and reports when it gives up" — narrowing Allowed
  paths to exclude `t-ship/SKILL.md` entirely (the issue's own Scope line named it as a
  candidate). Reasons recorded in the issue's `## Plan` Risks/constraints (`/t-plan`,
  2026-08-30): the done-when requires `/t-ship`'s gate to stay byte-unchanged, the
  problem is scoped to the unattended/driven case specifically, and a single
  once-only CI-status check is bounded by construction with no timeout to calibrate.
- A new ADR (`docs/adr/007-*.md`) amends ADR-006 D3 rather than editing it — ADRs are
  append-only per file (`CONSTITUTION.md` §2.1).

## Deviations / notes
- none
