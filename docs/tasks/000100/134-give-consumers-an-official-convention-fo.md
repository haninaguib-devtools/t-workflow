# 134 — Give consumers an official convention for adding their own protected-path bullets
Issue: #134

## Asked
A consumer repo generated from this template sometimes needs to protect its own
application-specific path (e.g. migration files, a domain config directory) the same
way `CONSTITUTION.md` §3's fixed list does — but neither §3's bullet list nor its
executable twin, `.t-workflow/scripts/protected-paths.sh`, carries a local slot, so a
consumer today has to hand-write unmarked custom content into both template-owned
files, which an ordinary `/t-update` sync silently deletes the next time it splices in
the incoming template text. Add an official, upstream-sanctioned local slot for a
consumer's own protected-path bullets/patterns in both files, documented in
`docs/architecture/local-slots.md`, that survives `/t-update` without a consumer having
to invent marker text or placement by hand, and is exercised by
`.t-workflow/scripts/plumbing-test.sh` and `check-manifest.sh` the same way every other
slot is.

## Done when
- `CONSTITUTION.md` §3 carries a `<!-- local -->` … `<!-- /local -->` slot for a
  consumer's own protected-path bullets.
- `.t-workflow/scripts/protected-paths.sh`'s `patterns` array carries a matching slot
  (in the `#`-prefixed line-comment marker form, since a bare marker line is not valid
  bash) for a consumer's own patterns.
- `docs/architecture/local-slots.md` documents the new slot as one of the named set and
  updates its own count language.
- A new `.t-workflow/scripts/plumbing-test.sh` fixture proves `consistency-check.sh`'s
  existing §3 ↔ `protected-paths.sh` symmetry check (check 9) actually exercises a
  consumer bullet/pattern pair added inside the new slot, both ways.
- A migration (`migrations/V3__protected-paths-local-slots.md`) relocates a consumer's
  pre-existing *unmarked* customization to either file into the new slot on the next
  `/t-update` sync, mirroring `migrations/V1__ci-yml-local-slots.md`'s shape — the same
  hazard the issue's own downstream account (`thyme-clinic/thyme`) already hit once for
  `ci.yml`-shaped files.
- `./.t-workflow/scripts/consistency-check.sh` and `.t-workflow/scripts/plumbing-test.sh`
  both pass.

## Explicitly not
- No change to `.t-workflow/scripts/check-manifest.sh` itself — its marker-stripping is
  already generic and format-agnostic; this task adds a fixture proving it, not new
  code.
- No change to `.claude/skills/t-update/SKILL.md` step 7's list of marker-carrying
  files — it already generalizes to whatever `local-slots.md` names next.
- No change to `docs/architecture/manifest.md` — it names no slot count to update.
- Confirming a real consumer's actual `/t-update` sync across this change is a
  post-merge human check, not part of this task's own validation.

## Decisions made along the way
- Added a migration (`V3`) rather than treating this purely as a non-breaking slot
  addition, because the issue's own motivating account establishes that at least one
  real consumer already carries unmarked customizations in both target files — the
  same silent-overwrite hazard `V1` was written to prevent for `ci.yml` (haninaguib,
  2026-09-05, at `/t-plan` time).

## Deviations / notes
- none
