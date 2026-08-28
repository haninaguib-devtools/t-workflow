---
name: t-cancel
description: Cancel a task that will not be done — record why, force an explicit decision on every dependent, child, and parent issue, then close its PR and delete its branch. The pipeline's terminal exit. Use to cancel, abandon, drop, or kill a task.
---

# Cancel a task

The only exit that is not a merge. The argument names the issue (`/t-cancel 142`); with
nothing, list open non-initiative issues and ask. Resolve every `tracker:*` / `forge:*`
operation named below via `docs/adapters/TRACKER.md` and `docs/adapters/FORGE.md`
(GitHub by default).

The safety rules come from
[ADR-001](../../../docs/adr/001-phase0-delivery-workflow.md), decision D3. Where this skill and
that ADR differ, the ADR wins and the difference is a defect — flag it, do not
improvise.

Cancelling destroys work. Nothing belonging to a *task* is destroyed before the gate in
Phase 3.

## Phase 1 — is this really a cancellation

1. Read `AGENTS.md`, `CONSTITUTION.md`, and the issue (`tracker:view <id>`).
2. **Refuse, naming the reason and the alternative:**
   - **A merged task.** Undoing shipped work is a revert — ordinary forward work with its
     own diff. Hand off to `/t-open`.
   - **"Not now."** Parking, deferring, waiting on something else — cancellation is
     terminal (ADR-001 D3.5). Deferral is the issue staying open with a blocked-by
     dependency set on it (`tracker:add-blocker`). Ask which is meant rather than
     guessing.
   - **A supersession with no successor named.** A task replaced by a different plan
     closes pointing at the issue that replaced it; find or open that issue first.
3. **Find what exists**, so the gate can name it: `git fetch --prune origin`, then the
   branch locally (`git branch --list 'wip/<id>-*'`; `git worktree list`) and on the
   remote, plus any PR (`forge:pr-find-by-task <id>`, all states) and whether a record
   file exists on the branch. A task worked in another session leaves nothing local.
4. **The escape hatch** (ADR-001 D3.1): if the reasoning behind this cancellation is
   durable and constrains future work — "we will not do X, because it conflicts with the
   event model" — or the same idea has now been opened and dropped more than once, it
   belongs in an ADR or `docs/architecture/`, not in a close comment. Say so and open that
   task (`/t-open`); do not smuggle a decision into a cancellation.

## Phase 2 — neighbours, decided before anything is torn down

ADR-001 D3.2 and D3.3. **Gather and decide here; act on nothing yet** — every comment,
label, relation change, and close happens in Phase 4, so an aborted gate leaves every issue
exactly as it was. Never decide any of them silently, and never cascade.

