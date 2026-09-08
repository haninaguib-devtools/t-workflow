# ADR-011: Adoption lands through the ordinary pipeline, not a new exception

**Status:** Accepted · 2026-09-08
**Deciders:** haninaguib

## Context

Until initiative #168, the delivery system only knew how to arrive at a project's very
start: the installer refuses to run against a directory that already has something in
it, and the by-hand route in `README.md` begins with `git init`. A team that already has
code, history, and a working repository had no supported door in — the obvious
workaround, copying the template's files in by hand, breaks the very rules it is trying
to install, because there is no tracker issue, no branch, and no reviewed PR behind the
copy.

Task #166 produced `docs/architecture/adoption.md`, the binding design for
`installer/adopt.sh` (built by #169–#172). That document resolves an apparent
chicken-and-egg problem — the diff adoption produces *is* the skills, adapters, and CI
gates the pipeline needs to process a task, so how can the pipeline process the task
that adds them? — and settles two questions this ADR records the decision for: which
rule lets the adoption change land at all, and how the post-merge CI gates behave for
branches that predate adoption. This task (#173) carries the constitution wording, the
`README.md` section, and the `AGENTS.md` clause those decisions require; this ADR is
the record of the decision itself, per `CONSTITUTION.md` §2.1 ("every ADR carries
rationale, alternatives, and revisit triggers") and §Amendment ("this file changes only
by PR ... normally alongside an ADR").

## Decision

**Adopting t-workflow into an already-existing repository is ordinary protected task
work, run from the adoption branch itself — never a second pass through the genesis
exception (`CONSTITUTION.md` §3), and never a new exception of its own.**

`installer/adopt.sh` writes the whole merged tree onto a task branch
(`wip/<id>-adopt-t-workflow`) *before* any pipeline stage runs against it. From that
point the checkout already has every skill, script, and adapter the pipeline needs, so
`/t-plan <id>` and `/t-review <id>` run against it exactly as they would for any other
task — the trunk only gains those files once the adoption PR is reviewed and merged,
the same as any other protected change. There is no moment where the pipeline is asked
to process a diff it cannot read.

**Post-merge CI gates land strict on non-task branches — no warn-only mode.** A pull
request whose head branch is not shaped `wip/<id>-<slug>` fails the record/plan/title
checks the moment the adoption PR merges, exactly as it always has for a generated
project. The rollout lever is not in the tree: `.t-workflow/scripts/github-bootstrap.sh`
(squash-only merges, delete-branch-on-merge, branch protection making the new checks
required) is a separate step a human runs, explicitly, only after the adoption PR
itself has merged. Before that script runs, the new workflow reports red or green but
blocks nothing, because nothing on the forge yet requires it to pass.

## Rationale

- **The chicken-and-egg problem is resolved by write-before-review, not by an
  exception.** Nothing about running `/t-plan` or `/t-review` requires the pipeline's
  files to exist on the trunk — only on the checkout the session is reading from.
  `adopt.sh` already produces that checkout, so no special vehicle is needed to get the
  task processed.
- **`/t-update` is the working precedent.** It already changes every template-owned
  file in a pinned consumer as an ordinary protected task with no exception of its own.
  Adoption is `/t-update`'s first sync, arriving by a different door — a script that
  also builds the initial manifest, rather than one that reads an existing one — so
  treating it as a special case would be an inconsistency to defend, not a
  simplification.
- **A tree-based warn-only switch duplicates what branch protection already gives for
  free, and is exactly the soft guardrail `CONSTITUTION.md` §1.5 warns against.**
  `github-bootstrap.sh` already gives a team a deliberate, human-timed moment to make
  the gates required; a second on/off switch inside the workflow file itself is a
  guardrail a person must remember to later tighten — the failure mode §1.5 exists to
  rule out.

## Alternatives considered

- **Extend `CONSTITUTION.md` §3's genesis exception to cover adoption.** Rejected, for
  three independently sufficient reasons: the exception's own text already forecloses
  it — it "never covers a second round of 'just this once'" and belongs only to "the
  repository being *created*," never to "work on the tooling that creates one," and an
  already-existing repository already had its genesis; it is unnecessary, since the
  write-before-review resolution above closes the only gap the exception would need to
  bridge; and it would make `/t-update`'s existing precedent — the same kind of
  whole-tree change, landed with no exception — an inconsistency needing its own
  defense.
- **A warn-only CI mode for non-task branches, built into the workflow file itself
  (a `continue-on-error`-style softening).** Rejected: it is a second, tree-based
  on/off switch duplicating what branch protection already gives for free, and a
  warn-only gate a person must remember to later tighten is precisely the kind of
  guardrail `CONSTITUTION.md` §1.5 says is never built softly in the first place.
  `github-bootstrap.sh`, run once and explicitly, is the rollout lever instead.

## Consequences

- `CONSTITUTION.md` §3's genesis paragraph gains one sentence pointing at adoption as
  ordinary work through `installer/adopt.sh`, changing neither the exception's own
  wording nor its stated end-point.
- `README.md` gains a §Adopting an existing repository section describing the command,
  what it merges and refuses, the plan-and-review-from-the-branch step, and
  `github-bootstrap.sh` as the confirmed post-merge step.
- `AGENTS.md` §Conventions' first bullet names `installer/adopt.sh`, run on the
  adoption task's own branch, as that task's work stage, the same way `/t-update`'s own
  sync procedure already is for a sync, without either being `/t-work` itself.
- A pre-existing open PR, a Dependabot- or Renovate-style branch, or a teammate's
  habitual branch name goes red against the new checks the moment the adoption PR
  merges — genuinely, because it does not carry what the pipeline now requires, not
  because of a defect — until the team is ready and runs `github-bootstrap.sh`.
- A known, separately-flagged gap is **not** resolved by this decision or this task:
  `CONSTITUTION.md` cites `README.md` §Bootstrapping, and `consistency-check.sh`
  resolves that citation against the *current repository's own* `README.md` — but
  `adopt.sh` never touches a consumer's `README.md` (§2 above), so a real adopted
  repository's own README essentially never carries that heading, and the check fails
  on it until a person adds one by hand. #172's task record and its independent
  reviewer both flagged this; it remains open, proposed as a follow-up issue rather
  than opened by this task (`AGENTS.md` §Conventions).

## Revisit triggers

- If a real adoption's collision or refusal rules turn out to need a case
  `docs/architecture/adoption.md` did not anticipate, revisit that document first; this
  ADR's decision (ordinary pipeline, no exception; strict CI with a human-timed
  rollout lever) is the boundary a revision would need to stay inside, or else
  supersede here.
- If `github-bootstrap.sh` being a separate, human-run step proves too disruptive in
  practice — teams routinely stuck red for reasons a warn-only period would have
  smoothed over — revisit the CI-gate decision specifically, weighing that evidence
  against §1.5's standing objection to soft guardrails.
- If the `README.md` §Bootstrapping gap noted under Consequences is ever addressed
  (by a follow-up task, or by a future change to `consistency-check.sh` itself), this
  ADR's Consequences entry is stale and should be corrected or struck by whichever
  change resolves it.
