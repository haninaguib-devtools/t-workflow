# 94 — Consolidate ci.yml's per-event job set into one job per trigger
Issue: #94 · Part of: #93

## Asked
`.github/workflows/ci.yml` runs seven separate jobs on every `pull_request` event
(`record`, `plan-gate`, `title-gate`, `blockers`, `manifest`, `consistency`,
`plumbing-test`) and four on every `push: main` (`consistency`, `manifest`,
`plumbing-test`, `build`). Each of the non-`build` jobs does 3-8 seconds of real work
(a shell script), but GitHub Actions bills every job on its own runner rounded up to a
full minute, so a PR run currently bills roughly 7 minutes for well under a minute of
actual work, on top of the real `build` job. Collapse each event's job set into a single
job with sequential steps — one for `pull_request` (the six gate scripts, `build`
unaffected since it already reports separately if desired) and, separately or combined,
one for `push: main` (`consistency`, `manifest`, `plumbing-test`, `build`) — so the
billed time approaches the actual work done, and so the branch-protection UI shows one
consolidated status instead of seven.

Preserve every individual check's own pass/fail semantics and its own log output (each
step's `run:` block stays intact and clearly demarcated); this is a packaging change to
how the *jobs* are grouped onto runners, not a change to what any single check verifies
or how strict it is.

## Done when
- `.github/workflows/ci.yml`'s `pull_request`-triggered checks run as one job (or the
  minimum number of jobs needed to preserve any real ordering/parallelism benefit),
  each existing check still runs as a distinct, individually-attributable step, and a
  failure in any one step still fails the job (and therefore the PR) exactly as today.
- The `push: main` checks are similarly consolidated.
- `.t-workflow/scripts/github-bootstrap.sh`'s required-status-check `contexts` list
  (currently `["consistency", "record", "plan-gate", "title-gate", "blockers",
  "cold-review", "plumbing-test"]`) is updated to name the new consolidated job name(s)
  in the same change — the header comment on `ci.yml` already says renaming a job means
  updating that script in the same change.
- A sample PR run's billed CI-minutes drop measurably (verify with `gh run view --json
  jobs` on a real PR, comparing total `ceil(duration/60)` across jobs before and after).
- No check's pass/fail behavior changes: a PR that would have failed `plan-gate` (etc.)
  before this change still fails after it, with the same reason surfaced.

## Explicitly not
- Does not change `review-gate.yml` or the `cold-review` check (separate task).
- Does not change what any individual gate script checks, only how its job is packaged.
- The issue's numbers name `manifest` and `build` jobs among the ones to consolidate;
  neither exists in this repo's `ci.yml` today (no stack yet — AGENTS.md §Checks; no
  `manifest` job, `check-manifest.sh` runs inside `/t-work`/`/t-update` only). Per the
  plan on #94, scope is the six jobs that actually exist:
  `consistency`, `record`, `plan-gate`, `title-gate`, `blockers`, `plumbing-test`.

## Decisions made along the way
- Scoped to the six jobs that actually exist in this repo's `ci.yml` (`consistency`,
  `record`, `plan-gate`, `title-gate`, `blockers`, `plumbing-test`), excluding `manifest`
  and `build` which the issue names but which don't exist here yet — per the plan on #94
  (agent, 2026-08-30).

## Deviations / notes
- `.github/workflows/installer.yml`'s header comment says "`.t-workflow/scripts/github-bootstrap.sh`
  ... names `consistency` and `record`" as the required-check context names — stale after
  this task's rename to `checks`. Out of this task's Allowed paths (`.github/workflows/ci.yml`,
  `.t-workflow/scripts/github-bootstrap.sh` only), so left as-is and reported here rather
  than fixed as a drive-by (AGENTS.md §Conventions): recommend a follow-up issue (or a
  ride-along on whichever of #95/#96/#98 next touches `ci.yml`) to update that comment.
