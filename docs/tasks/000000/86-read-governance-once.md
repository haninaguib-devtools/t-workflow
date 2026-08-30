# 86 — Read the governance documents once per driven run
Issue: #86 · Part of: #85

## Asked
Every stage the pipeline defines opens by reading `AGENTS.md` and `CONSTITUTION.md`:
`/t-drive` Phase 0 step 1, `/t-plan` step 1, `/t-work` Phase 1 step 1, `/t-review` step 2,
and `/t-ship`. Run by hand each of those is a fresh session where the read is cheap and
necessary. Chained by `/t-drive` they all land in one session, so the same documents are
read four to five times into a context that every later stage then pays for on each of
its own tool calls. Make the driven path read them once: `/t-drive` reads them in Phase 0,
and each chained stage's own read step is written so it may be skipped when the driving
session has already performed it in this run. The stages must keep their standalone
behaviour exactly — invoked directly, each still reads for itself, because there is no
driving session to have done it.

## Done when
- `/t-drive` Phase 0 states that its read of `AGENTS.md` and `CONSTITUTION.md` covers the
  whole run, in both modes.
- Each of `/t-plan`, `/t-work`, `/t-review`, and `/t-ship` names the condition under which
  its own read step is already satisfied, and states that a standalone invocation always
  performs it.
- `./.t-workflow/scripts/consistency-check.sh` passes.
- Human judgment: reading the amended skills cold, it is unambiguous which invocation is
  responsible for the read.

## Explicitly not
Does not touch what any stage reads *besides* those two documents — the issue body, the
diff, the record, and the ADRs each stage names stay exactly as they are. Does not change
`/t-review`'s isolation rule: a spawned reviewer is a separate context and always reads
for itself.

## Decisions made along the way
- none

## Deviations / notes
- none
