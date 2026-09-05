# 130 — Add a local slot to .gitignore so consumers can keep their own ignores under the manifest lock
Issue: #130

## Asked
`.gitignore` is template-owned and hashed into every consumer's `.template-manifest.json`,
but carries no `<!-- local -->` slot, so a consumer has nowhere legal to add its own
ignores without breaking `check-manifest.sh` or resorting to nested per-directory
`.gitignore` files (which don't help a single-module project whose build output sits at
the repo root). Give the template's `.gitignore` a marked local region — the same
mechanism `ci.yml` got in #118 — so a consumer's own entries survive every
`/t-update` sync unchanged.

## Done when
- The template's `.gitignore` ends with an empty `# <!-- local -->` / `# <!-- /local -->`
  region, with a one-line comment above it saying consumer additions go inside and a
  sync never touches them.
- `docs/architecture/local-slots.md` lists the new slot alongside the existing five, and
  `/t-update`'s step 7 example list of marker-carrying files is updated or left pointing
  at `local-slots.md` as the authority.
- `.t-workflow/scripts/check-manifest.sh --hash-file .gitignore` on a copy with real
  entries inside the markers equals the hash of the template's own file. `plumbing-test.sh`
  gets a fixture proving this.
- `consistency-check.sh` passes; a consumer's next `/t-update` sync leaves an
  already-identical `.gitignore` needing only the new empty region appended, no
  migration.

## Explicitly not
- Slots in `CONSTITUTION.md` §3's bullet list or `protected-paths.sh` for consumer-owned
  protected application surfaces — a separate change, its own consistency-check
  implications.
- A migration file — no consumer has diverged from the template's `.gitignore` today.
- Any change to how `check-manifest.sh` strips markers — the existing rule already
  covers a `#`-prefixed marker line.

## Decisions made along the way
- none

## Deviations / notes
- none
