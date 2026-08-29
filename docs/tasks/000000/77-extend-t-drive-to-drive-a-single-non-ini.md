# 77 — Extend /t-drive to drive a single non-initiative task
Issue: #77

## Asked
Extend `/t-drive`, which today refuses anything not labeled `initiative`, so a human
can hand it one ordinary (non-initiative) task and get the whole pipeline in one
invocation: plan if the declared scope needs it, implement, review if the actual diff
needs it, and stop exactly once — at `/t-ship`'s existing human merge gate. The trust
posture is unchanged: no integration branch, no autonomous merge; every gate fires
exactly where the manual pipeline fires it. The only rule touched is ADR-001 D1's
"nothing auto-chains", whose one existing exception (ADR-004) is widened to cover a
single-task mode. Deliverable: a short ADR extending — not superseding — ADR-004's
exception, plus the skill and doc edits implementing it. The issue pre-settles six
decisions the ADR encodes: mode by `initiative` label on the same command; the solo
sequence (`/t-plan` when declared scope is protected → `/t-work` Normal mode →
`/t-review` when the actual diff is protected → `/t-ship`, pausing at its gate);
chaining into `/t-ship`'s gate as the single stop; one bounded retry in ADR-004
Decision 2's shape; review skipped for a non-protected diff, with the ADR saying why;
tracker-write authority = the invocation plus the gate.

## Done when
- A new ADR exists in `docs/adr/` (next free number), Status: Accepted, extending —
  not superseding — ADR-004's exception to cover the single-task mode, settling each
  of the six decisions with rationale and revisit triggers.
- `.claude/skills/t-drive/SKILL.md` forks on the `initiative` label instead of
  refusing a plain task, and documents the solo sequence: the two protected-path
  tests, the chain into `/t-ship`'s gate, the bounded retry, and the
  stop-without-shipping outcome.
- The skill's frontmatter description, the `AGENTS.md` `/t-drive` table row, and
  `docs/workflow.md` say the stage drives an initiative or a single task.
- `./.t-workflow/scripts/consistency-check.sh` exits 0.
- Human judgment: the merged ADR's decisions match the six points above, with no
  change to the initiative mode's phases.

## Explicitly not
- No change to the initiative mode's phases or to any ADR-004 decision for
  initiatives — in particular its ending (stop and name `/t-ship`) stays as-is;
  aligning it to chain into the gate is a boundary noted in the ADR, not work done
  here.
- No new command, no flag, no retry machinery beyond the one bounded pass ADR-004
  Decision 2 already defines.
- No `CONSTITUTION.md` change — §1.4 is untouched; a solo drive's merge is an
  ordinary single-task squash with one `Task:` line.

## Decisions made along the way
- ADR-006 uses `### D<n>.` headings for its decisions (agent, 2026-08-29) — the
  consistency check resolves `ADR-006 D<n>` references only against literal
  `### D<n>.` headings, and the plan required picking one convention; `D<n>` headings
  keep short references valid everywhere, while ADR-004's decisions stay cited as
  "Decision <n>" spelled out, matching its `### 1.`-style headings.
- ADR filename `docs/adr/006-single-task-driving.md` (agent, 2026-08-29) — the slug
  the plan suggested.
- Phase 0's closed-issue refusal made explicit (agent, 2026-08-29) — the issue's
  Goal says Phase 0's eligibility checks (blocker gate, closed issue) apply to both
  modes, but the old Phase 0 never stated the closed-issue refusal in so many words;
  the fork rewrite states it once, shared by both modes, and the solo sequence runs
  the blocker gate as its own step 1 since it skips the initiative mode's per-child
  eligibility phase.
- One defensive sentence in the Phase 0 fork (agent, 2026-08-29): an issue with
  children but no `initiative` label is called out as a tracker defect to report
  rather than silently solo-driven — a consequence of D1's mode-by-label rule the
  issue settles, not a new policy; flagged here for the reviewer to strike if it
  reads as more than that.
- The solo sequence lives as a new section after Phase 3 rather than renumbering
  phases (agent, 2026-08-29) — `.claude/skills/t-ship/SKILL.md` cites `/t-drive`
  Phase 2 step 6 and Phase 3 step 1 by number; renumbering would break those
  references for no gain.

## Deviations / notes
- none
