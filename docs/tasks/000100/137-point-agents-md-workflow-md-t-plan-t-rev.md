# 137 — Point AGENTS.md/workflow.md/t-plan/t-review at CONSTITUTION.md §3 generically instead of hardcoding protected surfaces
Issue: #137

## Asked
Four template-owned files each hardcode a fixed list of where binding content lives or
gets checked (`AGENTS.md`'s promotion-destination sentence, `docs/workflow.md` §2's
"What lives where" list, `t-plan`'s step 2, `t-review`'s step 5), instead of pointing at
`CONSTITUTION.md` §3 generically the way `t-work`/`t-status`/`t-ship`/`t-drive` already
do for the protected-path list itself. A consumer adding its own protected surface to
§3 has to hand-edit all four files outside any `<!-- local -->` slot, which
`check-manifest.sh` then flags as drift. Apply the template's existing "run the script /
cite §3 generically" idiom to these four files instead of adding four new slots, and
document the idiom in `docs/architecture/local-slots.md` so a future template author
reaches for it instead of inventing another slot.

## Done when
- `AGENTS.md`'s promotion-destination sentence reads generically instead of a fixed,
  closed list.
- `docs/workflow.md` §2's "What lives where" list ends with a generic reference to
  `CONSTITUTION.md` §3's protected surfaces.
- `.claude/skills/t-plan/SKILL.md` step 2 tells the planner to also check any protected
  surface §3 names relevant to the issue's Goal, pointing at `protected-paths.sh --list`.
- `.claude/skills/t-review/SKILL.md` step 5's "document deliverable" category is
  generalized the same way; step 2's already-generic "read any design doc the issue
  names" is left untouched.
- A consumer adding a new protected surface to §3 / `protected-paths.sh` needs no other
  edit to these four files.
- `./.t-workflow/scripts/consistency-check.sh` passes; no new `<!-- local -->` slots
  introduced.
- `docs/architecture/local-slots.md` gets one short paragraph naming this "generic
  pointer to an existing slot" idiom as the preferred alternative to a new slot.

## Explicitly not
- `CONSTITUTION.md` §3 and `protected-paths.sh` — already correctly slotted, untouched.
- No new `<!-- local -->` slot anywhere.
- Not fixing any consumer's own already-drifted copies of these files — picked up via
  that consumer's own `/t-update`.

## Decisions made along the way
- none

## Deviations / notes
- none
