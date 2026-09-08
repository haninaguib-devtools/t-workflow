# 166 — Design an installer/adopt.sh mode for retrofitting t-workflow into an existing repository
Issue: #166 · Part of: #168

## Asked
Decide how t-workflow gets retrofitted into a repository that already has code,
history, and a team, and record that decision as a design document. Today the delivery
system only knows how to arrive before a project's first commit: the installer refuses
an existing directory, the README's by-hand route starts with `git init`, and the
site's Adopt section says "install before the first application commit". Someone with
an existing project has no supported path in, and the obvious workaround (copy the
files in by hand) has to break the rules it is installing. This task settles the shape
of an `installer/adopt.sh` mode and the rule changes it needs, so implementation can be
split into well-bounded follow-up tasks. Merging the design is the act of deciding
(`docs/workflow.md` §7).

## Done when
- A design document `docs/architecture/adoption.md` is merged that answers, with a
  decision and rationale for each: (1) which rule lets the adoption change land, and
  whether it needs a constitutional amendment via ADR; (2) what `installer/adopt.sh`
  does on each collision class (real `CLAUDE.md`/`GEMINI.md`, existing `.claude/`,
  existing `.gitignore`, `README.md`, existing `.github/workflows/ci.yml`, existing
  `docs/adr/`), and which it refuses; (3) how the CI gates behave on non-task branches
  after adoption (always fail, warn-only until switched on, or exempt by pattern); (4)
  how ADR numbering coexists with an existing decision log; (5) whether
  `github-bootstrap.sh` runs as part of adopt or stays a separate, explicitly confirmed
  step; (6) how the result becomes a pinned consumer (`.template-manifest.json`, the
  provenance line, `/t-update` first adoption).
- The design document ends with a list of the follow-up implementation tasks it
  implies, each with a one-line goal, so `/t-open` can mint them without guessing.
- `./.t-workflow/scripts/consistency-check.sh` exits 0.
- A cold review (`/t-review`) reports `readiness: ready` — `docs/architecture/` is a
  protected surface (`CONSTITUTION.md` §3), so a plan and independent review are both
  required.

## Explicitly not
- Writing `installer/adopt.sh`, amending `CONSTITUTION.md` §3, changing
  `.github/workflows/ci.yml`, or touching `installer/bootstrap.sh` — these are the
  follow-ups the design names (#169–#174), opened alongside this task rather than
  guessed now.
- Changing `/t-update`'s current first-adoption behaviour.
- Supporting adoption into a repository whose forge is not GitHub.

## Origin
none

## Verification
none — the plan's `### Validation` names two `human_checks:` items (whether the six
decisions are correct and consistent with #169–#174, and whether rejecting a
genesis-exception amendment is the right call), not a structured `verification:` list;
per `docs/architecture/verification.md` §Relationship to `human_checks`, those stay
ordinary `human_checks` judgments, restated by `/t-review` in its own `## Pending human
checks` section rather than tracked here.

## Feedback
none

## Decisions made along the way
- Reconciled the six required decisions against #169–#174's already-written bodies
  before drafting, per the plan's own instruction: every decision in
  `docs/architecture/adoption.md` matches what those five sibling issues already
  assume (verbatim `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` move into `AGENTS.md`'s
  project-notes slot; existing `.claude/` kept, refusing only a `t-*`-named skill dir;
  `docs/adr/` coexists, refusing a consumer file below the `100` prefix; any other
  template-owned path present is a refusal; CI gates stay strict, no warn-mode;
  `github-bootstrap.sh` stays a separate explicitly-confirmed step; the manifest is
  written directly, pointed at a release tag). No disagreement was found — see
  Deviations below (agent, 2026-09-08).
- Independently re-derived §1's central judgment call (extend the genesis exception vs.
  treat adoption as an ordinary task) rather than restating the initiative's "starting
  proposal" as settled: concluded ordinary-task treatment is correct because the
  chicken-and-egg problem the genesis exception would seem to solve is already resolved
  by `adopt.sh` writing the whole template tree onto the task branch *before* any
  pipeline stage reads it — `/t-plan` and `/t-review` need the skills to exist on the
  checkout they run against, never on the trunk. `CONSTITUTION.md` §3's own text
  ("never covers a second round of 'just this once'", never covers "work on the tooling
  that creates one") independently rules out reusing the genesis exception for this
  (agent, 2026-09-08).
- Avoided writing the literal token `ADR-011` anywhere in the design document: that ADR
  does not exist yet (it is opened by #173), and `consistency-check.sh` check 2
  resolves every `ADR-NNN` token in a living doc to a `docs/adr/NNN-*.md` file that
  must already exist. The document instead describes the new ADR by what it does
  ("a new ADR", "the ADR §1 above requires") without naming its number, so the
  document stays internally correct regardless of exactly when #173 lands (agent,
  2026-09-08).

## Deviations / notes
- none — the design's own reasoning agrees with every decision #169–#174's bodies
  already assumed; no disagreement to flag per the plan's Risks/constraints.
