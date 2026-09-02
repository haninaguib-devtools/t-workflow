# 122 — template-owned-paths.sh false-positives on consumer files added under a protected directory
Issue: #122

## Asked
`template-owned-paths.sh --list` decides "is this file template-owned" by pattern
alone — every git-tracked file under a protected pattern, minus the genesis-only
exclusion set — with no way to tell a file the template actually shipped from a file a
consumer created later on their own, that merely happens to sit under a protected
directory like `.claude/skills/`. That makes it a false positive for a consumer-local
skill or ADR the consumer added themselves: it blocked `/t-plan`'s step 3
template-owned-file check on a consumer task even though the file in question was
never a manifest key.

## Done when
- A file that is git-tracked, sits under a protected pattern, but is not a key in the
  current `.template-manifest.json`'s `files` map, is no longer reported by
  `template-owned-paths.sh --list`.
- A file the template genuinely ships (already a manifest key, or produced by a fresh
  `installer/bootstrap.sh` run before any manifest exists) is still correctly reported
  as template-owned.
- `docs/architecture/manifest.md` § Which files are template-owned describes the
  corrected rule.
- New fixture coverage in `.t-workflow/scripts/plumbing-test.sh` exercises both the
  false-positive fix and the still-correct true-positive case.

## Explicitly not
- Does not change what counts as a *protected* path (`CONSTITUTION.md` §3,
  `protected-paths.sh`).
- Does not retroactively touch any consumer's already-written
  `.template-manifest.json`.

## Decisions made along the way
- Fix lives entirely in `template-owned-paths.sh` (plus its doc and tests), not in
  `/t-plan`'s step 3 — the script is the one place `docs/architecture/manifest.md`
  already designates as "the executable list", so precision belongs there rather than
  in every caller. (Hani, 2026-09-02, via `/t-drive 122`)
- When `.template-manifest.json` exists at the repo root, `--list` now intersects the
  pattern-matched candidates with the manifest's `files` map keys (via `jq` + `comm
  -12`), rather than reporting the pattern match alone. With no manifest present
  (this repo itself, or `t-update`'s scratch clone of the template at a target tag,
  or a freshly-bootstrapped consumer before its first commit) the behavior is
  unchanged: pure pattern-based reporting. (Hani, 2026-09-02)

## Deviations / notes
- none
