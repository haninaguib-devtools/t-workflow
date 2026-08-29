# 20 — Add t-update: versioned manifest, migrations convention, CI lock
Issue: #20 · Part of: #17

## Asked

Give consumer repos a deliberate, verifiable way to take template updates, so their
copies of the template-owned files can never drift silently again. Five pieces:
release versioning for this repo (git tags), a manifest format each consumer commits
(pinned tag, template-owned file list, hashes), a `t-update` skill that syncs a
consumer forward while preserving its `<!-- local -->` slots and refusing to run on a
dirty owned file, a CI-lock check script consumers wire into their own CI, and a
documented migrations convention (`migrations/V<n>__slug.md`, no files written yet).

## Done when

- A rehearsal in a scratch clone of a consumer repo (documented here): `t-update`
  performs a correct first sync, preserving slot content; the check script exits 0 on
  the synced tree and non-zero after a hand-edit to an owned file.
- `t-update` visibly refuses when an owned file is dirty relative to the pin.
- The manifest format, tag scheme, and migrations convention are documented.
- This repo carries its first release tag.

## Explicitly not

- No migration files (convention only; the first real one ships with the first
  breaking change).
- No consumer-side adoption — locklane's own `t-update` run, manifest, and CI wiring
  are a locklane-tracker task (referenced from #17).
- No wiring of `scripts/check-manifest.sh` into this repo's own CI — the check is a
  no-op here by the issue's own words; each consumer wires it into its own CI.
- No changes to `installer/` — a newly bootstrapped repo does not get an initial
  manifest seeded automatically; flagged as a follow-on gap, not fixed here.

## Decisions made along the way

- `migrations/` is not added to `CONSTITUTION.md` §3 / `scripts/protected-paths.sh` in
  this task (hani, 2026-08-28). It carries no binding content yet — `migrations/README.md`
  is a thin pointer to `docs/architecture/manifest.md` / `migrations.md`, both of which
  are already protected. The task that lands the first real `V<n>__slug.md` migration
  file is the right place to add `migrations/*` to the protected list alongside it,
  matching the existing pattern of tightening a protected surface in the same task that
  first puts binding content there.
- The manifest's template-owned file list is `scripts/protected-paths.sh --list` minus
  genesis-only exclusions (`README.md`, `LICENSE`, `installer/`, `site/`,
  `.github/workflows/installer.yml`, `.github/workflows/pages.yml`) — confirmed by
  reading `installer/bootstrap.sh`, which stamps `README.md` once at genesis and
  deletes the rest outright for every generated project. Documented explicitly in
  `docs/architecture/manifest.md` rather than left for a reader to infer.
- The rehearsal (done-when 1) clones this repo as its own stand-in "consumer" — no
  other repo is available to test against, and locklane's real adoption is out of
  scope. Flagged in the plan for the human to confirm this satisfies the issue's
  "scratch clone of a consumer repo" wording.

## Deviations / notes

- **The plan's agent_check called for "a scripted rehearsal ... run via
  `./scripts/plumbing-test.sh` or standalone"; what's below is a documented manual
  rehearsal instead.** `t-update` is a prose skill, not a callable program — its
  splicing and gating steps are things an agent follows, not a script `plumbing-test.sh`
  can invoke. What *is* mechanical (`check-manifest.sh`'s hash normalization and verify
  mode, `template-owned-paths.sh`'s file list) is covered by real `plumbing-test.sh`
  fixtures, below. The rehearsal itself — walking the actual sync end to end — was
  performed once, by hand, exactly as the issue's done-when asks, with results recorded
  here rather than re-run automatically on every future PR.

- **Symlinks needed their own comparison rule, not content hashing.** The first
  rehearsal pass failed immediately: `.agents/skills` is a symlink to a *directory*
  (`.claude/skills`), and `check-manifest.sh --hash-file` tried to read it as a text
  file (`[ -f ]` rejects a symlink-to-directory) and errored. Fixed by comparing every
  symlink (`CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md`, `.agents/skills`)
  by its `readlink` target instead of hashing through it — simpler and more precise for
  an alias anyway ("is this still the same link", not "does its resolved content
  match"). `docs/architecture/manifest.md` documents the corrected rule.

- **The slot-marker regex was matching prose, not just real markers — caught by the
  rehearsal's step 8, not by inspection.** The first full rehearsal produced a false
  negative: `check-manifest.sh` reported a synced `docs/architecture/manifest.md` as
  clean *after* a hand-edit, because `awk`'s `/<!-- local -->/` pattern matched any
  line *containing* that substring — including this repo's own prose describing the
  convention ("A template-owned file may carry `<!-- local -->` … `<!-- /local -->`
  regions"), which put the file into permanent skip mode from that sentence onward, so
  everything after it stopped counting toward the hash. Fixed by requiring the whole
  trimmed line to *be* the marker (`^<!-- local -->[[:space:]]*$`), matching
  `docs/architecture/local-slots.md`'s own stated convention ("one marker per line").
  Re-verified with both a prose-mention fixture and a real-marker fixture (below).

## Rehearsal (done-when 1 and 2)

Performed by hand, 2026-08-28, using this repo itself as the stand-in "consumer" (no
other repo exists to rehearse against; flagged in the plan for the human to confirm this
satisfies the issue's "scratch clone of a consumer repo" wording). Full transcript kept
in this session; the essentials:

1. Cloned this repo at `cb698a4` (the commit before this task) into a scratch dir —
   the "old consumer." Filled its two local slots (`CONSTITUTION.md` §4,
   `AGENTS.md` §Checks item 1) with fake but realistic consumer content (a stack rule,
   a check command), committed — simulating a real genesis fill.
2. Built its `v0` manifest (43 files, `scripts/template-owned-paths.sh --list` ×
   `scripts/check-manifest.sh --hash-file`). `check-manifest.sh` on the clean tree: **rc
   0**. Hand-edited a non-slot line in `docs/workflow.md`, re-checked: **rc 1**, `DRIFT:
   docs/workflow.md` reported by name — proves done-when 2 (dirty-file detection; the
   mechanism `/t-update` step 3 uses to refuse).
3. Reverted the hand-edit, then synced forward to this task's current working tree (48
   files): every file spliced or copied by hand per the skill's step 7 rule — the two
   slot files spliced (old slot content kept, everything else from the new tag), the
   other 46 copied whole, symlinks recreated as symlinks. Confirmed by grep: the fake
   consumer content survived in both slot files, and new template content (the
   `/t-update` pipeline-table row) is present in `AGENTS.md`.
4. Built the `v1` manifest from the synced tree (48 files). `check-manifest.sh`: **rc
   0** — proves the "correct first sync" half of done-when 1. Hand-edited
   `docs/architecture/manifest.md` post-sync, re-checked: **rc 1**, `DRIFT:
   docs/architecture/manifest.md` — proves the "non-zero after a hand-edit" half.

Both bugs above were caught during this rehearsal, fixed, and the fixes were re-run
through the same steps before this record was written — the rc values above are from
the corrected script. Scratch directory removed after use; nothing from it is part of
this diff.