1. **Dependents.** `tracker:list-blocking <id>` — the cancelled issue's own native
   `blocking` field names every open issue it blocks directly (ADR-003); no scan of
   every other open issue's body is needed any more, unlike the retired `Blocked-by:`
   marker convention.

   A result that reaches the command's page cap is an incomplete read: report it and
   stop rather than reporting "no dependents". A cancelled blocker was **abandoned, not
   satisfied** — each dependent needs an explicit disposition: **proceed anyway**
   (drop the stale edge with `tracker:remove-blocker`, nothing to replace it), **re-point
   at a different blocker** (`tracker:remove-blocker` then `tracker:add-blocker` to the
   new one), or **cancel too** (a separate run, decided on its own merits — leave its
   edge as is; that run's own teardown is where it gets resolved).
2. **Parent.** If `tracker:view <id>` (Phase 1 step 1) returned a `parent`, ask the
   human explicitly whether that initiative still adds up without this step. If it does
   not, that is a second cancellation, decided separately — never implied by this one.
3. **Children.** If the issue carries the `initiative` label, `tracker:list-children
   <id>` and decide **each one individually**: cancel it, or promote it to standalone
   with `tracker:remove-parent`. Children are frequently valuable alone.
4. **Spun-off exclusions.** Issues carrying `Split from: #<id>` — opened from this task's
   Non-goals — hold rationale pointing at a task that will not exist: re-point them at the
   parent or cancel them, never orphan them. `Split from:` stays body text (ADR-003 keeps
   no native equivalent for it), so find them the same way as before: sweep bodies
   client-side with `tracker:list-open` rather than the tracker's own body-search, whose
   index can lag and miss a recently-edited issue. An issue opened before that marker
   existed will not be found, so say so rather than reporting none.

## Phase 3 — the gate

Before it, in plain prose per AGENTS.md §Communication: what will be destroyed, what will
survive, and every neighbour decision from Phase 2. Then the gate, per
`docs/architecture/confirmation-gates.md`: a plain question (or the environment's native
question mechanism), last thing in the message —

- evidence: destroys `<PR #, branch — or 'nothing built yet'>` · reason
  `<one line>` · neighbours `<n dependents, parent, children — dispositions>`
- question: "Cancel task #<id> and tear down its work?"
- options: `confirm` (cancel the task) / `abort` (keep it)

`confirm` proceeds; anything else stops, changing nothing. Never proceed on silence.

## Phase 4 — teardown, in this order

1. **Ensure the `cancelled` label exists** before anything is destroyed — discovering it
   is missing afterwards leaves work destroyed with the issue still open. Idempotent:
   `tracker:ensure-labels cancelled` (color `6E7781`, description "Task cancelled via
   /t-cancel — see the close comment for the reason", matching the bootstrap script).
2. **Close any PR — never repurpose it.** That diff *is* the discarded work, and closing
   it records the abandonment honestly. **Before composing the close command, re-read
   `docs/adapters/FORGE.md`'s `forge:pr-close` row and check the exact command string you
   are about to run against it** — a command missing the active backend's
   branch-deletion flag (`--delete-branch` on GitHub) closes silently and leaves the
   branch stranded on `origin` (issue #13): `forge:pr-close <pr>` with a comment saying
   why, in prose.
3. **Delete the branch, if anything is left to delete.** Step 2's `forge:pr-close`
   already removed the branch — local *and* remote — whenever a PR existed, so this step
   is normally a no-op after a PR, and does the whole job when there was never one. This
   skill does not touch worktrees (`/t-clean`'s job, run lazily whenever one is actually
   in the way), so the branch may still be checked out somewhere.

   If the *invoking* checkout itself is on the target branch, move it off first — this
   is the only checkout this skill may switch, and only because it is standing on the
   branch about to be deleted:

   ```bash
   [ "$(git rev-parse --abbrev-ref HEAD)" = "wip/<id>-<slug>" ] &&
     git checkout main && git merge --ff-only origin/main
   git rev-parse --verify --quiet wip/<id>-<slug> && git branch -D wip/<id>-<slug>
   ```

   **A branch still checked out in another worktree refuses to delete — that is the
   normal case here, not an error.** Report it as left in place, pointing at the
   worktree (`git worktree list`), and move on to the remote branch below; never switch
   or remove a worktree that is not the invoking checkout, and never remove the
   invoking checkout's own worktree to route around the refusal.

   **Then the remote branch, and check before deleting.** `git rev-parse --verify
   refs/remotes/origin/<branch>` failing means there is nothing left to do, which is the
   normal path, not an error. Only when that ref still exists, delete it with a lease
   against the exact object ID you just read, so concurrent work fails safely rather than
   being overwritten:

   ```bash
   oid=$(git rev-parse --verify refs/remotes/origin/<branch>) &&
     git push --force-with-lease=refs/heads/<branch>:$oid origin :refs/heads/<branch>
   ```

   A rejected deletion means another session moved the branch: stop without closing the
   issue and report it. That exact-ID lease is the only permitted force option here.
4. **Close the issue, carrying the reason.** A record that already merged to `main` stays
   there; one that only existed on the destroyed branch is gone by design (ADR-001), so
   this comment is the durable account: `tracker:label <id> cancelled`, then
   `tracker:close <id>` as not-planned, the comment carrying why (in prose) and the
   neighbour dispositions — what was decided for each dependent, child, or parent.

   The `cancelled` label is what makes cancellations queryable — `/t-status` counts them
   from it. Keep it.
5. **Execute every Phase 2 disposition** — nothing below happened before the gate; all
   of it happens now:
   - **Parent**, if any: `tracker:comment` on it saying this child is cancelled.
   - **Each dependent**: `tracker:remove-blocker <dependent-id> <this-id>` to drop the
     now-stale edge (proceed and re-point both start here; re-point continues with
     `tracker:add-blocker <dependent-id> <new-blocker-id>`), plus `tracker:comment` on
     it explaining why.
   - **Each child promoted to standalone**: `tracker:remove-parent <child-id>`, plus
     `tracker:comment` on it.
   - **Each spun-off issue**: `tracker:comment` pointing at its new home.

   Report what happened to every neighbour in plain prose.

## Rules

- **Never destroy before the gate**, and never on silence.
- **Never merge, never push `main`, never force-push** beyond the exact-ID lease above.
- **Never cascade.** Every dependent, child, and parent gets an explicit human decision,
  however tedious.
- **Never cancel to avoid finishing.** A failing check or a hard review finding is a
  re-plan, not a cancellation.
- Cancelling is not deleting: issues, PRs, and their threads stay readable.
