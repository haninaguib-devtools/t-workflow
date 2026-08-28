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
- Cold review (fresh subagent, 2026-08-28) found two high findings. One (a stale
  cross-reference in `docs/adapters/FORGE.md`'s `forge:pr-close` row, still pointing at
  `forge:pr-merge`'s old deletion behavior after this task rewrote it) was fixed
  directly, in scope. The other — `.claude/skills/t-fix/SKILL.md` describing the old
  `forge:pr-merge` behavior — was resolved without a code change: while the review was
  in flight, sibling task #25 merged to `main` and deleted `t-fix/SKILL.md` entirely,
  which is exactly the resolution the review itself named as an alternative to
  widening this task's scope (hani, 2026-08-28).

## Deviations / notes
- Sibling tasks #25 (remove `/t-fix`) and #26 (drop Jira/GitLab support) both merged to
  `main` after this task's branch was cut, each independently editing files this task
  also touches (`AGENTS.md`, `.claude/skills/t-cancel/SKILL.md`,
  `docs/adapters/FORGE.md`) — the scope-overlap risk flagged on the issue's Plan.
  Merged `origin/main` into the task branch and resolved the resulting conflicts in
  `.claude/skills/t-ship/SKILL.md` (kept this task's rewritten cleanup logic, adopted
  #26's dropped id-lowercasing clause and GitLab rows) and `docs/adapters/FORGE.md`
  (kept this task's `forge:pr-merge`/`forge:pr-list` changes, adopted #26's GitLab-row
  removal); `scripts/stale-branches-check.sh`'s modify/delete conflict resolved by
  keeping this task's deletion.
