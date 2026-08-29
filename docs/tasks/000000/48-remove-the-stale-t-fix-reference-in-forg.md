# 48 — Remove the stale /t-fix reference in FORGE.md's pr-create comment
Issue: #48 · Part of: #47

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
- none
