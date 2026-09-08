# 185 — plumbing-test.sh's docs-only tests read the consumer's live AGENTS.md slot and fail once it is filled
Issue: #185

## Asked
A consumer that writes anything into `AGENTS.md`'s documentation-only slot (the slot
#183 / ADR-012 added for exactly that purpose) cannot merge any PR: five assertions in
`.t-workflow/scripts/plumbing-test.sh` section 23 read the *live* `AGENTS.md` of
whatever repo the test runs in and assert the slot is empty. They pass in this repo,
where the slot is the placeholder, and fail in every consumer that uses the slot. CI
runs the script unconditionally as part of the required `checks` job, and the file is
template-owned, so the consumer cannot correct it locally without failing the manifest
check instead. Hit on locklane (haninaguib-devtools/locklane#835, the `v0.1.1` →
`v0.1.2` sync): listing `` - `site/**` `` in the slot fails these five:

- `--list prints exactly the two defaults in this repo` — compares `docs-only.sh
  --list` on the live repo against `*.md`/`docs/**` only.
- `docs plus site/index.html → 1 (not documentation-only)` — runs the live script;
  with `site/**` in the slot the script correctly answers 0.
- `without the slot entry (this repo), site/index.html is not documentation → 1` —
  same.
- `--list includes a glob from the slot after the defaults` — `make_fixture_repo`
  copies the live `AGENTS.md`, then `insert_docs_only_glob` adds `site/**` a second
  time, so the list has it twice.
- `a slot bullet without backticks is ignored` — the fixture again inherits the
  consumer's real slot content, so the list is not the bare defaults.

The test is checking the template's own state, not the rule.

## Done when
- Every assertion in the `docs-only.sh` section runs against a fixture `AGENTS.md`
  whose slot content the test itself sets (empty, one backticked glob, one plain
  bullet, no heading) — never against the running repo's live file.
  `make_fixture_repo` (or the section's own copy step) resets the documentation-only
  slot to the neutral placeholder before a test inserts anything.
- The section passes unchanged in this repo **and** in a checkout whose `AGENTS.md`
  slot carries `` - `site/**` `` (add that as a case: copy the repo, fill the slot, run
  the whole section against the copy).
- No change to `docs-only.sh`'s behaviour or to the slot's contract in
  `docs/architecture/local-slots.md`.
- Ships in the next tag so consumers pick it up through `/t-update`.

## Explicitly not
- Changing what counts as documentation, or how the slot is read.
- Any other test section.
- Cutting the release tag itself — a maintainer does that by hand after merge.

## Origin
system: locklane / url: https://github.com/haninaguib-devtools/locklane/issues/835

## Verification
none

## Feedback
none

## Decisions made along the way
- Section 23 becomes one function, `run_docs_only_section <source-tree> <label>`,
  invoked twice — once on this repo, once on a copy whose slot carries `site/**` — so
  the consumer case runs the identical assertion set rather than a hand-picked subset
  that could drift from it. (agent via /t-drive, 2026-09-08)
- The section's own copy helper (`copy_tree`, a tar of a directory) replaces
  `make_fixture_repo` inside section 23: `make_fixture_repo` copies `git ls-files` of
  `$root` and cannot copy the non-git consumer fixture. `make_fixture_repo` itself is
  untouched (section 11, outside scope). (agent via /t-drive, 2026-09-08)
- The slot reset scopes to the `### Documentation-only paths` heading, exactly as
  `docs-only.sh`'s own `slot_globs` does, never by marker ordinal. (agent via /t-drive,
  2026-09-08)
- The three trailing structural assertions (manifest-hash round-trip, five marker
  pairs, pair order) also move onto the reset fixture, so nothing in the section reads
  the live `AGENTS.md` even where it would have passed. (agent via /t-drive, 2026-09-08)

## Deviations / notes
- Check 1 does not exist in this repository (`AGENTS.md` §Checks item 1 still reads
  "none yet"), so there was nothing to run; `docs-only.sh` over the whole diff exits 1
  naming `plumbing-test.sh`, so the documentation-only skip does not apply either.
- Dead end worth remembering: the first cut of `reset_docs_only_slot` built the
  placeholder with `$(printf …)`, and command substitution strips the trailing newline,
  so the closing `<!-- /local -->` marker was glued onto the placeholder's last line
  and the manifest hash no longer matched. The placeholder is now a `$'…'` literal
  with its newline, and the section asserts the reset copy hashes the same as the
  source tree's own `AGENTS.md` — a guard that holds in a consumer too, since the hash
  ignores slot content.
- Verified from outside the test as the plan asks: in a clone with `` - `site/**` `` in
  the slot, the trunk version of the script fails exactly the five assertions the issue
  names (`217 passed, 5 failed`); this version passes (`251 passed, 0 failed`), the same
  as in this repo.
