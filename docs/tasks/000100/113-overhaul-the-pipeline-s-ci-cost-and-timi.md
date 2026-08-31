# 113 — Overhaul the pipeline's CI cost and timing in one pass
Issue: #113

## Asked
The generated pipeline costs far more GitHub Actions time than the work it verifies
(measured on a consumer repo: ~20 billed minutes per ordinary task, most of it six or
seven 3-8-second gate jobs each occupying its own runner and billed a rounded-up
minute), and several trigger/timing defects make it slower and misleading. Splitting the
fix across eight sibling tasks failed in practice — the first to ship (#94's job
consolidation) renamed the required status contexts underneath its open siblings' PRs
and had to be reverted (#111) — because these changes are one tightly-coupled surface:
job names, the trigger set, the required-checks list branch protection enforces, and the
skills that read CI state all have to move together. So they move together, as one
coherent change:

1. Consolidate each CI event's job set into one job (re-landing #94's reverted change),
   every gate script keeping its own step.
2. Drop the `pull_request: edited` trigger and its now-dead guards.
3. Add `concurrency:` (cancel-in-progress) and `timeout-minutes:` on every job in
   `ci.yml` and `review-gate.yml`.
4. Stop `cold-review` being red by construction: `review-gate.yml`'s `pull_request:`
   types become `synchronize` only.
5. Skip CI on draft PRs; start it at `ready_for_review`.
6. Reorder `/t-ship` for the new CI timing: mark ready before reading CI, then do an
   attended, interruptible watch — record the attended/unattended distinction against
   ADR-007 (a short new ADR); update `/t-drive` Solo step 6 for the new timing.
7. `/t-drive` creates each child PR against the integration branch directly, instead of
   opening against `main` and retargeting.
8. Let `/t-review` and `/t-ship` reuse a green CI check at the exact head sha.
9. Ship with the branch-protection flip built in, no unenforced window: update
   `github-bootstrap.sh`'s required-contexts list to the new names, flip live branch
   protection by direct API call at ship time once the new contexts already have a run
   (this PR's own), then re-run the bootstrap script as idempotent true-up.

Supersedes #93 (cancelled) and its cancelled children #95–#99, #101, #102; re-lands #94
(shipped, reverted by #111) with the sequencing failure addressed by item 9.

## Done when
- A sample PR event's total billed job-minutes (sum of per-job `ceil(duration/60)` from
  `gh run view --json jobs`) drops to roughly the build/checks work itself; the gate
  scripts bill ~1 minute total, not ~7.
- A PR-body-only edit fires no CI run; a push still does; two quick pushes to one
  branch leave only the newer run alive (older shows `cancelled`).
- A freshly-opened protected draft PR shows no failing required check; pushes while
  draft cost zero CI runs; marking ready starts CI.
- `/t-ship` on a protected task: the human's merge-gate evidence never reports CI green
  when nothing ran; the merge is never attempted with required checks unconcluded; an
  interrupted watch leaves a re-enterable state.
- A driven child lands with exactly one CI run and one review-gate run on the happy
  path, and its `cold-review` ran against the integration base.
- `/t-review` on a PR whose named check is green in CI at the exact head sha skips the
  local re-run and says so; any mismatch runs it locally.
- After ship: `gh api repos/<owner>/<repo>/branches/main/protection/required_status_checks`
  returns exactly the script's list; the bootstrap script re-run reports no change.
- No gate is weakened: every previously-enforced verification still runs and still
  blocks what it blocked, relocated or repackaged only.

## Explicitly not
- No check is removed. Anything here that repackages a check preserves its semantics.
- The pluggable CHECKS backend (running checks off hosted Actions entirely) is out — a
  boundary, not deferred work.
- Consumer-repo workflows are untouched; consumers pick this task up via `/t-update`.

## Decisions made along the way
- Only `ci.yml`'s `checks` job gets the `ready_for_review` trigger for item 5;
  `review-gate.yml` does not add it, since by the time `/t-ship` marks a PR ready, a
  review must already exist (`/t-ship` precondition 2), and that review's
  `pull_request_review: submitted` event already produced a `cold-review` run at the
  current head sha, unconditionally, regardless of draft state — adding
  `ready_for_review` there would only re-run the same check on the same commit for no
  new information, working against this task's own cost goal (agent, 2026-08-31).
- Item 6's ADR is a new file, ADR-008, rather than an in-place edit of ADR-007 (ADRs are
  append-only, `CONSTITUTION.md` §2.1) — it amends ADR-007's specific mechanism (the
  pre-`/t-ship` one-look CI check in `/t-drive` Solo mode) the same way ADR-007 itself
  amended ADR-006 without editing that file (agent, 2026-08-31).
