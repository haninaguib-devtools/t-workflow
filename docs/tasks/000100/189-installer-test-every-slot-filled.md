# 189 — installer/test.sh runs the consumer's own checks inside a generated consumer with every local slot filled
Issue: #189

## Asked
Stop finding template bugs on the consumer's machine. Every script the template ships
into a consumer's required CI job was only ever tested here, where every local slot
still holds its placeholder, so each script first met a filled slot in a consumer, at
sync time, after a tag — the way #118, #120, #122, #126, #130, #185 and #186 were all
found. Make the template's own CI generate a consumer, fill every slot the inventory in
`docs/architecture/local-slots.md` names with real content, and run the consumer's whole
check set in that tree, so a template PR that would break a consumer fails here first.

## Done when
- `installer/test.sh` has a section that copies the generated project, fills every
  slot in the inventory (status note, §4 rule, §3 bullet with its `protected-paths.sh`
  pattern, local-skill row with its `SKILL.md`, reviewer model, item 1 build command,
  `site/**` documentation glob, project notes, `ci.yml`'s trunk line, timeout and
  trailing guarded build step, `review-gate.yml`'s timeout, a `.gitignore` entry, a
  `.t-workflow/required-checks.local` file), each located by the template text around
  it, never by counting pairs.
- In that tree it runs `plumbing-test.sh`, `consistency-check.sh`,
  `docs-only.sh --list` (includes `site/**`), `required-checks.sh --list` (includes the
  local context), `protected-paths.sh` (protects the added pattern), and parses both
  workflow files; every one passes.
- It also runs `plumbing-test.sh` inside the adopted `happy` fixture.
- The runs would have failed on the pre-#187 `plumbing-test.sh`: verified by hand and
  stated here.
- `docs/architecture/local-slots.md` says this section is the inventory's guard.

## Explicitly not
- Changing any consumer-facing script or slot.
- A consumer-side override for a template-owned file that is wrong — a separate design
  question, not opened here.

## Origin
system: t-workflow / url: https://github.com/haninaguib-devtools/t-workflow/issues/185

## Verification
none

## Feedback
none

## Decisions made along the way
- Each fill also proves it landed *inside* its slot: the filled file must hash, under
  `check-manifest.sh --hash-file`, exactly as the untouched generated one. That is the
  same property every migration's Done-when checks, so the test and the migrations
  agree on what "in the slot" means. (agent, 2026-09-08)
- A fill whose anchor finds no marker pair fails the test rather than silently
  skipping: a slot the inventory names but the file does not carry is the class of
  drift this test exists to catch. (agent, 2026-09-08)
- The section lives in `installer/test.sh`, not `plumbing-test.sh`: it is a
  template-only self-test (it needs `installer/`, which every consumer deletes at
  genesis), and `plumbing-test.sh` is exactly the consumer-facing script under test.
  (agent, 2026-09-08)

## Deviations / notes
- **Scope grew by one file, on the guard's first catch.** The new section failed on
  its first full run, on `plumbing-test.sh` section 15 (protected-path slot symmetry):
  its fixtures copy the live tree, so a consumer whose §3 slot and pattern slot both
  carry `db/migrations/` — the path the test itself inserts, and the path #134's own
  motivating consumer protects — makes "a bullet with no matching pattern" pass,
  because the consumer's own pattern matches it. The same class as #185, one section
  over. Fixed here rather than as a fourth issue: section 15's three fixtures now empty
  both slots first (`reset_protected_slots`, by heading and marker form, never by
  ordinal), with a guard assertion that the emptied fixture still passes. Allowed paths
  on the issue's plan were amended to add `.t-workflow/scripts/plumbing-test.sh`
  (section 15 only) before commit. The `db/migrations/` fill in `installer/test.sh` is
  kept deliberately, so the collision stays under test.
- Verified by hand that the section is a real regression guard: a generated consumer
  with `site/**` in its documentation-only slot and a rewritten status note, given the
  pre-#187 `plumbing-test.sh` (`7a952f8`), fails the same five assertions locklane#835
  reported; with the current script it passes. The five, verbatim: `docs plus
  site/index.html → 1`, `--list prints exactly the two defaults in this repo`, `--list
  includes a glob from the slot after the defaults`, `without the slot entry (this
  repo), site/index.html is not documentation → 1`, `a slot bullet without backticks is
  ignored`.
- Awk regex anchors are passed with `-v`, which processes backslash escapes, so the
  anchors avoid backslashes (`^patterns=` rather than `^patterns=\(`); the first run
  failed on exactly that and was corrected before commit.
- Built on the #186 branch so the status-note slot exists to fill; rebased onto the
  trunk after #188 merged.
- check 1: no command named in `AGENTS.md` §Checks item 1; this diff touches
  `installer/test.sh`, so it is not documentation-only.
- The human directed this task to run without confirmation stops, on the record of
  their own message in this session.
