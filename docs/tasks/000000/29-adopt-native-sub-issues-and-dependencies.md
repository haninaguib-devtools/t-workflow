# 29 — Adopt native sub-issues and dependencies in the skills
Issue: #29 · Part of: #22

## Asked
Implement ADR-003: `/t-open` creates child issues with `gh issue create --parent` and
sets real dependencies with `--add-blocked-by`, and stops writing `Part of:` /
`Blocked-by:` body markers (`Split from:` stays body text). The three consumers of
those markers switch to native fields: `/t-work`'s blocker gate reads `blockedBy`;
`/t-status` reads `blockedBy` for blocked state and `subIssuesSummary` for initiative
progress; `/t-cancel`'s dependent sweep reads the cancelled issue's `blocking` field
(replacing the scan of every open issue body), and its parent/children/spun-off sweeps
use `parent` / `subIssues` where applicable. `/t-ship` stops ticking tracking-issue
checkboxes — closing the child updates `subIssuesSummary` — and its "completed the
list" question reads that summary. `docs/adapters/TRACKER.md` gains the relation
operations and drops the checkbox use of `tracker:edit-body`; the issue forms under
`.github/ISSUE_TEMPLATE/` drop their marker-heading fields, with
`docs/architecture/issue-templates.md` updated to match. The dual-shape marker parsing
is deleted from every skill.

## Done when
- `grep -rn "Part of: #\|Blocked-by: #" .claude/skills` shows no marker parsing or
  writing logic left (Split from handling remains).
- `docs/adapters/TRACKER.md` defines the relation operations; consistency check 7
  passes (every op a skill names is defined).
- Issue forms carry no "Blocked by" / "Part of" body-text fields.
- A test initiative opened via `/t-open` on a scratch basis shows native parent and
  dependency links (human-verified at review).
- `./scripts/consistency-check.sh` exits 0; CI green on the PR.

## Explicitly not
- No conversion of existing issues in this diff — that is a tracker-side act run
  separately, outside this diff.
- `Split from:` stays a body marker; the two-working-levels rule stays.
- No change to the abandoned-not-satisfied rule for cancelled blockers.

## Decisions made along the way
- Kept `tracker:view`'s bulk companions (`tracker:list-open`, `tracker:list-initiatives`)
  as single-call bulk reads by adding `blockedBy` / `subIssuesSummary` to their existing
  `--json` field lists, rather than having `/t-status` make a per-task or per-initiative
  follow-up call — preserves the "no extra per-item call" cheapness `/t-status`'s own
  doc already commits to (Hani, 2026-08-28).
- Added `parent` to `tracker:view`'s own contract (title, body, state, labels, **parent**)
  rather than a dedicated single-purpose op — `/t-cancel`'s Parent check (Phase 2 step 2)
  needs the cancelled issue's own parent, and `/t-work`/`/t-cancel` already call
  `tracker:view <id>` once at Phase 1 step 1, so this reads it for free instead of adding
  a second call. A deviation from the posted plan, which described `tracker:view`'s
  contract as untouched — that line was written before this specific read need was
  worked through; recorded here rather than re-running `/t-plan` for a same-file,
  same-Allowed-paths refinement (Hani, 2026-08-28).

## Deviations / notes
- **`.github/ISSUE_TEMPLATE/initiative.yml` touched, though the posted plan's Allowed
  paths named only `task.yml` under `.github/ISSUE_TEMPLATE/`.** The issue's own Scope
  line already covered the whole `.github/ISSUE_TEMPLATE/` directory; the plan narrowed
  it, reasoning the initiative form carried no machine-read marker fields. True, but its
  "Tasks" field description still showed a `- [ ] #151 ...` checkbox exemplar —
  `docs/architecture/issue-templates.md`'s own binding rule requires templates to mirror
  `/t-open`'s current shape "in the same change," and that shape no longer produces a
  hand-ticked checklist. Left uncorrected, the form would coach a human to write the
  exact pattern this task retires. Fixed both files together; a small widening back to
  the issue's original Scope, not new scope (Hani, 2026-08-28).
- **gh CLI version gap, verified live, not fixed here.** The relation flags/fields this
  task's adapter commands rely on (`--parent`, `--add-blocked-by`,
  `parent`/`blockedBy`/`subIssuesSummary` JSON fields, etc.) require gh CLI ≥2.94.0
  (2026-06-10). This workspace's gh is 2.45.0 and rejects every one of them
  (`gh issue view 29 --json parent` → "Unknown JSON field", confirmed live). The exact
  command strings in `docs/adapters/TRACKER.md` are written from gh's official
  changelog/PR for 2.94.0 (`--parent`/`--remove-parent`, `--add-sub-issue`/
  `--remove-sub-issue`, `--add-blocked-by`/`--remove-blocked-by`/`--add-blocking`/
  `--remove-blocking`, and matching `--json` fields on `view`/`list`), not executed
  end-to-end against a live gh in this session — no gh upgrade was attempted here since
  it is outside this task's Allowed paths and the plan already flagged the version floor
  as a human/CI concern, not something this diff can fix. Documented in
  `docs/adapters/TRACKER.md` itself as a stated version requirement, so a session on a
  stale gh gets a clear rejected-flag error rather than a silent no-op.
- `tracker:view`'s dead "state only" parenthetical (`gh issue view <id> --json
  state,stateReason`) is removed — it existed solely to serve `/t-work`'s old
  per-blocker state check, which now goes through `tracker:list-blockers` instead (one
  call returning every blocker's state, rather than one `tracker:view` call per
  blocker). No other call site used it (`git grep` confirmed before removing it).
