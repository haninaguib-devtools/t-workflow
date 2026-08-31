# 102 — Design a pluggable CHECKS backend so consumers can run checks off hosted Actions runners
Issue: #102 · Part of: #93

## Asked
Even after the other cost/latency tasks in this initiative land, every check still runs
on a hosted GitHub Actions runner, billed against the repo's Actions minutes. Design a
pluggable CHECKS backend — mirroring the existing `docs/adapters/TRACKER.md` and
`docs/adapters/FORGE.md` — that lets a consumer choose between the current
`github-actions` backend (unchanged default) and a `local-runner`/`self-hosted`
backend: a process that watches PR events, runs the same check scripts in a clean,
isolated checkout (never the authoring agent's own working tree), and posts one commit
status per required context via the GitHub statuses API.

## Done when
- `docs/adapters/CHECKS.md` exists, documenting the `checks:*` operation contract with a
  `github-actions` backend entry that reproduces current behavior exactly, sufficient
  for `.github/workflows/ci.yml`/`review-gate.yml` and `github-bootstrap.sh`'s
  required-checks setup to be re-described in its terms without behavior change.
- A new ADR in `docs/adr/` records the decision to make checks pluggable, the
  `local-runner` design outline (even if not yet implemented), the isolation
  requirement, and the rejected alternatives (e.g. self-hosted `runs-on:` runners).
- Follow-up implementation issues for whatever the design determines is separable are
  proposed in this PR's description, not opened directly.
- `CONSTITUTION.md` §3's protected-surface list and `docs/adapters/` stay consistent
  with the new file (`.t-workflow/scripts/consistency-check.sh`).

## Explicitly not
- Does not implement the `local-runner` backend itself — separable follow-up work this
  design proposes, not builds.
- Does not migrate this repo or any consumer off `github-actions` as the active backend.

## Decisions made along the way
- none

## Deviations / notes
- none
