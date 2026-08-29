# 59 — Remove the /t-clean skill
Issue: #59

## Asked
`/t-clean` — the skill ADR-002 introduced for lazy, explicit cleanup of a task's stale
local worktree/branch after `/t-ship` or `/t-cancel` — has turned out to be unused
standing cost: another command to know about, with no operator ever reaching for it.
Remove it, and bring every place that names or describes it (the pipeline table, other
site documentation, and the `/t-cancel` skill's own description) back in line with a
workflow that no longer has it.

Because `/t-clean` exists by a ratified decision (ADR-002), removing it is itself a
decision, not a plain edit: `CONSTITUTION.md` §2.1 requires a ratified decision to change
only via a new, append-only ADR that names what it supersedes. This task writes that ADR
alongside the mechanical removal.

## Done when
- A new ADR exists in `docs/adr/` superseding ADR-002's `/t-clean` decision (its "Replace
  ship/cancel teardown with deferred, explicit cleanup" section): stating that stale local
  worktrees/branches are left alone permanently rather than cleaned up lazily, with
  rationale, alternatives considered, and revisit triggers.
- `.claude/skills/t-clean/` is deleted.
- `/t-clean` no longer appears in `AGENTS.md`'s pipeline table.
- `/t-clean` no longer appears anywhere in `docs/workflow.md` or other site documentation
  (`grep -rn "t-clean" --include="*.md"` outside `docs/adr/` and `docs/tasks/` returns
  nothing).
- The `/t-cancel` skill's description (its `SKILL.md` frontmatter/card and any body text)
  no longer references `/t-clean` or describes teardown in terms that assumed `/t-clean`
  existed downstream.
- `./scripts/consistency-check.sh` passes.

## Explicitly not
- Re-litigating ADR-002's other decisions (dropping `/t-wtree`, `/t-fix`, the D4
  non-numeric tracker-key clause) — untouched.
- Changing `/t-ship`'s or `/t-cancel`'s merge/close behavior beyond the description fix —
  they already don't perform teardown; this task only removes the deferred-cleanup skill
  and its documentation trail.

## Decisions made along the way
- `docs/adapters/FORGE.md`'s `forge:pr-list` "repo-wide, all-state" variant existed only
  to serve `/t-clean`'s cross-referencing step; removed alongside it rather than left as
  documented, orphaned capability (Hani, 2026-08-28, via the plan on issue #59).
- `docs/tasks/TEMPLATE.md` and `docs/tasks/README.md` were checked for `/t-clean`
  references and have none — no edit needed there.

## Deviations / notes
- Phase 1's blocker check (`tracker:list-blockers 59` / `gh issue view 59 --json
  blockedBy`) cannot run: the installed `gh` is 2.45.0, older than the 2.94.0
  `docs/adapters/TRACKER.md` requires for native sub-issue/dependency JSON fields — the
  command fails with "Unknown JSON field". Proceeded without a positive blocker check:
  issue #59 is the only open issue in the repository (confirmed via `tracker:list-open`
  during `/t-plan`), so nothing else exists that could name it as a blocker. Flagging
  this gh-version gap rather than silently working around it.
- Two files edited that the plan's Allowed paths did not name, both required by the
  issue's own Done-when grep criterion and inside the already-protected `.claude/` and
  site-documentation scope, not a new protected surface: `.claude/skills/t-ship/SKILL.md`
  (its own `/t-clean` mention, missed when the plan's Allowed paths were drafted) and
  `site/index.html`'s `/t-cancel` skill card, whose "clean up the PR, branch, and
  worktree" wording described teardown in terms that assumed `/t-clean` existed
  downstream — exactly what the issue's Done-when asks fixed for `/t-cancel`'s
  description, just found in the site card rather than `SKILL.md`.
