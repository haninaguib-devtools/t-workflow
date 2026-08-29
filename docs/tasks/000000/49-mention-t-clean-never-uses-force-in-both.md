# 49 — Add a distinctive T_DRIVE_TEST_MARKER note to both /t-clean's row and its own skill file
Issue: #49 · Part of: #47

## Asked
`AGENTS.md`'s `/t-clean` pipeline-table row and `.claude/skills/t-clean/SKILL.md`'s own
frontmatter `description` should both carry the exact marker text
`T_DRIVE_TEST_MARKER_47` (a disposable validation marker, #47 — never a real content
change), so both documents can be checked for it independently.

## Done when
`grep -c 'T_DRIVE_TEST_MARKER_47' AGENTS.md` returns at least 1 on the `/t-clean` row,
and `grep -c 'T_DRIVE_TEST_MARKER_47' .claude/skills/t-clean/SKILL.md` returns at least 1
on that file's own frontmatter `description` line too — both, not just one.

## Explicitly not
- `.claude/skills/t-clean/SKILL.md` is not touched — outside this issue's own declared
  Scope (`AGENTS.md` only). See Deviations: this leaves Done-when's second clause
  unmet, by design (this is #47's deliberately-failing validation child).

## Decisions made along the way
- none

## Deviations / notes
- **Scope narrower than the Goal, by design (2026-08-29).** The issue's own Scope names
  only `AGENTS.md`; the Goal as written needs `.claude/skills/t-clean/SKILL.md` too. Per
  the `/t-plan` on this issue, Allowed paths stay exactly at the declared Scope — this
  child is #47's disposable, pre-approved deliberately-failing validation case (per
  issue #41's Done-when), so the honest, in-scope implementation below satisfies only
  the first half of Done-when.
