# 140 — Define the external collaboration model and boundaries
Issue: #140 · Part of: #139

## Asked
Write the architectural decision for how t-workflow supports work that originates outside
its own issue lifecycle — an external proposal or research system, a project's preview
evidence, contributor feedback, and asynchronous human verification — without ever giving
an external system authority to start implementation, change scope, mark review
complete, or merge. Preserve the two-level initiative-to-task hierarchy: an external
proposal is an origin of work, not a third workflow level.

## Done when
- An accepted ADR defines the responsibilities of t-workflow, an external observer, the
  project, and the human maintainer.
- The ADR defines which information is authoritative and where it lives.
- It distinguishes human authorization from machine-supplied context or evidence.
- It explains how one external proposal may produce either one task or an initiative
  with several tasks.
- It defines how feedback received after implementation begins returns to the task.
- It records the security and trust boundaries for links, webhook data, comments, and
  external status.
- It identifies the child tasks needed to implement the decision and their dependencies.

## Explicitly not
- Implementing Proposarium.
- Adding a Proposarium-specific adapter.
- Changing the existing implementation or merge authority.
- Adding a third issue hierarchy level.
- Building any of the concrete mechanisms this ADR describes (an origin field, an
  observer contract, a preview adapter, a verification schema, a t-work feedback pass, a
  t-drive stopping point, t-status states) — each is its own sibling task under #139
  (#141–#147), which this ADR's own "child tasks" section names and sequences.

## Origin
none

## Verification
none — this task predates the convention; retrofitted per `docs/tasks/README.md`'s "or
none" rule as part of assembling the initiative's aggregate PR.

## Feedback
none — no feedback pass has run against this task itself.

## Decisions made along the way
- Placed the ADR's one required operative pointer (`CONSTITUTION.md` §2.3) in
  `CONSTITUTION.md` §1 Delivery rather than `AGENTS.md`'s Conventions section: the rule
  it states — an external system may originate or observe work but never starts
  implementation, changes scope, completes review, or merges — is a Delivery-level
  invariant of the same shape as the other §1 bullets (who may move `main`, what a squash
  commit must carry), not a process convention describing a skill's own steps. No
  `AGENTS.md` pipeline-table row is added by this task since no skill or stage changes
  here — the sibling tasks that do change skills add their own rows/lines when they land.

## Deviations / notes
- none
