# 101 — Let /t-review and /t-ship reuse a green CI build check at the PR's head sha
Issue: #101 · Part of: #93

## Asked
A protected task's build/test command can run up to three times per commit: once
locally in `/t-work`, once locally again in `/t-review`, once more in CI. `/t-review`
already has a sha-pinned reuse rule for a check it can prove `/t-work` already ran on
this exact commit (the `## Checks run` PR-body note). Extend that same reuse principle
one step further: when a check tagged `either`/`implementation` in the plan (or `build`
from `AGENTS.md` with no plan) has a same-named CI job that completed successfully at
the PR's current head sha, `/t-review` (and `/t-ship`'s equivalent precondition, if any)
may treat that as satisfying the check without running it again locally — on the same
strict, no-staleness terms as the existing PR-body rule.

## Done when
- `/t-review`'s §6 reuse rule (and `/t-ship`'s equivalent precondition, if any) accepts
  "CI reports this check's job green at `.pr.headRefOid`" as an alternative to the
  `## Checks run` PR-body match, with the same strictness — any mismatch (different
  sha, job not found, job not successful) falls back to running the check locally.
- The skill text states plainly which source (PR-body provenance vs. live CI status)
  satisfied a given check, so a cold-context reviewer can tell which happened.
- No check's rigor is reduced: a check that would have failed locally still fails when
  read from a red or missing CI job.

## Explicitly not
- Does not change `/t-work`'s own local-check requirements before it pushes.
- Does not introduce any new CI job or change what `build` in `ci.yml` runs.

## Decisions made along the way
- Scoped the CI-reuse path in `/t-review` §6 to the same checks the existing PR-body
  path already covers (`either`-tagged, or the `AGENTS.md` §Checks set with no plan) —
  not also `implementation`-tagged ones, since step 6 never runs or reuses an
  `implementation`-only check in the first place; there is nothing there for CI to
  substitute for (hani@seaspraylabs.com, 2026-08-30).
- Left `.claude/skills/t-ship/SKILL.md` untouched. Inspected it fully: precondition 3
  already just reads `forge:pr-checks <pr>` as a merge go/no-go; `/t-ship` has no
  local-check-running step of its own to extend with a reuse rule, matching the issue's
  own "(and `/t-ship`'s equivalent precondition, if any)" hedge (hani@seaspraylabs.com,
  2026-08-30).
- The CI-job-name match (a check's identifying name to a CI job's `name` field) has no
  formal schema field — `gh pr checks`/`gh pr view --json statusCheckRollup` carry no
  per-check commit sha either, confirmed against this repo's own PR data. Both are
  handled in prose in the new §6 paragraph rather than by extending `/t-plan`'s
  `agent_checks` schema, which is outside this issue's scope
  (hani@seaspraylabs.com, 2026-08-30).

## Deviations / notes
- none
