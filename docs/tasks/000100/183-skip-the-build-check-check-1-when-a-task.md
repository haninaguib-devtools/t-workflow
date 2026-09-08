# 183 — Skip the build check (check 1) when a task's diff touches only documentation
Issue: #183

## Asked
Make "run the checks" proportional to what a task actually changed. Today every task
runs the full check set, and check 1 — the project's build/test command — is by far
the slowest: a consumer's task that changed three markdown files spent about six
minutes building and testing code no markdown file can affect, locally and again in
CI. The template should give the check set a path-aware rule: when a task's diff is
documentation-only, check 1 is skipped and reported as skipped; checks 2
(`consistency-check.sh`) and 3 (`git diff` review against scope) always run. The rule
lives in the template so every consumer gets it; the build command itself stays in the
consumer's `<!-- local -->` slot exactly as now.

## Done when
- A script (`.t-workflow/scripts/docs-only.sh`) decides, from
  `git diff --name-only <trunk>...HEAD`, whether the diff is documentation-only. The set
  is defined once, in the script: `*.md` anywhere, `docs/**`, and nothing else. Any
  other path — code, config, workflows, scripts, `.t-workflow/**`, the manifest — is
  *not* docs-only, even if it looks harmless.
- The docs-only set has a `<!-- local -->` slot in `AGENTS.md` for project-specific
  additions (e.g. a consumer's `site/**`). Fresh installs ship it empty; the template
  default (`*.md`, `docs/**`) works without it. The script reads the slot's globs in
  addition to its own defaults.
- `AGENTS.md` "## Checks" states the rule in ordinary words, above the local slot:
  check 1 runs unless the diff is docs-only per the script; when skipped, the record and
  the PR body say "check 1 skipped: documentation-only diff" rather than silently
  omitting it.
- `/t-work` (and the fix-pass path) and `/t-drive` follow the rule when they run the
  checks; `/t-review` treats "check 1 skipped" as valid only if the script agrees, and
  flags it as a finding otherwise.
- `.github/workflows/ci.yml` gains the same gate for the consumer's check-1 step (a
  step-level `if:` on the script's result), keeping the `record` and `consistency`
  steps unconditional. The template's own CI, which has no check 1, is unaffected.
- The change ships as a template release with a migration note, so consumers pick it
  up through `/t-update`.

## Explicitly not
- Deciding which *code* changes could skip which tests. Docs-only is a binary, cheap,
  obviously-safe cut; finer-grained test selection is a different, riskier problem.
- Skipping the cold-context review for docs-only diffs on protected surfaces. ADRs and
  the constitution are protected precisely because prose there is load-bearing; review
  stays.
- The slot only *adds* docs paths. A project that wants to *exclude* a `docs/**` file
  from the skip (say, docs that are build inputs) is a later problem, not this one.
- Changing the single human confirmation stop in `/t-drive` / `/t-ship` (ADR-004/006).
- Cutting the release tag itself — a maintainer does that by hand after merge
  (`docs/architecture/manifest.md`), then corrects the migration's `Introduced:` line.
- Consumer follow-through (locklane adding `site/**`, any consumer guarding its own
  build step) — done in each consumer through `/t-update`, guided by migration V5.

## Origin
none

## Verification
none

## Feedback
none

## Decisions made along the way
- The skip is a gate narrowing under `CONSTITUTION.md` §1.5 / workflow §11.3, so it is
  ratified by ADR-012 rather than landing as bare mechanics; `AGENTS.md` §Checks carries
  the operative one-line rule with the pointer (§2.3). (haninaguib via /t-plan,
  2026-09-08)
- `docs-only.sh` echoes the paths that are *not* documentation on exit 1 — the inverse
  of `protected-paths.sh`, which echoes the paths that matched — because the useful
  thing to report is why the build is running. (agent, 2026-09-08)
- The script finds its `AGENTS.md` slot by scoping to the template-owned
  `### Documentation-only paths` sub-heading, never by counting marker pairs; the one
  reader that does count pairs, `installer/adopt.sh`'s `splice_local_slot`, has its
  ordinals updated in this task. (agent, 2026-09-08)
- The CI step publishes `docs_only=false` on `push` events: there is no base ref to
  diff against, and the trunk build always running is cheap insurance. (agent,
  2026-09-08)

## Deviations / notes
- **Re-planned before any file was touched.** Between `/t-plan` and `/t-work` the trunk
  moved (#182 merged the #168 initiative), landing #169's project-notes slot in
  `AGENTS.md`, #170's `ci.yml` trunk slot and migration V4, #173's ADR-011, and #172's
  `installer/adopt.sh`, which splices `AGENTS.md` slots by ordinal position and
  generates the consumer's build step. `/t-plan 183` was re-run by this `/t-drive` run;
  the re-plan added `installer/adopt.sh` and `installer/test.sh` to Allowed paths,
  confirmed V5 and ADR-012 as the numbers, and replaced the "new slot is last in the
  file" placement rationale with the ordinal-shift handling above. The previous Allowed
  paths, verbatim:

  ```
  - `.t-workflow/scripts/docs-only.sh` (new — the one place the docs-only set is defined)
  - `.t-workflow/scripts/plumbing-test.sh` (a new fixture section for `docs-only.sh`, and a slot round-trip case for the new `AGENTS.md` slot)
  - `.t-workflow/scripts/consistency-check.sh` (only the comment above check 3's slot reader, which today says `AGENTS.md` carries "a second, unrelated `<!-- local -->` pair under `## Checks`" — there will be two)
  - `AGENTS.md` (§Checks only: the rule in ordinary words, the new docs-only slot, and the trailing CI-wiring sentence)
  - `.github/workflows/ci.yml` (one new template-owned step immediately before the trailing `<!-- local -->` slot, plus the comment above that slot showing the `if:` idiom a consumer's build step uses)
  - `.claude/skills/t-work/SKILL.md` (Phase 3 steps 1 and 5; Fix mode; Feedback mode step 3)
  - `.claude/skills/t-review/SKILL.md` (step 6)
  - `.claude/skills/t-drive/SKILL.md` (the three places that say "a check `AGENTS.md` §Checks names fails" / "re-run the checks the findings falsify" — one clause each pointing at the rule)
  - `docs/architecture/local-slots.md` (the slot count and inventory, the placeholder list, and the paragraph "Why only item 1 of §Checks is marked")
  - `docs/adr/012-*.md` (new — the ADR `CONSTITUTION.md` §1.5 / workflow §11.3 require for narrowing a check; 011 is reserved by #173)
  - `migrations/V5__docs-only-check-gate.md` (new — V4 is reserved by #170; gaps are allowed by `docs/architecture/migrations.md`)
  - `README.md` §The two fills, `installer/templates/README.md` §Checks item, `installer/bootstrap.sh` exit-message text — one clause each, only where the sentence that tells a consumer to add its build command to `ci.yml` needs to also say "guarded by the docs-only step"
  - `docs/tasks/000100/183-*.md` (the record)
  ```
- Check 1 does not exist in this repository (`AGENTS.md` §Checks item 1 still reads
  "none yet"), so there was nothing to run or skip here; the new rule was exercised
  against this task's own diff, which is *not* documentation-only (exit 1), as the plan
  requires.
- `migrations/README.md` still says "No migration files exist yet" although V1–V5
  exist. Outside this task's Allowed paths; proposed as its own small issue in the
  closing report rather than fixed here.
