# 28 — Ship from anywhere: strip teardown from t-ship/t-cancel, add /t-clean
Issue: #28 · Part of: #22

## Asked
Separate merging from cleanup, per ADR-002. `/t-ship` stops removing worktrees and
local branches and drops its "Where this runs" restriction, so it runs from any
checkout — including inside the task's own worktree; after a merge it at most
fast-forwards a `main` it happens to be sitting on. `/t-cancel` likewise stops removing
worktrees (closing the PR and deleting the remote branch remain its job — destroying
the work is what cancellation is). Drop `--delete-branch` from `forge:pr-merge` in
`docs/adapters/FORGE.md` — the repo's delete_branch_on_merge setting already deletes
the remote branch — and with it the "re-read the row before composing the command"
ritual. Add a `/t-clean` skill: list worktrees and local branches whose PR is merged or
closed, show them, remove on the human's confirmation, refuse on uncommitted changes,
never --force. Delete `.github/workflows/stale-branch.yml` and
`scripts/stale-branches-check.sh` — the failure they backstop (a hand-composed merge
command missing the deletion flag) can no longer happen. Update workflow §9's
mechanical-enforcement list to match.

## Done when
- `/t-ship` and `/t-cancel` contain no "Where this runs" section and no worktree
  removal; `/t-ship` run from inside a task worktree completes (human-verified at review/ship).
- `.claude/skills/t-clean/SKILL.md` exists with an `AGENTS.md` table row (check 3).
- `.github/workflows/stale-branch.yml` and `scripts/stale-branches-check.sh` are gone.
- `docs/adapters/FORGE.md`'s `forge:pr-merge` row carries no branch-deletion flag.
- `./scripts/consistency-check.sh` exits 0; CI green on the PR.

## Explicitly not
- The human merge-confirmation gate is untouched.
- `forge:pr-close` keeps deleting the branch — teardown is `/t-cancel`'s explicit job.
- No auto-cleanup: `/t-clean` acts only on the human's confirmation.

## Decisions made along the way
- none

## Deviations / notes
- none
