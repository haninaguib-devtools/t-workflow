# 30 — CI: enforce plan, review, and blocker gates mechanically
Issue: #30 · Part of: #22

## Asked
Today several safety rules of this pipeline live only as prose an agent has to remember:
that a change to a protected file needs a written plan first, that shipping one needs a
fresh (not self-graded) review that says it's ready, that every dependency a task is
waiting on has actually been finished (not just closed as abandoned), that the paper
trail (the task record, the PR title) actually matches the work, and that the commit
message written to `main` is self-contained. This task turns those rules into automated
checks GitHub runs on every pull request, so a violation is caught by CI rather than
relying on an agent noticing.

Concretely: (1) a PR touching a protected surface fails unless its issue carries exactly
one `## Plan` section; (2) a protected PR requires a current cold review — a required
status check, re-run on review events, failing unless the latest review body has
`readiness: ready`, an `isolation:` line that is not `same session`, and a timestamp
newer than the head commit; (3) at merge time every blocker of the PR's issue is closed
as completed — read from the native `blockedBy` field — failing on an open or
not-planned blocker; (4) the task record is real: heading and `Issue: #<id>` line match
the branch id, template sections present; (5) the PR title starts `[<id>]` matching the
branch. A plumbing-test job covers `scripts/protected-paths.sh` (exit codes 0/1/2,
quoted non-ASCII paths), the bucket math, and the record check against fixture diffs.
`scripts/github-bootstrap.sh` registers the new required contexts.

## Done when
- Each new check demonstrably fails on a violating fixture and passes on a clean PR;
  the evidence (commands and results) is in the task record.
- The plumbing-test job runs in CI and passes.
- `scripts/github-bootstrap.sh` names the new required contexts.
- `./scripts/consistency-check.sh` exits 0; CI green on the PR.

## Explicitly not
- No warn-only squash-message audit on main (deferred until messages actually drift).
- The issue-body-drift warning stays in `/t-status`, not CI.
- No weakening or removal of any existing check (CONSTITUTION.md §1.5).

## Decisions made along the way
- Factored each gate's decision logic into a small, pure `scripts/check-*.sh` script
  (`check-plan-gate.sh`, `check-title-gate.sh`, `check-blocker-gate.sh`,
  `check-review-gate.sh`, `check-record.sh`), each taking fixture-friendly input (a
  file, stdin paths, or both) rather than calling the tracker/forge itself. The
  workflow YAML is left as thin plumbing — fetch, then hand off. This is what makes
  Done-when 1's "demonstrably fails on a violating fixture, passes on a clean one"
  possible without a live PR for every check, and is why `scripts/plumbing-test.sh`
  could cover all five, not only the three the issue names by name (hani, 2026-08-28).
- `scripts/plumbing-test.sh` tests `check-plan-gate.sh`, `check-title-gate.sh`,
  `check-blocker-gate.sh`, and `check-review-gate.sh` in addition to the three the issue
  explicitly named (`protected-paths.sh`, the bucket math, the record check). Same
  fixture-driven approach, same cost to add, and it makes Done-when 1's fail/pass
  evidence permanent and re-run on every future PR instead of a one-off transcript in
  this record (hani, 2026-08-28).
- The `blockers` job calls `gh api graphql` directly rather than
  `gh issue view --json blockedBy` (the literal command in
  `docs/adapters/TRACKER.md`'s `tracker:list-blockers` row). Two reasons: (a) the
  contract table for that row promises only `state` per blocker, not `stateReason`,
  and `stateReason` is what tells a cancelled blocker from a completed one
  (ADR-001 §D3.2) — already an open finding on #29's review, unrelated to this task,
  left as-is since `docs/adapters/TRACKER.md` is outside this task's Allowed paths;
  (b) the `gh` CLI available while planning/implementing this task (2.45.0) rejects
  `--json blockedBy` outright (`Unknown JSON field`), so it could not be exercised
  locally at all — confirmed while planning. The equivalent `gh api graphql` query
  returns `stateReason` today even on that old CLI (also confirmed while planning),
  and needs no assumption about the Actions runner's `gh` version either (hani,
  2026-08-28).
- `title-gate` checks only that the PR title starts with `[<id>]`, not that the rest
  matches the issue title verbatim — matching the goal's literal wording ("starts
  `[<id>]` matching the branch") and leaving room for a human to edit a draft PR's
  title afterward without tripping the gate (hani, 2026-08-28).
- The cold-review gate lives in its own workflow file (`review-gate.yml`), not a job in
  `ci.yml`: it is the one check that must also fire on `pull_request_review` (a review
  being submitted doesn't touch the PR's commits, so nothing in `ci.yml`'s
  `pull_request`-triggered jobs would re-run). Splitting the file keeps that second
  trigger from also re-running `consistency`/`record`/`plan-gate`/`title-gate`/
  `blockers` on every review comment (hani, 2026-08-28).
- `ci.yml`'s `pull_request` trigger gained the `edited` type (previously the default
  `opened, synchronize, reopened`), so `plan-gate` (reads the issue body — a plan added
  after the PR was opened needs no new commit to be picked up) and `title-gate` (a
  title-only edit is not a new commit) get a fresh run without requiring a push. This
  also makes `consistency`/`record`/`blockers` re-run one extra time on a pure edit,
  which is harmless — same inputs, same result (hani, 2026-08-28).
