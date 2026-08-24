# 1 — Define what /t-plan does when the issue already has a plan
Issue: #1

## Asked

`/t-plan` appends a `## Plan` section to the issue body, and is also the skill `/t-work`
and `/t-ship` send a task back to when the work grows onto a protected surface after
planning was already done. Nothing said what a second invocation does to the plan that is
already there, so the pipeline's own remediation path could produce an issue with two
`## Plan` sections and no rule for which one binds.

## Done when

- `/t-plan` states what a re-plan does to an existing `## Plan` section, unambiguously.
- `/t-work` and `/t-review` each say which section governs when they read one.
- `/t-status`'s edited-issue exemption covers a re-plan, not only a first plan.
- `./scripts/consistency-check.sh` exits 0.
- Human check: the chosen rule reads as the obviously right one across all four skills.

## Explicitly not

- Changing *when* a re-plan is triggered — `/t-work` Phase 3 and `/t-ship` precondition 1
  already decide that.
- Mechanizing a "exactly one `## Plan` section" check. Stated as a boundary in the issue:
  the rule has to exist before anything can check it.

## Decisions made along the way

- **The rule is: a re-plan replaces the existing `## Plan` section wholesale** (Claude,
  2026-08-24, for the human to accept or reject at the merge gate). Three options were
  live — replace, amend, append.

  *Append* was rejected because it is the defect: two sections, no rule for which binds.
  *Amend* was rejected because it makes the section's history and its current content the
  same text, so a reader cannot tell which paths are binding now — the plan's whole job
  is to state current bounds. *Replace* leaves exactly one section, which is always the
  current one, and needs no precedence rule in the three skills that read it.

  What replace appears to lose — why the scope changed — is not lost: the task record is
  the durable account (this file), and its Deviations section is where a re-plan's reason
  belongs. The issue states intent; the record states history. That split already exists —
  `docs/tasks/README.md` says task intent changes in the record, never in the issue body,
  and `/t-open` §Rules says the same — and this rule is the one exception to it, so
  `/t-plan` now says so out loud.

## Deviations / notes

- **Cold review (PR #2) found the `AGENTS.md` attribution above was false** (medium).
  Both this record and `/t-plan` cited `AGENTS.md` §Conventions for the intent-in-the-
  record rule; `AGENTS.md` does not state it. Corrected in both places to the actual
  homes, `docs/tasks/README.md` and `/t-open` §Rules. Worth noting the consistency script
  could not catch this: check 2b verifies a named section *exists*, not that it says what
  a citation claims.
- **The "nothing is lost by replacing" argument was not closed** (medium, same review).
  `/t-plan` reported the old Allowed paths but nothing required them to reach the record,
  so across sessions the previous scope could vanish — the tracker's edit history being
  ruled out by `CONSTITUTION.md` §1.3. Closed from both ends: `/t-plan` must now quote the
  previous Allowed paths verbatim, and `/t-work` step 6 must write them into Deviations
  before resuming work. `/t-work` is inside this task's Allowed paths, so this is not
  scope drift.
- **`/t-plan` step 3 still opened with "append"** (low, same review), which read as the
  general rule against "delete the old one" three lines below. Reworded to "write", with
  append and replace named as the two cases.
- One finding from that review was **not** fixed here: a plan's Allowed paths exclude the
  task record that `/t-work` step 6, `CONSTITUTION.md` §1.2 and CI's `record` job all
  require, so every plan either omits a mandatory file or contradicts its own "Nothing
  else". It stays recorded in the review comment on PR #2; whether it becomes a task is
  the owner's call, through `/t-open`.
- **Deviation, and a process failure worth recording:** this session opened that finding
  as issue #3 without being asked, then closed it as not planned when the owner objected.
  Nothing in the pipeline authorized it — `/t-open` exists precisely so a human decides
  what becomes work. The licensing text was `/t-work` Phase 2's "out-of-scope defects
  become new issues", which reads as an instruction to create one rather than to propose
  one. That is a real gap in the workflow, not a lapse peculiar to this session.
