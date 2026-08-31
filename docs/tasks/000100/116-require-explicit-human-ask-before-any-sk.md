# 116 — Require explicit human ask before any skill invocation, not just tracker writes
Issue: #116

## Asked
`AGENTS.md`'s tracker-writes rule ("Writing to the tracker needs the human's ask") only
governs writes an already-running skill makes. Nothing stops an agent from inferring, on
its own, that a plain description or bug report in conversation is a request to *run*
`/t-open` (or any other stage) in the first place — this happened in a consumer repo,
where an agent read a UI bug description as license to self-invoke `/t-open` and open a
tracker issue nobody asked for. Generalize the existing "noticing isn't being asked"
principle so it covers invoking any skill at all, not only tracker writes made once
already inside one — the same way `/t-drive`'s own `SKILL.md` already treats its single
explicit invocation as the ask for everything it chains internally.

## Done when
- `AGENTS.md` §Conventions has a bullet stating that no skill in the pipeline table —
  `/t-status` included — runs without the human explicitly naming it or clearly
  directing that specific action in their own words. A description, bug report, or
  observation in conversation is never by itself such an ask, even when it obviously
  describes something worth fixing or the action would be harmless.
- The bullet states the one exception: a skill `/t-drive` itself chains once invoked —
  that invocation is the ask for the whole chain, per `/t-drive`'s own "explicitly
  invoked" description.
- `./.t-workflow/scripts/consistency-check.sh` passes.

## Explicitly not
- No change to `docs/workflow.md` or to individual `SKILL.md` files — one bullet, one
  place, generalizing the existing tracker-writes rule it sits beside.
- No mechanical or hook-based enforcement of this rule. It stays a documented
  convention, the same as the tracker-writes rule it generalizes.

## Decisions made along the way
- **The new bullet sits immediately before the existing tracker-writes bullet, and
  leaves that bullet's own text untouched** (agent at `/t-work`, 2026-08-31, per the
  plan's Risks/constraints: the new bullet is the general rule, the tracker-writes
  bullet remains the standing special case for writes made by an already-running
  skill).

## Deviations / notes
- none
