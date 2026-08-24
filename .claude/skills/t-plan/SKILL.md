---
name: t-plan
description: Plan a task — pin its precise allowed-paths scope, risks, and validation split onto the issue before implementation. Required before changing a protected surface. Use after t-open, before t-work.
---

# Plan a task

Sharpen an existing issue into a bounded plan. Do not implement anything.

The argument names the issue (`/t-plan 152`). Planning is optional in general (ADR-001)
and **required before any change to a protected surface** (`CONSTITUTION.md` §3). If
planning a task reveals it will touch one, say so — the plan is now mandatory, not
optional, and `/t-work` will refuse without it.

## Procedure

1. Read `AGENTS.md`, `CONSTITUTION.md`, the issue (`tracker:view <id>` — resolve every
   `tracker:*` operation via `docs/adapters/TRACKER.md`; GitHub Issues by default), and
   its tracking issue if any.
2. Inspect the repository enough to plan honestly — relevant files, existing structure.
   Do not load everything by default.
3. Produce the plan and **append it to the issue body** (`tracker:edit-body <id>`,
   preserving the existing body). Appending only this section is the one edit to an
   issue body that is expected after its PR opens — `/t-status` exempts it; anything
   else changed at the same time is the intent drift that warning exists to catch.
   The section:

   ```markdown
   ## Plan
   ### Allowed paths
   <precise globs/paths the diff may touch — binding on t-work, checked by t-review>

   ### Risks / constraints
   <what could go wrong; constitution rules that apply>

   ### Validation
   agent_checks:
     - <runnable command or concrete procedure> — stage: implementation|review|either
       — proves: <what a pass demonstrates>
   human_checks:
     - <judgments cheaper or more reliable for a human>
   ```

4. **Scope-overlap check.** List every open issue and compare Allowed paths and Scope
   lines, using `tracker:list-open` — its contract requires a complete scan. A truncated
   list reports "no overlap" because it never looked, so a result that hits the backend's
   page limit is an incomplete scan: say so and paginate rather than concluding anything
   from it. A non-empty overlap
   is not automatically a refusal (some overlaps are sequential by `Blocked-by`), but it
   must be named in the plan so a person decides at plan time rather than at
   merge-conflict time.
5. Report — in plain prose per AGENTS.md §Communication, saying what the plan means in
   ordinary language before any internal terminology: validation ownership, open
   questions, and whether the task is ready for `/t-work`.

## Rules

- Tag every agent check with its stage; untagged checks get run twice by two stages.
- **State every done-when criterion machine-checkable where possible** — a runnable
  command whose exit code or output settles it. A criterion that genuinely cannot be
  machine-checked is not a failure: assign it to `human_checks` with one sentence on why
  (verification only possible post-merge is the classic case).
- The done-when acceptance check belongs to implementation, not review — review confirms
  behavior, it must not be the stage that first discovers it.
- If the issue is incomplete, fix the issue or stop with a clear question. Never hide a
  gap inside the plan.
- Do not implement, and do not create branches or PRs here.
