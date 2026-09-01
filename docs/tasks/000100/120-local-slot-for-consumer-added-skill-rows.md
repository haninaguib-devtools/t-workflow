# 120 — Local slot for consumer-added skill rows in AGENTS.md's pipeline table
Issue: #120

## Asked
A consumer repo cannot currently add its own locklane-style local skill under
`.claude/skills/`: `consistency-check.sh` check 3 requires every directory under
`.claude/skills/` to have a matching pipeline-table row in `AGENTS.md`, but `AGENTS.md`
is template-owned and manifest-hash-locked, with only one `<!-- local -->` slot
(`§Checks` item 1) — nothing covers the pipeline table. Add a second local slot to
`AGENTS.md`, placed after the existing `t-*` pipeline table, for consumer-added skill
rows, and document it in `docs/architecture/local-slots.md` alongside the two slots
already named there.

## Done when
- `AGENTS.md` has a new `<!-- local -->` … `<!-- /local -->` slot after the pipeline
  table, holding a neutral placeholder (this repo is the template, not a consumer).
- `docs/architecture/local-slots.md` documents the new slot alongside the two it
  already names, and updates the "Everything else … is template content" framing.
- `.t-workflow/scripts/consistency-check.sh` check 3 still passes on this repo (no
  consumer rows yet); its first-loop extension (walking local-skill rows the same way
  as `/t-*` rows) is covered by `.t-workflow/scripts/plumbing-test.sh` with fixture
  consumer rows in the new slot.
- `./.t-workflow/scripts/consistency-check.sh` exits 0.
- A consumer pinned to the release that includes this change can add a local skill
  (row in the new slot + `.claude/skills/<name>/SKILL.md`) and pass both
  `consistency-check.sh` and `check-manifest.sh` — flagged in the record as a
  post-merge, cross-repo dry run (`human_checks` in the plan), not verifiable inside
  this task.

## Explicitly not
- No change to the `t-*` pipeline table itself, or to what counts as a protected
  surface.
- No change to `docs/adr/`'s existing consumer-numbering convention.
- Does not itself add any consumer-local skill.

## Decisions made along the way
- Adopted the issue's suggested first-loop extension to `consistency-check.sh` check 3
  (walk local-skill rows in the new slot, same staleness check as `/t-*` rows) — the
  issue framed it as optional ("consider extending"), but it costs little and closes
  the asymmetry the issue itself flags. Scoped the extraction to the `## The pipeline`
  section specifically (not "the first/only local marker") since `AGENTS.md` carries a
  second, unrelated `<!-- local -->` pair under `## Checks`.
- Kept the new slot's placeholder as prose (not a filled-in example table row), same
  pattern as the two existing slots — an example row would need its own matching
  `SKILL.md` to keep this repo's own `consistency-check.sh` green, defeating the point
  of a placeholder.

## Deviations / notes
- none
