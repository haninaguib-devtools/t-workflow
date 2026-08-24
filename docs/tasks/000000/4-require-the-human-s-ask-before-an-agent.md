# 4 — Require the human's ask before an agent creates tracker artifacts
Issue: #4

## Asked
Nothing in the pipeline requires the human's agreement before an agent creates a tracker
artifact, and at least one instruction reads as a licence to create one unprompted:
`/t-work` Phase 2 said "Out-of-scope defects become new issues", and `/t-work` Fix mode
said a finding "becomes a new finding or a new issue". Both described the outcome, not
who decides it. `/t-open` §Timing and `/t-work`'s opening both protect against *starting
work* without being asked, but neither covered *minting an issue*, which is the act that
puts a new item on the owner's tracker under the owner's name.

This is not hypothetical. Working task #1, this pipeline opened issue #3 unprompted while
in `/t-work`, citing exactly that Phase 2 sentence; it was closed as not planned when the
owner objected. The workflow's own first principle is that work starts when a human says
it starts — `/t-open` exists for that — so an agent that can create issues on its own has
routed around the pipeline's entrance while appearing to follow it.

## Done when
- A single rule states that creating or modifying tracker artifacts — issues, comments,
  labels, issue state — outside the skill that owns the act requires the human to have
  asked for that specific thing. Its home is `AGENTS.md` §Conventions, where the
  "all changes go through the pipeline" rule already lives, so a cold session meets it on
  session start. Checkable: `grep -c "without being asked\|unprompted" AGENTS.md` is
  non-zero.
- `/t-work` Phase 2 and Fix mode say **propose and wait**, not "becomes a new issue".
  Checkable: `grep -c "become new issues" .claude/skills/t-work/SKILL.md` returns 0.
- `/t-review`'s finding handling says the same, since a reviewer that mints issues for
  its own findings has the same problem.
- The rule names its exceptions explicitly, so it is not read as forbidding the pipeline
  itself: `/t-open` creating the issues it was invoked to create, `/t-cancel` commenting
  and closing after its gate, `/t-ship` ticking a tracking issue and closing a shipped
  one, `/t-plan` editing the issue body it was invoked for. Each of those is either the
  skill's whole purpose or sits behind a human gate.
- `./scripts/consistency-check.sh` exits 0.
- Human check: read as a cold session, does the rule stop the unprompted case without
  making the pipeline's own tracker writes ambiguous? No command can settle that.

## Explicitly not
- Mechanical enforcement. Nothing in CI can see an issue that should not have been
  created; this is a rule an agent follows, and it belongs in the session-start contract.
  Whether a permission-level control (tool restrictions on the tracker CLI) is worth it
  is a separate judgment, not this task.
- Changing `/t-open`'s own behaviour. Creating issues is what it is invoked to do.
- Revisiting issue #3, which is closed. If its finding is worth working, that is a
  `/t-open` decision the owner makes.
- Editing `/t-open`, `/t-plan`, `/t-cancel`, `/t-ship` or `docs/workflow.md`. The new
  rule names those stages as exceptions by reference; none of them needed a change.

## Decisions made along the way
- The new rule is written as its own `## Conventions` bullet rather than folded into the
  existing "All changes go through the pipeline" bullet (Claude, 2026-08-24). That bullet
  governs *edits to the tree*; this one governs *writes to the tracker*. They are
  different surfaces with different exception lists, and merging them would have buried
  the tracker rule inside a bullet a reader scans for file-editing guidance.
- The rule's scope is stated as the whole tracker surface — creating issues, commenting,
  labelling, changing issue state — not just issue creation (Claude, 2026-08-24). Issue #3
  was an issue-creation failure, but a rule naming only that invites the same
  routing-around in another shape.
- Exceptions are expressed as "the skill invoked for that act, on the artifact it was
  invoked for" rather than a bare list of skill names (Claude, 2026-08-24). A bare list
  would license `/t-cancel` to comment on any issue it liked; the binding form is that
  the human's invocation of the stage *is* the ask, and it reaches only that stage's own
  artifact.
- The existing out-of-scope-work rule in `AGENTS.md` §Conventions was rewritten in place
  rather than deleted (Claude, 2026-08-24). It still has to say that out-of-scope work is
  not a drive-by change; only its disposal instruction ("becomes a new issue") changed to
  propose-and-wait.

## Deviations / notes
- **A first draft of the rule would have broken `/t-cancel` and `/t-ship`.** It ended
  "the invocation *is* the ask, and it reaches that stage's own artifact and no other",
  which forbids exactly the neighbour writes those two stages are required to make:
  `/t-cancel` Phase 4 step 6 comments on every dependent, child and parent and edits the
  tracking issue's checkbox, and `/t-ship` ticks and may close a tracking issue that is
  not the task's own. Caught by re-reading both skills against the draft before commit,
  not by any check. The rule now says the exception is the stage doing what its invocation
  asked for, and that a write reaching past the task's own issue is asked-for because the
  human agreed to it at that stage's confirmation gate. This is the "must not disable the
  pipeline it governs" risk the plan named, arriving exactly where the plan expected it.
