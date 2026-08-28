---
name: t-clean
description: Remove a shipped or cancelled task's stale local worktree and branch — the explicit, lazy cleanup /t-ship and /t-cancel no longer perform automatically (ADR-002). Lists candidates, refuses on uncommitted changes, removes only on the human's confirmation, never --force. Use to clean up, remove worktrees, or delete stale local branches.
---

# Clean up stale worktrees and branches

Nothing destroys a local worktree or branch as a side effect of shipping or cancelling
(ADR-002); this skill is the deferred, explicit step for when one is actually in the
way. Resolve every `forge:*` operation named below via `docs/adapters/FORGE.md` (GitHub
by default). This skill touches no tracker issue.

## Where this runs

This is the one skill of the three that still removes a worktree, so it inherits the
restriction ADR-002 lifted from `/t-ship` and `/t-cancel`: it cannot delete the ground
it is standing on. If the current checkout is a linked worktree (`git worktree list`),
stop and report the primary checkout's absolute path — a single pass here may clean
several tasks at once, so this skill cannot assume in advance which worktree, if any,
would be safe to remove out from under this session.

## Procedure

1. **Candidates.** `git fetch --prune`, then:
   - local branches matching `wip/*` or `fix/*` (`git branch --list 'wip/*' 'fix/*'`);
   - registered worktrees (`git worktree list --porcelain`), excluding the primary
     checkout itself.

   Resolve every candidate branch's PR state in one round trip with the repo-wide,
   all-state variant of `forge:pr-list`, matching rows by `headRefName`.

2. **Classify each branch:**
   - **merged or closed PR** → a removal candidate.
   - **open PR** → work in flight; report it, never a candidate.
   - **no PR found** → never a candidate. This is not "safe to discard" — it can mean
     work that never reached `/t-work`'s draft-PR step, or a branch worked in a session
     that never pushed. Report it as unresolved rather than offering it for removal.

3. **Check cleanliness** of each removal candidate that has a worktree:

   ```bash
   git -C <worktree-path> status --porcelain   # empty output = clean
   ```

   A dirty worktree drops only that one candidate from the removable set — report it
   and continue with the rest. A branch with no worktree has nothing to check.

4. **Show the full list** before touching anything: branch, PR # and state, worktree
   path if any, and clean/dirty/in-flight/no-PR. Nothing is removed yet.

5. **Gate**, per `docs/architecture/confirmation-gates.md`: a plain question (or the
   environment's native question mechanism), last thing in the message —

   - evidence: candidates `<n removable>` · excluded `<m dirty, k in flight, j no PR>`
   - question: "Remove these <n> stale worktrees/branches?"
   - options: `confirm` (remove the listed candidates) / `abort` (remove nothing)

   `confirm` proceeds; anything else stops, changing nothing. Never proceed on silence.

6. **On confirmation, for each removable candidate:**

   ```bash
   git worktree remove <worktree-path>   # only if it has one; never --force
   git branch -D <branch>
   ```

   If the branch is currently checked out in the *invoking* (primary) checkout itself —
   not a linked worktree, since step "Where this runs" already excluded those — switch
   it to a fast-forwarded `main` first (`git checkout main && git merge --ff-only
   origin/main`), the same way `/t-ship` and `/t-cancel` do when they find themselves
   standing on the branch they need to touch.

7. **Report** what was removed, and what was left in place and why (dirty, still open,
   no PR, or refused).

## Rules

- **Never act before the gate**, and never on silence.
- **Never remove a worktree with uncommitted changes, and never `--force`.** Destroying
  unsaved work is the human's call, never this skill's.
- **Never offer a branch with an open PR, or no PR at all, for removal.** "Merged or
  closed" is the whole of the candidacy test — nothing here guesses at intent.
- Removal is local only: this skill never touches the tracker, never pushes, and never
  deletes a remote branch — the forge already did that (`delete_branch_on_merge` on
  merge, `forge:pr-close`'s own deletion on cancel).
