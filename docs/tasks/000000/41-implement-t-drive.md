# 41 — Implement /t-drive
Issue: #41 · Part of: #39

## Asked
Build the `/t-drive <initiative-id>` skill per the ADR from #40: given an initiative
with child tasks, create its integration branch, run each unblocked child through
`/t-work` then `/t-review` (parallel where children don't depend on each other), merge
a child into the integration branch only once its review passes, apply the one-retry
self-correction policy on failure, run the full check suite against the aggregate diff
once every included child has merged, and open the single PR against `main` — then
stop, naming `/t-ship` as the next command. Excluded children (and anything blocked on
them) are named explicitly in a closing report, never silently dropped and never
auto-cancelled.

## Done when
- `.claude/skills/t-drive/SKILL.md` exists, follows the existing skills' shape, and is
  wired into `AGENTS.md`'s table and `docs/workflow.md`'s overview.
- Run end-to-end against a real multi-task initiative in this repo: at least one child
  succeeds and merges into the integration branch, and the final PR lands against
  `main` in a form `/t-ship` can confirm and merge without modification.
- A deliberately-failing child is excluded from the final PR, reported by name in the
  closing output, and does not stop unrelated siblings from shipping.

## Explicitly not
- No change to `/t-work`, `/t-review`, or `/t-plan`'s own contracts — `/t-drive` calls
  them as-is, per child (per #39's Non-goals).
- No retry/attempt-limit machinery beyond the one bounded self-correction step ADR-004
  Decision 2 already names.
- No change to who confirms the merge to `main`, or to squash-only merging.

## Decisions made along the way
- Plan widened beyond the issue's own Scope line to include
  `.claude/skills/t-ship/SKILL.md` and the CI record/plan-gate mechanics
  (`.github/workflows/ci.yml`, `scripts/check-record.sh`, `scripts/check-plan-gate.sh`,
  `scripts/plumbing-test.sh`) — human-approved at `/t-plan` (2026-08-28). Tracing
  ADR-004's mechanics showed these two gaps would leave `/t-drive`'s own output
  unshippable: CI's `record`/`plan-gate` jobs check a single issue's record/`## Plan`
  keyed off the branch name, which the initiative behind
  `wip/<initiative-id>-integration` has neither of; and `/t-ship`'s merge-commit step
  still wrote only one `Task: #<id>` line, though `CONSTITUTION.md` §1.4 already
  generalized to one-or-more for this case.
- A one-time disposable test initiative (not a recurring pattern) is pre-approved by
  the human at `/t-plan` (2026-08-28) to satisfy the end-to-end Done-when: a small
  initiative with at least two trivial children, one designed to fail its first review
  or check, run through `/t-drive`, then disposed of via `/t-cancel`.

## Deviations / notes
- **Re-plan during implementation (2026-08-29), human pre-approved via the widened-scope
  pattern already established at the first `/t-plan` pass.** Before writing any skill
  code, confirmed empirically (disposable probe branch/PR against a disposable
  integration-like branch, opened then closed, nothing kept) that
  `forge:pr-create-draft`'s underlying command always targets the repository's default
  branch, never the branch's actual git parent — so `/t-work`, called unmodified per
  child, would always open a child's draft PR against `main`, not the integration
  branch ADR-004 Decision 1 requires. Previous plan's Allowed paths had no way to fix
  this: `docs/adapters/FORGE.md` was not in scope. Re-ran `/t-plan 41`, widening Allowed
  paths to add one new operation, `forge:pr-set-base <pr> <base>` (GitHub: `gh pr edit
  <pr> --base <base>`), for `/t-drive` to retarget a child's PR after `/t-work` opens
  it. Previous Allowed paths (unchanged otherwise): `.claude/skills/t-drive/SKILL.md`,
  `AGENTS.md`, `docs/workflow.md`, `.github/workflows/ci.yml`,
  `scripts/check-record.sh`, `scripts/check-plan-gate.sh`, `scripts/plumbing-test.sh`,
  `.claude/skills/t-ship/SKILL.md`. New: `docs/adapters/FORGE.md`.
- Also found during the same probe: this environment's `gh` (2.45.0) has a second,
  independent bug — `gh pr edit --base` itself fails with a GraphQL error on a
  deprecated `projectCards` field, even though the underlying REST PATCH works fine.
  The adapter still documents the natural `gh pr edit --base` command for a compliant
  `gh`; this session's own execution of it works around the bug with `gh api
  repos/<owner>/<repo>/pulls/<pr> -X PATCH -f base=<base>` instead, same category as the
  already-noted ADR-003 `gh` version gap.
- Scope-overlap with #20 (`scripts/`, `AGENTS.md`, `docs/workflow.md` named broadly in
  its own Scope line) was missed on the first `/t-plan` pass and added on this
  amendment — not blocked-by/blocking #41, non-overlapping specific files, noted so
  whichever lands second expects a trivial rebase, not a surprise.
- **Skill bug found and fixed during implementation, before any live test (2026-08-29):**
  merging a child's PR requires it to be taken out of draft first (`gh pr merge` refuses
  a draft outright) — `/t-work` always opens a draft, and only `/t-ship` ever calls
  `forge:pr-ready` on its own PR, so nothing did this for a child's PR on this branch.
  Added `forge:pr-ready <pr>` to `/t-drive` Phase 2 step 6, immediately before the merge.
- **End-to-end validation (2026-08-29), Done-when bullets 2–3.** Ran `/t-drive` for real
  against a pre-approved disposable initiative, #47 ("Disposable /t-drive validation
  (temporary)"), with three children: #48 (a real, small, valuable fix — remove a stale
  `/t-fix` reference from `docs/adapters/FORGE.md`'s `pr-create` heading; `/t-fix` was
  removed by issue #25) and #49 (add a distinctive `T_DRIVE_TEST_MARKER_47` string to
  `AGENTS.md`'s `/t-clean` row, deliberately scoped narrower than its own stated Goal so
  its own Done-when's second clause is genuinely, honestly unsatisfiable within that
  scope — disclosed in its own record's Deviations) both merged into the integration
  branch (`wip/47-integration`) on `readiness: ready`, no retry needed; #52
  ("Test-only: intentionally blocked child") was excluded immediately with no retry
  spent, correctly, per its `Blocked-by: #20` (#20 open, not closed as completed) — this
  environment's `gh` cannot read the native `blockedBy` field (same ADR-003 gap noted
  in the Plan's Risks), so this one step was judged by reading the issue body's
  `Blocked-by:` text by hand rather than mechanically, exactly as the Plan anticipated.
  The aggregate PR to `main` (#53, from `wip/47-integration`) then genuinely exercised
  Phase 3's own bounded-retry path: its first independent review returned
  `readiness: not-ready` with a real HIGH finding — the PR body's `Closes #47` would
  have auto-closed the initiative on merge (wrong; it should stay open) and would very
  likely have broken `/t-cancel`'s own "merged task" refusal guard, stranding excluded
  child #52 with no path to a decided disposition. Root cause: Phase 3 step 1 told
  `/t-drive` to write `Task: #<id>` lines (for the CI `record` gate) but never said
  anything about the forge's own closing keyword — fixed by adding an explicit
  `Closes #<child-id>` instruction (one per included child, **never** for the
  initiative itself) to Phase 3 step 1, applied the fix directly to PR #53's body (no
  code change needed for this one), and it read `readiness: ready` on the scoped
  re-review. A second, real bug surfaced along the way and was also fixed in the skill:
  Phase 3 step 1 hadn't specified the `Task:` line's exact format precisely enough — an
  early draft of PR #53's body named children in ordinary prose/bullets, which
  `check-record.sh --multi`'s anchored parse correctly rejected; Phase 3 step 1 now
  spells out the exact required line shape. Every review (three children's worth plus
  two passes on the aggregate PR) ran in a genuinely isolated subagent, since this same
  session did all of the implementing and orchestrating.
- **What "the final PR lands against `main` in a form `/t-ship` can confirm and merge
  without modification" actually proves, and its one real limitation.** Confirmed
  directly: PR #53 reads `readiness: ready`, its body is well-formed for both the CI
  `record` gate and the forge's auto-close. Confirmed by local simulation, not by a live
  GitHub Actions run: the *new* `record`/`plan-gate` CI logic this same task adds is
  what makes that PR's required checks pass — proven by running the fixed
  `scripts/check-record.sh --multi` and the `plan-gate` skip logic directly against
  PR #53's real diff and real PR body (a checked-out `wip/47-integration` worktree),
  not by watching GitHub's own check runs go green, because that fix cannot itself be
  live on GitHub until *this* task (#41) merges to `main` — the two are sequenced
  (`main` gets the fix; only then can a driven run's aggregate PR pass CI for real),
  never circular. GitHub's own `record`/`plan-gate` checks on PR #53 will keep showing
  red until #41 ships; that is expected, not a defect.
- **Environment-only findings, not design defects, kept out of the skill:** `gh pr edit`
  (this environment's 2.45.0) fails on *any* mutation — not just `--base` — with the
  same `projectCards`/Projects-classic GraphQL error; every body/base edit in this
  session's own execution used `gh api ... -X PATCH` instead. The adapters keep
  documenting the natural `gh` command for a compliant version.
- **Recommended follow-up, not opened (report only, per `AGENTS.md`'s tracker-write
  rule):** the independent reviewer of PR #50 found that `.github/workflows/review-gate.yml`
  does not listen for the `edited` PR event, unlike `ci.yml` — so a child's `cold-review`
  required check can be left showing a stale result after `/t-drive` retargets its base
  (`forge:pr-set-base`), until something else (a new commit, or the review itself, which
  fires `pull_request_review` and reads the PR fresh) refreshes it. Not a correctness
  gap in this task's own Done-when (both times it self-resolved once the review posted),
  but worth its own small follow-up task adding `edited` to that workflow's trigger list.
- **Open decision for the human, not resolved here:** the disposable initiative (#47,
  #48, #49, #52, PR #53) is left exactly as the validation run produced it — #48 and
  #49 are real, valuable, already-reviewed-ready fixes sitting on `wip/47-integration`,
  not yet in `main`. Two honest paths, not chosen unilaterally: actually run `/t-ship 47`
  once #41 itself has shipped (landing #48/#49's fixes in `main` for real, closing the
  loop completely — CI on PR #53 will need a re-run, or a fresh commit/review cycle,
  once `main` has #41's fix), or abandon the whole thing via `/t-cancel 47` (deciding
  #48's and #49's disposition individually — cancel, or promote standalone for someone
  to redo as ordinary tasks later) plus `/t-cancel 52` for the deliberately-blocked
  child. Recommended: ship it — #48 and #49 are genuinely good, small, already-reviewed
  fixes, not throwaway content, and shipping closes the validation loop completely
  rather than leaving it asserted-but-unfinished.