- `/t-ship`'s CI-green precondition became Procedure step 2 (an attended watch, no fixed
  timeout — bounded by the human's presence and, structurally, by `ci.yml`/
  `review-gate.yml`'s own `timeout-minutes: 10`) rather than staying a precondition,
  since it structurally cannot be evaluated before step 1 marks the PR ready under the
  new CI timing (agent, 2026-08-31).
- `timeout-minutes: 10` chosen for both `checks` and `cold-review`: generous relative to
  the ~1-minute real work these jobs do post-consolidation, while still well short of
  GitHub's 6-hour default (agent, 2026-08-31).
- `forge:pr-set-base` is kept documented in `FORGE.md`, not deleted, even though `/t-drive`
  no longer calls it after item 7 — no other skill is known to need it, but removing a
  documented operation speculatively is a different kind of change than correcting one
  that was already wrong (agent, 2026-08-31).
- Item 9's branch-protection flip became a new, conditional `/t-ship` Procedure step
  (fires only when a shipped diff changes `github-bootstrap.sh`'s required-contexts
  list) rather than a one-off manual action for this task's own ship — this generalizes
  the #94/#109/#111 sequencing fix so any *future* task that renames a required check
  gets the same guardrail, not just this one (agent, 2026-08-31).
- **Self-correction before opening this task's own PR (2026-08-31): the flip must
  happen *before* the merge attempt, not after.** First draft of the new `/t-ship` step
  placed the flip after the squash-merge (mirroring the issue's own prose, which reads
  as "ship, then flip"). Caught by checking this task's own PR against it before
  pushing: a PR that renames required-status-check contexts cannot merge under the
  *old* protection in the first place — this PR's own CI never again produces the old
  six job names, so those required checks sit at "expected" forever and block the merge
  button, self-inflicting the exact #94/#109 failure on this PR. Moved the check to a
  new step between the CI-watch and the merge-confirmation gate: it confirms the new
  context names already have a real run (this PR's own head sha, not `main` — the merge
  hasn't happened yet) and folds into the *same* gate as evidence, executing only after
  the human's merge confirmation and before the actual `forge:pr-merge` call. Verified
  against this repo's live branch protection (`gh api
  .../branches/main/protection/required_status_checks`, read before pushing): it
  currently requires the old six names plus `cold-review`, confirming the old ordering
  would have blocked this exact PR (agent, 2026-08-31).
- `/t-review`'s CI-based check-reuse source (item 8) is scoped to checks with a real
  corresponding CI job — in this repo, only `consistency-check.sh`, since it is the one
  check both `AGENTS.md` §Checks names and `ci.yml`'s `checks` job actually runs; a
  future task-specific plan check with no CI counterpart is never a candidate for this
  source (agent, 2026-08-31).

## Deviations / notes
- **Re-plan during implementation (2026-08-31), before touching `docs/adapters/FORGE.md`.**
  Item 7 (`/t-drive` creating each child PR directly against the integration branch)
  needed to correct `FORGE.md`'s `forge:pr-create-draft` contract, which was not in the
  first plan's Allowed paths. Ran `/t-plan 113` again to widen it, after first confirming
  empirically (a disposable probe: two throwaway branches off `origin/main`, a draft PR
  opened with `gh pr create --draft --base <non-default-branch> --head <branch>`,
  `baseRefName` confirmed equal to the named branch, then closed and both branches
  deleted — mirroring task #41's own probe precedent, nothing kept) that item 7 can land
  as literally specified: `--base` works fine alongside `--draft`; task #41's original
  finding was narrower than `FORGE.md` currently states — it was about *omitting*
  `--base` (which does default to the repo's default branch, not the branch's git
  parent), never about `--base` being unsupported when passed explicitly.
  Previous plan's Allowed paths (unchanged otherwise): `.github/workflows/ci.yml`,
  `.github/workflows/review-gate.yml`, `.t-workflow/scripts/github-bootstrap.sh`,
  `.claude/skills/t-ship/SKILL.md`, `.claude/skills/t-drive/SKILL.md`,
  `.claude/skills/t-review/SKILL.md`, one new file in `docs/adr/`,
  `.claude/skills/t-work/SKILL.md` (conditional), `docs/adr/007-...md` (conditional,
  never edited in place), `docs/architecture/` (conditional). New: `docs/adapters/FORGE.md`.
