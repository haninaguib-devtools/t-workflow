# ADR-012: Documentation-only diffs skip the build check

**Status:** Accepted · 2026-09-08
**Deciders:** haninaguib

## Context

`AGENTS.md` §Checks names the check set every stage runs: check 1 is the project's own
build/test command (a consumer's local slot; this template has none), check 2 is
`consistency-check.sh`, check 3 is the `git diff` review against scope. Until this
decision every task ran all three regardless of what it changed. In a consumer, a task
that ratified an ADR — three Markdown files — spent about six minutes in a Maven build
and an Angular client build, locally and again in CI, exercising code no Markdown file
can reach. The ceremony was correct; the cost was not.

Skipping a check for a class of diffs is a **loosening** under `CONSTITUTION.md` §1.5
and workflow §11.3 ("removing a gate … needs ADR-grade rationale"), even when the gate
provably cannot fail on that class. This ADR is that rationale, so the rule lands as a
ratified decision rather than as bare mechanics an implementer happened to find
convenient.

## Decision

Check 1 runs unless the task's whole diff against the trunk is **documentation-only**,
decided by one executable, `.t-workflow/scripts/docs-only.sh`, over
`git -c core.quotePath=false diff --name-only <trunk>...HEAD`. The documentation set is
defined once, in that script: any `*.md` file, anything under `docs/**`, plus whatever
globs a project adds in `AGENTS.md` §Checks' documentation-only local slot. Nothing else
is documentation, however harmless it looks. When the script exits 0, check 1 is not
run and every place that would have reported it says exactly
`check 1 skipped: documentation-only diff` — the task record's Deviations / notes, the
PR body's `## Checks run`, and the review body. `/t-review` re-runs the script on the
same diff and treats a claimed skip it does not confirm as a high finding. Checks 2 and
3, the cold review on a protected surface, and every CI gate other than the consumer's
own build step are untouched by this rule; in CI the consumer's build step alone carries
a step-level `if:` on the same script's verdict.

## Rationale

- **The check's outcome is invariant on the skipped class.** A build reads source,
  configuration, and build inputs; by construction it does not read Markdown or the
  project's documentation tree. A check whose result cannot depend on the diff proves
  nothing by running, so skipping it loses no information — unlike every other gate,
  whose result on a documentation change is exactly what is under review.
- **The cut is binary, cheap, and auditable.** One script, one list, one exit code —
  the same discipline `protected-paths.sh` already established (0/1/2, an empty pipe is
  a broken caller). There is no heuristic about which tests a code change could affect;
  that is a different, riskier problem this decision deliberately does not open.
- **The skip is a verdict, never a judgment.** An implementer cannot declare a diff
  documentation-only; only the script can, and the reviewer re-derives it. A skip the
  script contradicts is a check that never ran, graded as such.
- **Every consumer gets it by sync, and can widen it without editing template text.**
  The rule and its defaults are template-owned; the slot holds a project's own extra
  documentation paths (a static site, say). The slot only adds — it cannot exempt a file
  from the default set, so no project can quietly widen "documentation" to cover a
  build input.

## Alternatives considered

- **Leave every check unconditional.** Simplest and always safe, but the cost is paid on
  every documentation task in every consumer forever, and a slow, pointless check is
  what gets routed around (workflow §11.2's own warning). Rejected.
- **Path-based test selection for code changes too.** Far larger saving, but it needs a
  model of which sources reach which tests, is wrong in ways that are hard to notice,
  and is exactly the "weaken a check to make work pass" shape §1.5 forbids. Named as a
  non-goal; nothing here prejudges it.
- **`paths-ignore` on the CI workflow.** Skips the whole workflow — record, plan, title,
  blocker and consistency gates included — for a documentation PR, which is precisely
  where those gates matter most. Rejected in favour of a step-level condition on the
  build step alone.
- **Let the implementer judge "obviously docs-only" by eye.** No executable twin, no
  way for review to confirm it, and the first disagreement becomes a merge-time
  argument. Rejected.
- **Skip the cold review too on documentation-only protected diffs.** ADRs and the
  constitution are protected *because* their prose is load-bearing. Rejected; review
  stays.

## Consequences / revisit triggers

- `AGENTS.md` §Checks carries the operative rule and the slot (`CONSTITUTION.md` §2.3);
  `/t-work`, `/t-review`, and `/t-drive` apply it; `ci.yml` publishes the verdict as
  `steps.docs-only.outputs.docs_only` for the consumer's build step to read;
  `installer/adopt.sh --build-command` writes the guarded step; migration V5 walks
  existing consumers through guarding their own step and filling the slot.
- **Revisit if any consumer's build reads Markdown or `docs/**` as an input** — a site
  generator that renders `docs/` into the shipped artifact, a test that asserts on a
  README, code generated from a Markdown spec. The honest fixes are, in order: move that
  input out of the default set's paths, or reopen this ADR to add an exclusion mechanism
  (the slot deliberately has none today). Never fix it by letting the build run on a
  "documentation-only" verdict — that hides a false skip instead of correcting the set.
- Revisit if the default set ever needs to *shrink*: this ADR fixes `*.md` and `docs/**`
  as documentation; a project for which `docs/**` holds build inputs is the trigger
  above, not a reason to hand-edit the script.
- Revisit if a second class of provably-inert diffs appears (generated lockfile bumps,
  say) — it deserves its own ADR at the same bar, not a widening of this one.
