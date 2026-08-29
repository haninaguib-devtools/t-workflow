# 65 — Batch each skill's read-only tracker/forge fetch into one script call
Issue: #65

## Asked
Several skills (`t-status` especially, also `t-drive` and `t-ship`) make a long sequence
of individual `tracker:*`/`forge:*` calls — each a separate LLM-mediated Bash/`gh`
invocation and reasoning round trip — to gather data that carries no judgment (issue
list, blocker state, PR list, reviews, checks). That sequential round-tripping is a real
source of wall-clock slowness. The gate scripts in `.t-workflow/scripts/` already show the
right shape: pure functions over pre-fetched JSON. Extend that pattern to fetching
itself: one script that shells out to `gh`/`git` for everything `t-status`'s read phase
needs and emits a single JSON blob, plus two smaller instances of the same problem —
`t-drive` looping a tracker call per child instead of using a bulk fetch it already has,
and `t-ship` fetching the same PR review twice in one run.

## Done when
- `t-status`'s five list-operations (initiatives, tasks, PRs, local git state,
  cancellations) collapse into one script (`status-snapshot.sh`) invoked once, emitting
  structured JSON the skill then narrates.
- `t-drive` Phase 0 step 3 resolves every open child's blockers from one bulk fetch (the
  same `blockedBy`-bearing list call `t-status` uses) instead of looping
  `tracker:list-blockers` per child.
- `t-ship` fetches `forge:pr-reviews <pr>` once per run and reuses it for both the
  precondition-2 verdict and the precondition-7 pending-human-checks extraction.
- The skills' prose is updated to describe reading one fetched result rather than
  issuing each `tracker:*`/`forge:*` call individually.
- No change to what gets reported or decided — same data, same warnings, fewer round
  trips.

## Explicitly not
- Collapsing any step that involves judgment or a refusal condition (branch resolution,
  blocker-cancelled-vs-closed distinction, protected-surface decisions) into a script —
  those stay LLM-interpreted prose per the pipeline's existing design.
- Writing a script for `t-work`'s or `t-review`'s gate-check phase — the issue names
  them as also affected by the general pattern but the Done-when only requires
  `t-status`, `t-drive`, and `t-ship`; further batching there is left for a future task.

## Decisions made along the way
- `status-snapshot.sh` fetches every open **and closed/merged** PR's `files`, `reviews`,
  and `statusCheckRollup` in one repo-wide `gh pr list --state all --json …` call, rather
  than one `gh pr list` (open only) plus separate per-PR `gh pr view`/`gh pr checks`
  calls as the plan's Risks section anticipated (it only explicitly ruled out folding
  `protected-paths.sh` itself into the script, not the shape of the PR fetch). `gh pr
  list --json` exposes the identical field set `gh pr view --json` does (confirmed via
  `gh pr list --json` / `gh pr view --json` help output), so one call replaces what would
  otherwise be `forge:pr-list` plus a `forge:pr-files`/`forge:pr-reviews`/`forge:pr-checks`
  round trip per PR — and the all-state (not open-only) fetch is what lets the `local`
  section correlate every `wip/*` branch and worktree against its PR's state without a
  second query. The script still leaves the protected-surface decision itself to
  `t-status`'s own `protected-paths.sh --stdin` call, per the plan (haninaguib, during
  implementation).
- Extended `docs/adapters/TRACKER.md`'s `tracker:list-open` row with `updatedAt` (needed
  for the "issue edited after its PR opened" warning) and `docs/adapters/FORGE.md`'s
  `forge:pr-list` row with the new all-state, full-field variant described above — both
  are the narrow field additions the plan's Allowed paths anticipated, not new operations
  or changed commands for anything the script doesn't touch (haninaguib, during
  implementation).
- Confirmed `gh issue list --json blockedBy` and `gh issue view --json blockedBy` (the
  latter is `tracker:list-blockers`'s documented command) return the identical
  per-blocker shape (`id`, `number`, `state`, `title`, `url` — no `stateReason`), so
  switching `t-drive` Phase 0 step 3 from the per-child call to the bulk
  `tracker:list-open` fetch changes zero data fidelity for the blocked/cancelled
  distinction; whatever `t-work`/`t-drive`'s existing prose already does with that field
  today, it can keep doing unchanged (haninaguib, during implementation).

## Deviations / notes
- **Fix pass after `/t-review 65`** (haninaguib, 2026-08-29): the cold subagent review
  on PR #69 found one HIGH finding — `status-snapshot.sh`'s `ci_state` jq function only
  treated the literal conclusion `FAILURE` as a CI failure, so a check run that ended
  `CANCELLED`, `TIMED_OUT`, `ACTION_REQUIRED`, `STARTUP_FAILURE`, or `STALE` (all still
  `status: COMPLETED`) fell through to `"pass"` — a misreport `/t-status` would have
  surfaced, exactly the class of thing the issue's "no change to what gets reported"
  done-when rules out. Fixed by enumerating every terminal non-passing conclusion
  explicitly rather than checking for the single `FAILURE` literal. Unit-tested the new
  logic against all nine conclusion values (`FAILURE`, `CANCELLED`, `TIMED_OUT`,
  `ACTION_REQUIRED`, `STARTUP_FAILURE`, `STALE` → `"fail"`; `SUCCESS`, `NEUTRAL`,
  `SKIPPED` → `"pass"`) plus the pending and no-CI-configured cases before re-running the
  live script. Re-ran `bash .t-workflow/scripts/status-snapshot.sh` (still exits 0, PR #69
  now correctly reports `ciState: "fail"` — its `cold-review` check is red pending this
  very review pass, which is expected), `./.t-workflow/scripts/consistency-check.sh`, and
  `bash .t-workflow/scripts/plumbing-test.sh` (still 47/47).

  While writing the fix, the first attempt broke `jq`'s outer single-quoted program by
  adding a comment containing an apostrophe (`GitHub's checkRun API`) inside the script's
  bash single-quoted jq argument — caught immediately by re-running the script (`jq:
  error: syntax error, unexpected end of file`), fixed by rewording the comment to avoid
  the apostrophe rather than escaping it, since bash single-quotes admit no escape
  sequence at all.

  The two LOW findings from the same review (the `.tasks.truncated` flag's placement,
  and `cancellations.truncated`'s hardcoded `100`) were not addressed — Fix mode
  addresses only blocker/high findings; both are named here for the human as unfixed
  and low-severity, to accept as-is or ask for by number.
