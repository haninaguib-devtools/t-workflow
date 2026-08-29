# 48 — Remove the stale /t-fix reference in FORGE.md's pr-create comment
Issue: #48

## Asked
`docs/adapters/FORGE.md`'s `forge:pr-create <title> <body>` operation is commented "(the
`/t-fix` path)", but `/t-fix` was removed (issue #25). Update the heading so it no
longer points at a stage that no longer exists.

## Done when
`grep -c '/t-fix' docs/adapters/FORGE.md` returns 0, and the operation's heading still
accurately describes what it does (a non-draft PR create).

## Explicitly not
- No change to the operation's own contract or its mapped command — wording only.

## Decisions made along the way
- none

## Deviations / notes
- Redo of a prior fix (PR #50, commit `bd7f3f6`) that landed only on `wip/47-integration`
  — deleted when the disposable #47 validation initiative was cancelled, so it never
  reached `main` and this task recreates the same one-line wording change (haninaguib,
  2026-08-28, per issue #48's promotion comment).
