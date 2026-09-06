# 145 — Add a feedback implementation pass to t-work
Issue: #145 · Part of: #139

## Asked
Give `/t-work` an explicit mode for resuming a task in response to contributor
feedback, preview findings, or manual quality-assurance evidence. The pass must retain
normal scope controls and make the relationship between the feedback, resulting
changes, and repeated checks visible.

## Done when
- A maintainer can invoke `/t-work` for a feedback pass and provide a durable evidence
  URL or reference.
- The skill classifies the feedback as clarification, defect, in-scope adjustment, or
  proposed scope expansion before editing code.
- Scope expansion requires the same explicit human authorization and re-planning
  expected elsewhere in the workflow.
- The task record identifies the feedback source and the changes made in response.
- Checks whose previous evidence was invalidated are rerun.
- Existing review and human verification are invalidated when the new commit makes
  their evidence stale.
- The draft PR remains the implementation surface throughout repeated feedback cycles.
- Ordinary `/t-work` behavior remains unchanged when no feedback reference is
  supplied.

## Explicitly not
- Automatically accepting every external suggestion.
- Letting comments silently change task scope.
- Creating a second implementation branch for each feedback round.
- Replacing `/t-review`.

## Origin
none

## Verification
none — this task declares no `verification:` entry of its own; it builds the
mechanism a *future* task's plan can use, and reuses the existing invalidation
machinery `## Verification` entries already have (`docs/architecture/verification.md`).

## Decisions made along the way
- **No new ADR** (haninaguib, via the driving session, 2026-09-06): ADR-010 §D6
  already decided the model a feedback pass implements — classify before editing,
  route a proposed scope expansion through the same explicit authorization and
  re-planning any other scope growth needs, never open a second branch or PR, and
  invalidate stale review/verification evidence rather than leaving it standing. This
  task builds ADR-010's own named mechanism (`#145`), the same tightening-not-loosening
  reasoning #141 and #144 already used for their own no-new-ADR calls
  (`docs/workflow.md` §11.2/§11.3).
- **No new invalidation logic** (haninaguib, 2026-09-06): a feedback pass is a mode
  of `/t-work` that produces a new commit through the existing Phase 3, so it inherits
  `check-review-gate.sh`'s existing timestamp-based review staleness (any review that
  predates the new head commit already fails that gate) and Phase 3 step 2's existing
  verification-invalidation judgment (`docs/architecture/verification.md`) for free.
  Building a second staleness mechanism here would risk a second, possibly-diverging
  notion of "stale" — the risk the plan's own Risks/constraints section named.
- **Evidence recorded, never fetched** (haninaguib, 2026-09-06): a feedback reference
  (an external URL, a preview finding, a contributor's comment) is copied verbatim into
  the record and the invocation is the human's own account of what it says; no skill
  step resolves, fetches, or executes the reference itself, mirroring
  `external-origin.md`'s existing rule for an origin's `url` (ADR-010 §D7).
- **New `docs/architecture/feedback-pass.md`** (haninaguib, 2026-09-06), in the same
  style as `external-origin.md`/`verification.md`, rather than folding the same rules
  directly into `t-work/SKILL.md`: keeps the skill file itself readable as a sequence
  of steps, and gives `/t-review` and a future reader one place to check the shape
  against, the same pattern the two already-merged siblings established.
- **`## Feedback mode` placed after the existing `## Fix mode` section, and the
  Phase 1 step 5 mode-detection paragraph extended rather than rewritten** (haninaguib,
  2026-09-06): keeps this addition legible as a separate insertion against #141's
  `## Origin` and #144's `## Verification` material already in the file, per this
  task's own plan-time instruction not to restructure what is already there.
- **New `## Feedback` record section, always present (reads "none" until a feedback
  pass has run)** (haninaguib, 2026-09-06): mirrors the existing `## Origin`/
  `## Verification` convention (`docs/tasks/README.md`) so `check-record.sh`'s
  generic per-heading check (derived from `TEMPLATE.md`, no code change needed) covers
  it for free, and so a cold reviewer always finds the section in the same place
  whether or not this task has ever had a feedback round.

## Deviations / notes
- **Re-plan mid-task** (haninaguib, 2026-09-06): the first `/t-plan 145` did not
  anticipate that adding `## Feedback` to `docs/tasks/TEMPLATE.md` would need
  `.t-workflow/scripts/plumbing-test.sh`'s own `check-record.sh` fixture records
  updated too — `plumbing-test.sh` failed ("a correct record passes" and the
  `--multi` case) once the fixture records no longer carried every heading
  `check-record.sh` now derives from the widened template, exactly the same
  fixture-currency gap #141 (for `## Origin`) and #144 (for `## Verification`) each
  already hit and fixed in turn. Old Allowed paths (first plan): `.claude/skills/
  t-work/SKILL.md`, `docs/architecture/feedback-pass.md` (new), `docs/tasks/
  TEMPLATE.md`, `docs/tasks/README.md`, `docs/workflow.md`, this task's own record.
  New Allowed paths add exactly one line: `.t-workflow/scripts/plumbing-test.sh`
  (fixture data only — no new fixture section, no gate-script behavior change).
  Re-planned via a second `/t-plan 145` before touching that file, per `/t-work`
  Phase 1 step 3's "work that grows onto a protected path stops for a plan."
