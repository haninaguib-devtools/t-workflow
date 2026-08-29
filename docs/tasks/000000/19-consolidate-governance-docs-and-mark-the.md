# 19 — Consolidate governance docs and mark the per-repo slots
Issue: #19 · Part of: #17

## Asked
The governance docs shared with consumer repos — `AGENTS.md` and its aliases
(`CLAUDE.md`, `GEMINI.md`), `CONSTITUTION.md`, `docs/workflow.md`, `docs/architecture/`
— have small two-way drift with haninaguib-devtools/locklane, and contain two slots
that are per-repo by design: the application constraints in `CONSTITUTION.md` §4 and
the check-command list in `AGENTS.md` §Checks. Harvest the drift both ways, then make
the per-repo slots machine-recognizable by wrapping each in explicit
`<!-- local --> … <!-- /local -->` markers, so a future sync tool can replace
everything outside the markers and preserve everything inside. Declare `AGENTS.md` the
single source `CLAUDE.md` and `GEMINI.md` come from, and document the marker
convention in `docs/architecture/`.

## Done when
- Governance docs here contain every improvement present in either repo's copy
  (human-judged via diff against locklane `main`, decisions below).
- The two per-repo slots are wrapped in markers, and the template text inside them is
  the neutral placeholder (this repo is itself at Phase 0).
- `cmp AGENTS.md CLAUDE.md && cmp AGENTS.md GEMINI.md` both succeed.
- The marker + alias convention is documented in `docs/architecture/`.

## Explicitly not
- No skill changes — sibling task #18 (already merged).
- No sync/update mechanism — sibling task #20, blocked on this one.
- `docs/architecture/releasing.md` (locklane-only, Maven/`pom.xml`-specific release
  tooling) is not templated here — see Decisions.
- A stale reference in `docs/architecture/confirmation-gates.md` (still names the
  removed `/t-fix` and the removed `/t-cancel` teardown step) is left untouched —
  reported as a follow-up finding, not fixed here (out of this task's actual scope,
  not a pure typo).

## Decisions made along the way
Compared against `haninaguib-devtools/locklane` at `main`, commit `44f856e4`
(Claude, 2026-08-28).

- **Discovery that changes the mechanism, not the goal**: `CLAUDE.md`, `GEMINI.md`, and
  `.github/copilot-instructions.md` are already symlinks to `AGENTS.md`
  (`CLAUDE.md -> AGENTS.md`), not separate stamped copies. `cmp` succeeding is
  therefore guaranteed by construction, not by a process that needs enforcing. The
  issue's Goal describes this as "stamping" — that word is inaccurate for what's
  actually here, so `docs/architecture/local-slots.md` documents the real mechanism
  (a filesystem alias, one file, nothing to keep in sync) instead of inventing a
  stamping step that doesn't exist. Practically: edits happen to `AGENTS.md` only —
  never to `CLAUDE.md`/`GEMINI.md` directly, which would either edit the same
  underlying file or risk replacing the symlink with a real file.
- **Harvested from locklane → here**: `AGENTS.md` §Conventions dropped the sentence
  documenting the `[<id>] <title> (#<pr>)` squash-commit/draft-PR-title convention,
  even though this repo's own skills (`t-work` step 4, `t-ship` step 3) still implement
  it and this repo's own commit history (`git log --oneline`) still follows it.
  Restored, adapted to this repo's current (non-Jira/GitLab, numeric-id-only) wording —
  locklane's version still carries the multi-backend Jira-key caveat this repo dropped
  in #26, which is not restored.
- **Not harvested — locklane predates this repo's own later changes**: everything else
  in locklane's copies of `AGENTS.md`/`CONSTITUTION.md`/`docs/workflow.md` is the
  *older* model this repo already moved past since #19 was opened — `/t-wtree`,
  `/t-fix`, the Jira/GitLab backend abstraction, body-text `Blocked-by:`/`Part of:`
  markers (superseded by ADR-003's native fields), the retro's `/t-fix`-count
  tracking. None of it is a locklane-side improvement to pull in; it's drift in the
  other direction that locklane simply hasn't caught up on yet (out of this task's
  reach — no consumer-side task exists here per the issue's own non-goals).
- **`docs/architecture/releasing.md`** exists only in locklane and is entirely tied to
  its own Maven build (`<revision>` in `pom.xml`, `engine/pom.xml`, a `locklane.jar`
  artifact). Not a template convention — this repo is Phase 0 with no stack decided
  (`CONSTITUTION.md` §4 reserved) — so it stays locklane-only, not templated here.
- **`CONSTITUTION.md` §4** stays the reserved placeholder (this repo's own state); the
  marker wraps the placeholder sentence so a consumer's real content (e.g. locklane's
  Spring Boot/Angular/SQLite/PTY line) can sit inside it without touching anything else
  in the file on sync.
- **`AGENTS.md` §Checks**: only item 1 (the check-1 build/test command) is per-repo;
  items 2–3 (`consistency-check.sh`, the scope-diff review) and the CI-wiring sentence
  are template machinery every consumer shares, so only item 1 is wrapped.
- **New file `docs/architecture/local-slots.md`** documents both the marker convention
  and the alias mechanism, in the style of the existing `confirmation-gates.md` /
  `issue-templates.md` docs.

## Deviations / notes
- The installed `gh` CLI here is 2.45.0, below the ≥2.94.0 `docs/adapters/TRACKER.md`
  requires for native sub-issue/dependency JSON fields (ADR-003). `gh issue view 19
  --json blockedBy` (the documented `tracker:list-blockers` command) failed with
  `Unknown JSON field: "blockedBy"`. Worked around for this task's Phase 1 blocker
  check using `gh api graphql` directly against the same field
  (`blockedBy(first: 10) { totalCount nodes { number title state } }`), which returned
  `totalCount: 0` — no blockers, gate passes. Not a scope item for this task (no
  `docs/adapters/` or `scripts/` changes were planned or made); flagged in the closing
  report as an environment gap the human may want to fix (upgrade `gh`) since every
  future `/t-work`, `/t-cancel`, and `/t-status` run in this checkout will hit the same
  wall on any relation operation.
