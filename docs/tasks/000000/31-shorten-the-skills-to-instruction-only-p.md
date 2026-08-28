# 31 — Shorten the skills to instruction-only prose
Issue: #31 · Part of: #22

## Asked
A behavior-preserving prose pass over the remaining skills once the structural removals
have landed: every rule and instruction survives, but rationale, history, and defensive
narration move out — to an ADR or `docs/architecture/` where durable, or are deleted
where the removed machinery made them moot. Target: no SKILL.md over ~120 lines. Skills
carry instructions; ADRs carry why.

## Done when
- `wc -l .claude/skills/*/SKILL.md` shows every file at or under ~120 lines (state any
  justified exception honestly in the record).
- The cold review explicitly verifies no behavioral rule was lost against the pre-trim
  text (human-judged criterion).
- `./scripts/consistency-check.sh` exits 0; CI green on the PR.

## Explicitly not
- No behavior changes of any kind — a rule change discovered mid-pass stops and gets
  its own issue.

## Decisions made along the way
- Scope turned out to be `.claude/skills/*/SKILL.md` only — every trimmed sentence
  already had a home in an existing ADR or architecture doc, so nothing needed to move
  into a new `docs/architecture/` file or a new ADR. `docs/adr/` and `docs/architecture/`
  stayed untouched (agent, 2026-08-28).
- `t-status`, `t-clean`, `t-plan`, `t-open` were left unedited: already at or under the
  ~120-line target (75/85/89/115) with minimal rationale relative to their instruction
  density — no removal was warranted (agent, 2026-08-28).
- Four skills land slightly over ~120 after trimming: `t-work` 128, `t-review` 128,
  `t-ship` 124, `t-cancel` 132 (from 162/175/185/166). Each is dense, safety-critical
  procedural content — exact git commands with `force-with-lease` safety, multi-precondition
  merge gates, a four-way branch-resolution refusal list, a five-phase destructive
  teardown — where further compression started costing precision rather than prose.
  Treated as the justified exceptions the issue's Done when anticipates, stated here
  rather than pushed further (agent, 2026-08-28).

## Deviations / notes
- **What moved where, per file** (the mapping the plan's implementation-stage check
  asked for — verify against `git diff main...HEAD -- .claude/skills/`):
  - **All four files**: restated ADR/architecture citations replaced inline
    restatements of their reasoning — e.g. `t-cancel`'s five safety rules now point at
    ADR-001 D3.1–D3.5 instead of re-explaining each; `t-ship`/`t-cancel`'s gate-format
    paragraphs ("a plain question … last thing in the message") now point at
    `docs/architecture/confirmation-gates.md`, which already states it in full, instead
    of restating it (dropped outright in `t-cancel`, kept as a pointer in `t-ship`).
  - **t-work**: dropped the worked example of why an unpushed commit is "the one
    failure that looks like a clean ship" (kept the rule: mismatch → stop and push);
    dropped restated ADR-001 §D4 bucket-math rationale (kept the formula and the
    pointer).
  - **t-ship**: same unpushed-commit narration cut as t-work; dropped the sentence
    explaining *why* the human confirmation is the strategic pass (ADR-001's Rationale
    already says a solo-shipped task "has had exactly one pair of eyes on it"); dropped
    "nothing can mark a judgment settled mechanically" narration around outstanding
    human checks (kept the rule: confirming acknowledges them).
  - **t-cancel**: dropped the explanatory clauses around why a rejected force-with-lease
    push means "another session moved the branch" (kept the mechanism and the stop
    rule); dropped restated ADR-001 D3 numbering references in favor of one citation at
    the top.
  - **t-review**: dropped the aside on why the isolation claim can't be verified after
    the fact ("a cold reviewer's comment and a warm one's are byte-identical" — kept as
    one clause, not a paragraph); tightened the four-way document-review criteria and
    the pending-human-checks explanation to single clauses per rule.
  - No rule, gate, refusal, or check was deleted — only the prose explaining *why* each
    exists, where that *why* already lives in ADR-001, ADR-002, ADR-003, or
    `docs/architecture/confirmation-gates.md`.
- Validated: `wc -l .claude/skills/*/SKILL.md` (table above), `./scripts/consistency-check.sh`
  (exit 0). Behavioral-equivalence is a human/cold-review judgment per the issue's own
  Done when — not machine-checkable — so the cold review is asked to diff each file
  against its pre-trim text (`git show main:.claude/skills/<name>/SKILL.md`) and confirm
  nothing binding was dropped.
