# 68 — Skills should call the existing check-*-gate.sh scripts instead of re-deriving the same logic in prose
Issue: #68

## Asked
`.t-workflow/scripts/check-blocker-gate.sh`, `check-plan-gate.sh`, `check-review-gate.sh`,
and `check-title-gate.sh` already implement — and CI already trusts — exactly the
decisions several skills currently make by hand-reasoning over raw JSON: `t-work`'s
blocker check, `t-ship`'s review-currency check, and `t-drive`'s eligibility check each
spend a paragraph telling the LLM how to reach a conclusion a deterministic script
already computes, never invoking it. That costs reasoning tokens and latency on every
invocation, and it duplicates logic that can drift from the script's own behavior.

## Done when
- `t-work` Phase 1's blocker check invokes `check-blocker-gate.sh` against the fetched
  blocker JSON and reads its exit code, rather than describing the closed/cancelled
  distinction in prose for the LLM to apply itself.
- `t-ship` precondition 2's review-currency check invokes `check-review-gate.sh` the same
  way.
- `t-drive` Phase 2 step 1's eligibility check reuses `check-blocker-gate.sh` for the
  blocker-satisfied sub-decision instead of restating it.
- Each skill's prose is reduced to "run the script, read the exit code, act on it" for
  the covered decision — the surrounding judgment (what to do on failure: stop, exclude,
  retry) stays prose, since that part is not what the script decides.
- No behavior change: same refusals, same conditions, just one implementation of each
  instead of two.

## Explicitly not
Writing any new gate script, or changing what the existing ones check — this is purely
about the skills consuming scripts that already exist and are already CI-authoritative,
not about the gate logic itself.

## Decisions made along the way
- The plan (`/t-plan 68`) found that `check-blocker-gate.sh` needs `stateReason` per
  blocker, but `tracker:list-blockers`'s documented GitHub command (`gh issue view <id>
  --json blockedBy`) never returns it — confirmed empirically against this live repo.
  Human chose to fix `docs/adapters/TRACKER.md`'s `tracker:list-blockers` command to the
  `gh api graphql` query `.github/workflows/ci.yml`'s `blockers` job already uses (over
  inlining the raw call into the skills), keeping skills backend-agnostic and matching
  ADR-003's own stated design ("the native `blockedBy` field plus the blocker's
  `stateReason`") (haninaguib, at `/t-plan` time).

## Deviations / notes
- **Branch was stale at `/t-work` start.** `wip/68-*` had no commits of its own and was
  two commits behind `origin/main` (missing #66 and #65's merge, PR #69) — #65 touched
  the same three skill files and `docs/adapters/TRACKER.md` this task also touches, per
  the plan's own noted overlap. Fast-forwarded (`git merge --ff-only origin/main`) before
  any edit, safe because the branch carried no unique commits yet.
- none beyond the above
