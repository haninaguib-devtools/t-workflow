# 27 — Remove /t-wtree
Issue: #27 · Part of: #22

## Asked
Remove the `/t-wtree` skill, per ADR-002. Worktrees remain possible — plain
`git worktree add`, or a harness-created checkout — but the pipeline no longer ships a
skill for creating them. Delete `.claude/skills/t-wtree/` and its `AGENTS.md` pipeline
row together; delete consistency check 8 (the branch-resolution twin check — `/t-work`
becomes the algorithm's only home); reword the worktree references in `/t-work` (phase 1
step 4), `docs/workflow.md`, and `README.md`. `/t-work` keeps its checkout-safety
refusals: never switch a checkout registered to another task, two sessions never share a
checkout.

## Done when
- `.claude/skills/t-wtree` does not exist; `AGENTS.md`'s table has no `/t-wtree` row.
- `grep -rn "t-wtree" AGENTS.md docs/workflow.md README.md .claude/skills scripts` shows
  no living-guidance hits.
- `/t-work` still carries the never-switch-another-task's-checkout rules (human-judged in
  review).
- `./scripts/consistency-check.sh` exits 0; CI green on the PR.

## Explicitly not
- No change to how `/t-work` resolves or creates the task branch.
- Worktree cleanup behavior belongs to the ship-from-anywhere task — #28.

## Decisions made along the way
- Fast-forwarded this branch onto `origin/main` before starting work: #26 (Jira/GitLab
  removal) merged after `/t-plan 27` ran, and its commit already touched
  `.claude/skills/t-wtree/SKILL.md` (dropped the non-numeric-id clause) and
  `scripts/consistency-check.sh` (removed check 8b) — both inside this task's own scope.
  No conflict resolution was needed; the branch had no commits of its own yet, so this
  was a plain fast-forward (hani, 2026-08-28).

## Deviations / notes
- none
