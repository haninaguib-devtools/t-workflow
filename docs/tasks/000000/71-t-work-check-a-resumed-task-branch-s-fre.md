# 71 — t-work: check a resumed task branch's freshness against origin/main
Issue: #71

## Asked
`/t-work` step 4 only guards against a stale base when *creating* a branch. Resuming an
existing `wip/<id>-*` branch gets no freshness check at all — drift against
`origin/main` only surfaces at `/t-ship`'s merges-cleanly gate, the most expensive
moment to discover it. Add the symmetric guard for the resume path: after checking out
the existing branch, fetch; if it's behind `origin/main`, rebase onto `origin/main` when
the rebase applies cleanly (note it in the report); stop and report on a conflict —
never auto-resolve — mirroring the existing ff-only/stop-if-diverged split for `main`.

## Done when
- `t-work/SKILL.md` step 4's existing-branch arm states the fetch, the behind check,
  the clean-rebase-and-note path, and the conflict stop-and-report path.
- The conflict stop explicitly forbids auto-resolving and names what the human should
  do (supervise the rebase, then re-invoke `/t-work`).
- `.t-workflow/scripts/consistency-check.sh` passes.

## Explicitly not
- Touching any other skill or doc — the plan found no cross-reference to this rule
  elsewhere; scope is `.claude/skills/t-work/SKILL.md` only.

## Decisions made along the way
- none

## Deviations / notes
- none
