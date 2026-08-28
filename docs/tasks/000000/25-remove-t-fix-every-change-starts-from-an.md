# 25 — Remove /t-fix: every change starts from an issue
Issue: #25 · Part of: #22

## Asked
Remove the no-issue fix path everywhere it lives, per ADR-002: delete
`.claude/skills/t-fix/`; remove the `fix/*` branch handling from CI's `record` job;
remove the `/t-fix` special cases from `/t-cancel` (Phase 1 step 2) and `/t-status`
(step 5, the fix-merge count) and the retro creep-signal sampling from
`docs/workflow.md` §11.6; update `scripts/consistency-check.sh` check 4 so it no longer
requires the t-fix skill file; and sweep the `/t-fix` references from `AGENTS.md`,
`CONSTITUTION.md` §1, `README.md`, and the remaining skills. Historical documents
(ADR-001, merged task records) stay unedited.

## Done when
- `.claude/skills/t-fix` does not exist; `AGENTS.md`'s pipeline table has no `/t-fix`
  row (consistency check 3 symmetry).
- `grep -rn "t-fix\|fix/" AGENTS.md CONSTITUTION.md README.md docs/workflow.md
  .claude/skills .github/workflows scripts` shows no living-guidance hits (historical
  ADRs and task records exempt).
- `./scripts/consistency-check.sh` exits 0; CI green on the PR.

## Explicitly not
- No changes to squash-only merging, confirmation gates, or any other pipeline stage.
- The stale-branch workflow's fate belongs to the ship-from-anywhere task, not here
  (`.github/workflows/stale-branch.yml` untouched — split to #28).

## Decisions made along the way
- none

## Deviations / notes
- The Done-when grep's three surviving hits are judgment calls, not misses — all three
  are the stale-branch mechanism's own description of what it matches, and its fate is
  #28's per Non-goals: `.github/workflows/stale-branch.yml` (untouched, out of Allowed
  paths), `docs/workflow.md` §9 (describes that workflow's `fix/*` pattern, not `/t-fix`
  guidance), and `scripts/stale-branches-check.sh:2` (its own top-of-file description of
  the `wip/*`/`fix/*` branch prefixes it scans — the one `/t-fix`-*naming* sentence in
  that file, at the old line 12, was in scope and removed). Flagged at plan time
  (issue #25's `## Plan` → Risks) for the first two; the third surfaced during
  implementation and is the same category (Claude, 2026-08-28).
- **Rebased onto `origin/main` after #26 (Drop untested Jira/GitLab support) merged**,
  exactly the sibling-overlap risk the plan flagged: PR #35 went `CONFLICTING` once #26
  landed as commit `2418a3d`, since both tasks touched `.github/workflows/ci.yml` and
  `AGENTS.md`. Resolved by hand: kept #26's already-landed simplifications (numeric-only
  `id` regex in the `record` job's branch match, and the shorter "Task ID = the
  tracker's issue number" line in `AGENTS.md`, both from ADR-002's dropped D4
  non-numeric-key clause — #26's job, not this task's) alongside this task's own removal
  of the `fix/*` exemption block and every `/t-fix` mention. Re-verified after rebase:
  `./scripts/consistency-check.sh` exits 0, the protected-paths check on the diff
  against the new `main` is unchanged (same 11 files), and the living-guidance grep
  still shows only the same three documented residual hits. New commit `be20e64`
  (force-pushed, replacing `b539c6e`) — the prior cold review's verdict was for
  `b539c6e` and needs re-confirming against the rebased head before `/t-ship`
  (Claude, 2026-08-28).
