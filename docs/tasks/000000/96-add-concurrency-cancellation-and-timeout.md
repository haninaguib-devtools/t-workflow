# 96 — Add concurrency cancellation and timeouts to ci.yml and review-gate.yml
Issue: #96 · Part of: #93

## Asked
Neither `.github/workflows/ci.yml` nor `.github/workflows/review-gate.yml` declares a
`concurrency:` group or any `timeout-minutes:`. A superseded run (a new push while an
old one is still building, or `/t-drive`'s base-retarget landing right after PR
creation) keeps running to completion instead of being cancelled, burning full minutes
for a result nobody will read; and a hung job has no ceiling short of GitHub's 6-hour
platform default. Add a `concurrency:` block to each workflow, grouped by workflow name
plus the PR (or the ref on the `push: main` trigger) with `cancel-in-progress: true`,
and a reasonable `timeout-minutes:` on every job.

## Done when
- Both workflow files declare `concurrency:` with `cancel-in-progress: true`, scoped so
  that two runs on the same PR head (or the same push to `main`) never run concurrently,
  while two different PRs' runs are unaffected by each other.
- Every job in both files has an explicit `timeout-minutes:`.
- Pushing two commits to the same branch in quick succession is observed to cancel the
  first run's in-progress jobs (verify via `gh run list` / `gh run view` showing a
  `cancelled` conclusion on the superseded run).

## Explicitly not
- Does not touch `release.yml` (already has its own `concurrency:` group) or
  `pages.yml`/`sonar.yml`/`stale-branches.yml`.
- Does not resolve the scope overlap with sibling tasks #94, #95, #97, #98, which also
  edit `ci.yml`/`review-gate.yml` — flagged in the plan; sequencing is a human call, not
  this task's.

## Decisions made along the way
- Concurrency group key: `${{ github.workflow }}-${{ github.event.pull_request.number
  || github.ref }}`, not `github.head_ref` — `head_ref` is unset on
  `review-gate.yml`'s `pull_request_review` trigger, while
  `github.event.pull_request.number` is populated on both `pull_request` and
  `pull_request_review` (both carry a `.pull_request` payload), falling back to `.ref`
  on `push: main`. Per the plan (issue #96).
- `timeout-minutes: 15` uniformly on every job in both files — all current jobs are
  short shell-script/`gh api` checks (issue #93 measures the `ci.yml` gate jobs at 3-8
  seconds of real work each); no `build` job exists yet. Per the plan (issue #96).

## Deviations / notes
- Live cancellation check (done-when #3) verified on PR #104 by pushing two commits in
  quick succession after the draft PR opened and checking `gh run list` for a
  `cancelled` conclusion on the superseded run.
