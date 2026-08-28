# 23 — ADR-002: trim the Phase 0 workflow
Issue: #23 · Part of: #22

## Asked
The delivery workflow carries machinery its single operator does not use. Write and
ratify ADR-002, superseding parts of ADR-001, to: drop the worktree stage (`/t-wtree`)
from D1's per-task stages; remove the no-issue fix path (D2, `/t-fix`) so every change
starts from an issue; drop D4's non-numeric tracker-key detail (ids are GitHub-numeric
only); and record the new cleanup model — `/t-ship` merges and stops, runnable from any
checkout, remote branch deletion rides the repo's `delete_branch_on_merge` setting, and
local worktree/branch cleanup becomes an explicit lazy step (a new `/t-clean`) instead
of ship/cancel teardown.

## Done when
- `docs/adr/002-*.md` exists on `main`, Status: Accepted, with context, rationale,
  alternatives, and revisit triggers (CONSTITUTION.md §2.1).
- ADR-001 is unedited (append-only); the superseded decisions are named explicitly.
- `./scripts/consistency-check.sh` exits 0.

## Explicitly not
- No skill, CI, adapter, or script edits here — the sibling implementation tasks
  (#25 Remove /t-fix, #26 drop untested backends, #27 Remove /t-wtree, #28 ship from
  anywhere/add /t-clean) do that, each blocked on this ADR.
- The native-relations decision (`Part of:`/`Blocked-by:` markers → GitHub-native
  sub-issues and dependencies) is ADR-003's subject (#24), not this file's.

## Decisions made along the way
- Filename: `docs/adr/002-trim-the-phase-0-workflow.md`, matching the `NNN-slug.md`
  pattern `scripts/consistency-check.sh` check 2 requires for `ADR-002` references to
  resolve (Claude, 2026-08-28).
- D3 (cancellation rules) is named as partially superseded even though the issue's Goal
  paragraph only calls out D1/D2/D4 by number: the new cleanup model changes D3's
  teardown clause (worktree removal + branch deletion by `/t-ship`/`/t-cancel`) and
  makes D3.4 ("a `/t-fix` change has nothing to cancel") moot once D2 is gone, while
  D3.1/D3.2/D3.3/D3.5 (the dependency, anti-cascade, escape-hatch, and terminal-not-
  deferral safety rules) are untouched. Called out explicitly per the plan's Risks
  section rather than silently folded into the D1/D2/D4 list (Claude, 2026-08-28).

## Deviations / notes
- none