- "At merge time" (goal item 3) has no GitHub Actions hook that fires on the literal
  merge click without a merge queue (flagged as a risk in the Plan). The practical
  answer used here: both `plan-gate` and `blockers` re-derive their verdict from
  current tracker state on every run, and a required check can be re-run on demand from
  the Actions UI immediately before merging with no new commit needed — so "at merge
  time" is satisfied by a deliberate re-run, not automatically. Left as a Pending human
  check per the Plan rather than solved silently (hani, 2026-08-28).
- `scripts/github-bootstrap.sh`'s required-contexts list also gained `plumbing-test`
  (the issue's Done-when only requires it to "run in CI and pass", not that it be a
  required check) — made required anyway, consistent with this task's own goal of
  moving guardrails from convention into mechanical enforcement, and it costs nothing
  extra since the script already gates all new contexts on the same `consistency`-seen
  detection it uses for the others (hani, 2026-08-28).
- `docs/workflow.md` §9 (which lists what's "in force today, mechanically" and names
  `ci.yml`'s jobs) is now stale — it does not mention `plan-gate`, `title-gate`,
  `blockers`, `cold-review`, or `plumbing-test`. `docs/workflow.md` is outside this
  task's Allowed paths (Scope was `.github/workflows/`, `scripts/`) and updating it is
  not a typo/formatting fix, so it was left untouched rather than taken as a ride-along.
  Recommending a follow-up issue in the closing report (hani, 2026-08-28).

## Deviations / notes
- none — implementation stayed within the plan's Allowed paths throughout.

## Validation evidence (Done-when 1)
`scripts/plumbing-test.sh`, run from the repo root, exercises every new check-*.sh
script against fixtures that must fail and fixtures that must pass, plus
`protected-paths.sh`'s exit codes/quoting and the bucket-math formula:

```
$ bash scripts/plumbing-test.sh
protected-paths.sh
  ok   exit 0 on a protected path (rc=0)
  ok   exit 1 when none are protected (rc=1)
  ok   exit 2 when nothing was given (rc=2)
  ok   exit 2 on empty stdin (rc=2)
  ok   un-quotes and un-escapes a quoted non-ASCII path

bucket math
  ok   id 30 -> 000000
  ok   id 99 -> 000000
  ok   id 100 -> 000100
  ok   id 142 -> 000100
  ok   id 7031 -> 007000

check-record.sh
  ok   a correct record passes (rc=0)
  ok   a heading with the wrong id fails (rc=1)
  ok   an Issue line that only prefix-matches (#420 vs #42) fails (rc=1)
  ok   a record missing template sections fails (rc=1)
  ok   a missing record file fails (rc=1)

check-plan-gate.sh
  ok   protected diff, no Plan section: fails (rc=1)
  ok   protected diff, one Plan section: passes (rc=0)
  ok   protected diff, two Plan sections: fails (rc=1)
  ok   unprotected diff: passes regardless of the issue body (rc=0)

check-title-gate.sh
  ok   title starting [<id>] passes (rc=0)
  ok   title with no prefix fails (rc=1)
  ok   title with the wrong id fails (rc=1)

check-blocker-gate.sh
  ok   every blocker closed as completed: passes (rc=0)
  ok   no blockers at all: passes (rc=0)
  ok   an open blocker: fails (rc=1)
  ok   a cancelled (not-planned) blocker: fails — abandoned, not satisfied (rc=1)

check-review-gate.sh
  ok   protected + current ready fresh review: passes (rc=0)
  ok   protected + readiness not-ready: fails (rc=1)
  ok   protected + isolation same session: fails (rc=1)
  ok   protected + no isolation line: fails (unknown, not cold) (rc=1)
  ok   protected + review predates head commit: fails (rc=1)
  ok   protected + no review at all: fails (rc=1)
  ok   unprotected diff: passes without needing a review (rc=0)

33 passed, 0 failed
```

`./scripts/consistency-check.sh` also run locally: `OK: all consistency checks passed`
(exit 0).

**Live confirmation on PR #42 itself**, the real end-to-end test — this task's own
issue (#30) has a `## Plan` section, every blocker closed as completed, and the PR
title/branch match, so `plan-gate`, `title-gate`, `blockers`, `record`, and
`plumbing-test` all ran against real GitHub state and passed; `cold-review` correctly
**failed** with `FAIL: no review on this PR`, since none had been posted yet —
demonstrating on a live PR, not only a fixture, that the gate actually blocks:

```
$ gh pr checks 42
cold-review     fail   6s
blockers        pass   8s
consistency     pass   4s
plan-gate       pass   5s
plumbing-test   pass   6s
record          pass   4s
title-gate      pass   4s
```

The runner's `gh` (Actions "Current runner version" 2.336.0-era image) supports
`gh api graphql` fine — the `blockers` job's fallback from `gh issue view --json
blockedBy` was the right call regardless of the runner's exact `gh` version, per the
Decision above.
