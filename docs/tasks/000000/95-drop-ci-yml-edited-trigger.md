# 95 — Drop ci.yml's pull_request 'edited' trigger
Issue: #95 · Part of: #93

## Asked
`.github/workflows/ci.yml`'s `pull_request` trigger includes `edited`, on the theory
that it lets an issue-body-only edit re-run `plan-gate` without a new commit. That
theory is wrong — GitHub's `pull_request: edited` event fires only on a change to the
PR's own title, body, or base branch, never on a change to the linked issue that
`plan-gate` actually reads. In practice the trigger's only effect is that `/t-work`'s
mandated rewrite of the PR's `## Checks run` section, and `/t-drive`'s per-child base
retarget, each fire a full CI run for a pure metadata change. Remove `edited` from the
trigger; a human or agent who needs a gate re-checked after a genuine title/body fix can
re-run the job manually (`gh run rerun`).

## Done when
- `.github/workflows/ci.yml`'s `pull_request:` trigger no longer lists `edited`.
- The `if: github.event.action != 'edited'` guards on `consistency` and `plumbing-test`
  (now dead code once `edited` can't occur) are removed in the same change, and the
  header comment explaining the `edited` trigger and those guards is removed or
  corrected to match.
- A PR-body-only edit (e.g. `gh pr edit <n> --body ...`) no longer triggers a CI run.
- A push of new commits still triggers CI exactly as before (`synchronize` is untouched).

## Explicitly not
- Does not change `review-gate.yml`'s trigger types (separate task — #97).
- Does not add any replacement mechanism for re-checking an issue-body edit against
  `plan-gate` — that check already re-runs on the next real `synchronize`, and a human
  can `gh run rerun` in the interim if needed.

## Decisions made along the way
- Also corrected the `blockers` job's comment ("Re-evaluated on every pull_request
  sync/reopen/edit") to drop the now-impossible "edit", since it was describing exactly
  the same removed trigger behavior the issue's Done-when 2 asks to fix — not a
  separate defect, just the same correction applied to the one other place it appears.

## Deviations / notes
- none
