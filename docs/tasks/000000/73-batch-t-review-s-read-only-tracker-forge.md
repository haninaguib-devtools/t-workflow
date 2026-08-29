# 73 — Batch t-review's read-only tracker/forge fetch into one script call
Issue: #73

## Asked
`/t-review` gathers its inputs (the issue, the PR diff, local git state, the PR's
head commit, and the PR's changed files for the protected-path check) as a sequence
of separate tracker/forge calls with no judgment attached between them — the same
pattern that made `/t-status`, `/t-drive`, and `/t-ship` slow before #69 fixed it for
those three skills. #69's commit message explicitly deferred `t-review` (and
`t-work`) to a future task. This task does that for `t-review`: add a script that
folds t-review's read-only fetch (steps 2-3 of `.claude/skills/t-review/SKILL.md`)
into one invocation — the issue body/labels/parent, the PR diff, PR view (head sha,
files), and local git state (`git status`, `git rev-parse HEAD`) — and update
`SKILL.md` to call it once instead of making each fetch as a separate round trip.

## Done when
- A new script under `.t-workflow/scripts/` gathers the read-only inputs t-review's
  steps 2-3 currently fetch one call at a time, in a single invocation (or the
  minimum number of `gh` calls the data genuinely requires).
- `.claude/skills/t-review/SKILL.md` is updated to invoke that script instead of the
  separate fetches, without changing any judgment step (isolation decision,
  protected-surface decision, scope/record/constitution checks, verdict logic).
- `.t-workflow/scripts/plumbing-test.sh` (or its equivalent) covers the new script,
  following the same pattern added for `status-snapshot.sh` in #69.
- `./.t-workflow/scripts/consistency-check.sh` passes.

## Explicitly not
- `t-work`'s gate-check phase — also named in #69's non-goals, left for its own task.
- Collapsing any step that involves judgment or a refusal condition (isolation
  decision, protected-surface decision, scope/record/constitution checks, the
  readiness verdict itself) into the script — those stay in the skill.

## Decisions made along the way
- none

## Deviations / notes
- none
