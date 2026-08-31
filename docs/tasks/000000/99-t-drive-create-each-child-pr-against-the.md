# 99 — /t-drive: create each child PR against the integration branch directly, not against main then retargeted
Issue: #99 · Part of: #93

## Asked
`/t-drive`'s Phase 2 step 4 creates each child task's PR via the ordinary `/t-work` flow
— which opens the draft PR against `main` — and then retargets it onto the initiative's
`wip/<id>-integration` branch with `forge:pr-set-base`. That retarget fires a
`pull_request: edited` event, which `review-gate.yml` does not listen for. The
consequence is two-fold: (1) the child's `cold-review` verdict, if computed before the
retarget, was computed against a diff against `main` — including every sibling child
already merged into the integration branch — never against the integration branch it
actually merges into; (2) the retarget itself burns one extra full CI run per child.
Fix `/t-drive` to create each child's PR with the integration branch as its base from
the start, eliminating the retarget step entirely.

## Done when
- `/t-drive`'s Phase 2 child-PR creation targets the integration branch as its base at
  creation time; no `forge:pr-set-base` call remains in the child-PR happy path.
- A child's `cold-review` check, when it runs, is computed against a diff against the
  integration branch rather than against `main` from a stale pre-retarget open.
- Driving an initiative with N children fires exactly one CI run and one review-gate run
  per child on the happy path (down from two each today) — verify by counting
  `gh run list` events for a real or simulated drive.
- `docs/architecture/` or `docs/adr/004-*` (wherever the driven-initiative child-PR flow
  is specified) is checked for any statement of the create-against-main-then-retarget
  sequence and updated to match the new create-with-base-set behavior.

## Explicitly not
- Does not change how the *initiative's own* aggregate PR (integration branch → `main`)
  is created — that already targets `main` correctly.
- Does not change the bounded-retry or exclusion behavior for a child that fails review.

## Decisions made along the way
- Plan (`/t-plan 99`, 2026-08-30) extended Allowed paths to include
  `.claude/skills/t-work/SKILL.md`, beyond the issue's original Scope line
  (`.claude/skills/t-drive/SKILL.md`, `docs/adapters/FORGE.md`): `/t-work`, not
  `/t-drive`, is the thing that actually calls `forge:pr-create-draft`, and GitHub only
  lets the base be set at creation time, not reliably after — so the fix has to add an
  optional base parameter there, additive-only for every other caller.
- `docs/adr/004-autonomous-initiative-driving.md` was checked (plan step) and already
  states the target end-state generically without describing create-then-retarget
  mechanics; it needs no edit.

## Deviations / notes
- none
