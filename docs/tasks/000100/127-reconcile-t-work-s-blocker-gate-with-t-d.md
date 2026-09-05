# 127 — Reconcile /t-work's blocker gate with /t-drive's merged-but-open sibling blockers
Issue: #127

## Asked
A driven initiative can chain one child on another without anyone bending a rule. When
`/t-drive` works an initiative's children in dependency order, child A is merged into
the integration branch and only then child B, which is blocked by A, starts — but A's
issue stays open until the aggregate PR reaches the trunk, so `/t-work`'s blocker gate
(`check-blocker-gate.sh`, which wants every blocker closed as completed) refuses B by its
letter while `/t-drive` Phase 2 step 1 says a merged sibling no longer holds a child.
Three driven runs in a consumer repo each resolved that by hand, in the record. Put the
reconciliation where the gate executes, name it in both skills in the same words, record
it in an ADR, and keep CI from failing a driven child on the same ground.

## Done when
- `/t-work`'s blocker gate, when `/t-drive` invokes it for a child of an initiative,
  treats a blocker that is a sibling child of the same initiative as satisfied when that
  sibling's PR is merged into the initiative's integration branch (head `wip/<sibling>-*`,
  base `wip/<initiative>-integration`, state MERGED) and its latest cold review reads
  `readiness: ready`. Any other blocker — outside the initiative, or a sibling that is
  open, excluded, or cancelled — is judged exactly as today.
- The rule lives in `check-blocker-gate.sh`, which takes the sibling dispositions as
  input, with fixtures in `plumbing-test.sh`: sibling merged + ready review → pass;
  sibling merged but no ready review → fail; sibling open → fail; sibling cancelled →
  fail; outside blocker open → fail.
- `/t-work` Phase 1 step 2 and `/t-drive` Phase 2 step 1 name the rule in the same
  words, and an ADR amending ADR-004 records the reconciliation.
- A standalone `/t-work <child>` on a child whose sibling blocker is merged-but-open says
  so explicitly and names `/t-drive <initiative>`, rather than silently applying the
  driven reading or silently refusing.
- CI's `blockers` step does not fail a driven child (base = integration branch) on a
  merged-but-open sibling.

## Explicitly not
- Closing a child's issue at its integration-branch merge (ADR-004 Decision 3 keeps
  children open until the work reaches the trunk).
- Any change to how blockers outside an initiative are judged.
- Editing `AGENTS.md`, `CONSTITUTION.md`, `docs/workflow.md`, or `docs/adapters/` — the
  operative rule lands in the two skills, as ADR-007 and ADR-008 did with theirs.

## Decisions made along the way
- The sibling dispositions reach the script as one JSON file (`--siblings <initiative-id>
  <file>`) whose entries carry the raw shape the two forge reads already return — PR
  rows (`state`, `headRefName`, `baseRefName`) and review rows (`submittedAt`, `body`) —
  so the script judges the rule itself and every branch of it is a fixture. (agent, plan
  on the issue, 2026-09-04)
- CI's scoping is done inside the script (`--pr-base <ref>`) rather than as a YAML `if:`
  on the step, so the "integration-branch PR is judged by the driving session, not by
  CI" rule is fixture-tested rather than only readable. (agent, plan on the issue,
  2026-09-04)
- The amendment is a new ADR-009 with `### D<n>.` headings, never an edit to ADR-004
  (`CONSTITUTION.md` §2.1; the ADR-007/ADR-008 precedent). (agent, plan on the issue,
  2026-09-04)

- Only a still-OPEN sibling can be satisfied by its driven merge: the first cut let a
  cancelled sibling with a merged PR pass; the fixture "sibling cancelled → fail"
  caught it, and the script now checks the blocker's own state before consulting the
  dispositions. (agent, 2026-09-04)
- An unparsable blockers or siblings file exits 2, never 0. Before this task an
  unparsable blockers file produced an empty "not closed" list and an OK — the unsafe
  direction — in the same script this task already rewrites; hardened here with a
  fixture rather than left as a separate issue. (agent, 2026-09-04)

## Deviations / notes
- `consistency-check.sh`'s ADR-reference check pairs the first `ADR-NNN` on a line with
  any `D<n>` later on that line, so a sentence mentioning ADR-004 and `ADR-009 D1` on
  one line fails as "ADR-004 D1 does not resolve". Two such lines were reflowed; no
  check was changed.
- `plumbing-test.sh` section 11 copies only tracked files into its fixture repo, so a
  new ADR referenced by a skill must be at least staged before that section passes —
  worth knowing for the next task that adds an ADR.
- The rule sentence's identity across the two skills was checked with:
  `awk '/^ *A blocker that is a sibling child of the same initiative counts as satisfied$/{f=1} f{sub(/^ +/,""); print} f && /completed, or nothing\.$/{exit}' <SKILL.md>`
  on each file, then `diff` of the two outputs (empty).
