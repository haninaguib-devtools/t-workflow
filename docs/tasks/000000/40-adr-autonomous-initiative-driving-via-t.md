# 40 — ADR: autonomous initiative-driving via /t-drive
Issue: #40 · Part of: #39

## Asked
Ratify, as an ADR, the design for `/t-drive`: a stage that walks an entire initiative's
child tasks to completion — implementing and independently reviewing each one — and
stops once, at a single PR against `main`, for the human's one confirmation. The ADR
settles three things: the integration-branch model (each child branches off the
initiative's integration branch, not `main`; a child's independent cold review is what
authorizes its merge into that branch; only the integration branch's final state reaches
`main`, and only by an ordinary human-confirmed PR); the bounded self-correction policy
for a child that fails review or checks (one retry, then it is excluded from the driven
run — never auto-merged, never auto-cancelled); and the `CONSTITUTION.md` §1.4
commit-message extension to carry one `Task: #<id>` line per included child instead of
assuming one task per commit. This reopens ADR-001 D1's "nothing auto-chains" principle
for this one, explicitly-invoked case — everything else about D1 stands unchanged.

## Done when
- New ADR file in `docs/adr/`, following the existing shape (Context, Decision,
  Rationale, Alternatives considered, Consequences/revisit triggers), covering the three
  decisions above.
- `CONSTITUTION.md` §1.4 updated for the multi-task commit format, and the operative
  one-line pointer added per §2.3.
- `AGENTS.md`'s stage table gets a `/t-drive` row stating its contract (implementation
  is the next task; this task fixes what it must satisfy).
- Merged at the heightened approval bar (protected surface: `docs/adr/`,
  `CONSTITUTION.md`, `AGENTS.md`).

## Explicitly not
- No real `/t-drive` behavior and no `docs/workflow.md` wiring — building the skill is
  #41 (blocked by this task); this task's `.claude/skills/t-drive/SKILL.md` is a stub
  only (see Deviations).
- No re-decision of ADR-001 D1 beyond the one named, explicitly-invoked exception for
  `/t-drive`; D1 stands unchanged for every other stage.

## Decisions made along the way
- Widened Allowed paths mid-task to include `.claude/skills/t-drive/SKILL.md` as a
  minimal stub (human, 2026-08-28) — see Deviations for why.

## Deviations / notes
- **Scope amendment, human-approved (2026-08-28).** The original plan's Allowed paths
  excluded `.claude/skills/t-drive/`, expecting the `AGENTS.md` stage-table row to exist
  with no matching skill file until #41. Running `./scripts/consistency-check.sh` showed
  that fails check 3 (AGENTS.md ↔ `.claude/skills/` symmetry) the moment the row exists
  — and since `.github/workflows/ci.yml` runs the same check on every push to `main`,
  merging #40 as originally planned would leave `main`'s `consistency` CI job red until
  #41 lands (which is itself blocked by #40, so that window is unavoidable under the
  original scope). Presented three options to the human (widen scope for a stub, accept
  `main` going red temporarily, or stop for a formal `/t-plan` re-run); they chose to
  widen scope for a stub now. Issue #40's Plan section was amended accordingly (Allowed
  paths, Risks, Validation) and `.claude/skills/t-drive/SKILL.md` was added: frontmatter
  plus a short body stating `/t-drive` is not implemented yet and pointing at ADR-004
  and #41 — no part of the real driven-initiative behavior. `./scripts/consistency-check.sh`
  now passes.
