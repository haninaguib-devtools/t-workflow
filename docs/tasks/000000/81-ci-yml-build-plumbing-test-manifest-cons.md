# 81 — ci.yml: build/plumbing-test/manifest/consistency rerun needlessly on PR 'edited' events
Issue: #81

## Asked
`.github/workflows/ci.yml` triggers on `pull_request: types: [opened, synchronize,
reopened, edited]`. `edited` is there so `title-gate` (title changed) and
`plan-gate`/`blockers` (a human wants a fresh read of issue state without a new commit)
get a re-run without a new push. But that trigger applies at the workflow level, so
every job re-runs on an `edited` event — including jobs that depend on nothing an
`edited` event (a PR title/body change) can affect. A PR title fix alone currently
reruns work that gained nothing from the edit. Guard the jobs that don't need to react
to `edited` so they only run on `opened`/`synchronize`/`reopened` (and on the `push:
main` trigger, unaffected), while `record`, `plan-gate`, `title-gate`, and `blockers`
keep reacting to `edited` exactly as today.

## Done when
- `consistency` and `plumbing-test` — the jobs the issue names that actually exist in
  this repo's `ci.yml` today — carry a guard (`if: github.event.action != 'edited'`)
  so they do not run on a `pull_request: edited` event, but still run on
  `opened`/`synchronize`/`reopened` and on `push: main`.
- `record`, `plan-gate`, `title-gate`, `blockers` are unchanged — they keep reacting to
  `edited`.
- Checks 2 and 3 pass.

## Explicitly not
- The issue also names `build` and `manifest` jobs. Neither exists in this repo's
  `ci.yml`: there is no `build` job yet (AGENTS.md §Checks — no stack exists), and no CI
  job named `manifest` exists at all (`check-manifest.sh` runs inside `/t-work` and
  `/t-update`, not as its own CI job). Guarding either is out of scope here; the
  `/t-plan` on #81 already flagged this — when a `build` job is eventually added it
  should get the same guard, as its own change at that time — split to whichever issue
  adds that job.
- The `edited` trigger type itself, and the reasoning for keeping it (title-gate,
  plan-gate, blockers reacting without a new push), are unchanged.
- Branch-protection required-status-check names (`consistency`, `plumbing-test`) are
  unchanged — this task only adds an `if:` guard, the job names stay identical, so
  `.t-workflow/scripts/github-bootstrap.sh` needs no update.

## Decisions made along the way
- Scoped to the two jobs that actually exist among the four the issue names,
  per the plan on #81 (agent, 2026-08-29).

## Deviations / notes
- none
