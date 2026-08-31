# 118 — ci.yml has no local-slot markers, so every consumer sync misreports it as changed and requires manual re-splicing

Issue: #118

## Asked
`docs/architecture/local-slots.md` marks `<!-- local -->` slots on exactly two files
today: `CONSTITUTION.md` and `AGENTS.md`. `.github/workflows/ci.yml` carries no such
slot, yet every consumer hand-customizes it (at minimum a `timeout-minutes` override,
often extra trailing build/manifest-check steps). Because there is no slot, a
consumer's recorded manifest hash for `ci.yml` is a hash of their customized file, so
every future `/t-update` sync flags it as "changed" even when the template's own
`ci.yml` didn't move — and a human/agent has to manually re-splice the local content
back in from memory each time (observed twice in `haninaguib-devtools/locklane`, tasks
#424 and #442).

Give `ci.yml` real `<!-- local -->` slots for the two known customization points — the
`checks` job's `timeout-minutes`, and an extension point at the end of its `steps:`
list — following the same mechanism `AGENTS.md` and `CONSTITUTION.md` already use, so a
sync tool can splice this file exactly like it already does for those two.

## Done when
- `docs/architecture/local-slots.md` documents the new slot(s) in `ci.yml`, same style
  as the existing two.
- A sync tool applying the existing splice procedure (copy target file whole, replace
  marked regions with the consumer's current content) produces a correct, working
  `ci.yml` for a consumer with a customized timeout and trailing build/manifest-check
  steps — verified against a consumer fixture or `locklane`'s own current `ci.yml`.
- `.t-workflow/scripts/check-manifest.sh`'s normalized hashing already strips marked
  regions generically, so no script change should be needed beyond the new markers
  landing in the right places — confirm this rather than assuming it.

## Explicitly not
- Retrofitting an already-synced consumer's existing hand-customized `ci.yml` by hand —
  that consumer's own migration path, applied via `/t-update`.
- Any application-level CI content (build/test steps themselves) — this task only adds
  the slot mechanism, not example content for it.

## Decisions made along the way
- The plan (`/t-plan 118`) found that a bare `<!-- local -->` line is not valid YAML
  (confirmed with PyYAML) — every marker in `ci.yml` is written as a YAML line-comment
  (`# <!-- local -->`), which required extending `check-manifest.sh`'s marker regex to
  recognize an optionally-indented, optionally-`#`-prefixed marker line, kept
  backward-compatible with the existing bare-line markers in `CONSTITUTION.md`/
  `AGENTS.md`.
- The plan also found that the first sync shipping this fix is itself a breaking change
  for any consumer whose `ci.yml` is already hand-customized (no markers to splice
  from yet) — `docs/architecture/migrations.md`'s first-ever migration file,
  `migrations/V1__ci-yml-local-slots.md`, carries that consumer content forward instead
  of letting the sync silently overwrite it.
- `.claude/skills/t-update/SKILL.md` step 7's splice bullet named only
  `CONSTITUTION.md`/`AGENTS.md` by name; generalized to "every changed/added file that
  carries `<!-- local -->` markers" so `ci.yml`'s new markers actually get spliced by a
  real sync, not just described as spliceable.

## Deviations / notes
- `migrations/README.md`'s landing-pad line ("No migration files exist yet") is now
  inaccurate now that `migrations/V1__ci-yml-local-slots.md` exists, but that file was
  not in the plan's Allowed paths and there is no human present mid-task in this driven
  run to approve widening scope for it — left untouched; flagged in the closing report
  as a one-line follow-up (fold into this PR on request, or its own tiny task).
