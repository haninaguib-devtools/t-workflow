# 18 — Consolidate skill drift from locklane back into the template
Issue: #18 · Part of: #17

## Asked
The nine `t-*` skills under `.claude/skills/` exist here and as copies in the consumer
repo haninaguib-devtools/locklane, and five of them (t-cancel, t-fix, t-open, t-ship,
t-wtree) have drifted in both directions: locklane added improvements this repo lacks
(e.g. t-open's classification-labels step, t-wtree's clearer worktree-freshness
wording), while this repo has wording locklane lacks. Merge both copies into one
best-of-both canonical version here. Locklane's t-open improvement references a
"Classification labels" section in `docs/adapters/TRACKER.md` and four extra label
lines in `scripts/github-bootstrap.sh` that exist only in locklane — port those here
too, since the merged skill text depends on them. A local checkout of locklane may be
used for the comparison (e.g. a sibling clone of haninaguib-devtools/locklane at
`main`); reading it needs no locklane-side task.

## Done when
- For each of the nine skills, this repo's `SKILL.md` contains every improvement present
  in either copy; the task record documents the per-skill merge decisions (human-judged
  via side-by-side diff).
- `docs/adapters/TRACKER.md` here carries the classification-labels section and
  `scripts/github-bootstrap.sh` ensures those labels.
- No consumer-specific content leaks into the template:
  `grep -ri locklane .claude/skills docs/adapters` returns nothing.

## Explicitly not
- No changes to governance docs (AGENTS.md, CONSTITUTION.md, docs/workflow.md,
  docs/architecture/) — that consolidation is its own task under the same initiative
  (#19).
- No sync/update mechanism — also its own task under the same initiative (#20).
- `docs/adapters/FORGE.md`, which also drifted from locklane (a real addition on `gh`'s
  branch-deletion ordering that `/t-ship` needs), stays untouched — the issue's Scope
  line names `docs/adapters/TRACKER.md` specifically, not the whole `docs/adapters/`
  directory. Flagged in the plan and in this task's closing report as a finding for the
  human to decide (fold in, or split to a follow-up issue) rather than acted on here.

## Decisions made along the way
Compared against a fresh clone of `haninaguib-devtools/locklane` at `main`, commit
`2c147618` (Claude, 2026-08-28). Per-skill merge decisions:

- **t-cancel** — kept: locklane's clearer phrasing of the branch-deletion re-read
  warning ("a command missing the ... flag closes silently and leaves the branch
  stranded on `origin`" vs. this repo's vaguer "a command reconstructed from memory ...
  is exactly how a branch survives a close unnoticed"). Rejected: locklane's citation
  `(#39)` — that's locklane's own issue number. This repo already had its own valid
  citation for the same content, `(issue #13)` (this repo's real issue that added the
  warning); kept that instead of dropping the citation entirely.
- **t-fix** — same pattern and same decision as t-cancel, applied to the
  `forge:pr-merge` re-read warning in step 6.
- **t-open** — locklane's classification-labels + project-label auto-apply step (its
  own "step 4" insertion, plus the `tracker:ensure-labels` mention in step 3) ported
  wholesale: purely additive, no locklane-specific content, and this repo had nothing
  to contribute to this point (one-directional improvement, not actually bidirectional
  despite the issue's framing).
- **t-ship** — largest diff (85 lines), three separable improvements found:
  1. Re-read warning wording — same merge as t-cancel/t-fix: kept locklane's phrasing,
     citation reverted to this repo's own `(issue #13)`.
  2. Squash-commit subject format `[<id>] <issue title> (#<pr>)` (was `<issue title>
     (#<pr>)`) — adopted, for consistency with the same `[<id>]` prefix ported into
     t-work's draft-PR title below. Doesn't conflict with `CONSTITUTION.md` §1.4 (which
     constrains the body, not the subject).
  3. Step 5 cleanup rewritten as two explicit, always-both-taken actions (worktree
     removal vs. checkout fast-forward), replacing an either/or framing that could skip
     the fast-forward when a worktree existed — ported, with locklane's issue citations
     (`#121`, `#92`) genericized into plain prose, since those are locklane-internal
     incident numbers with no equivalent here.
  **Withheld, not ported**: locklane's step-4 addition verifying the remote branch was
  actually deleted (`git ls-remote --heads origin <headRefName>` after merge, guarding
  against `gh` silently failing to delete the remote branch when the local delete
  fails first). Its rationale cites `docs/adapters/FORGE.md` as documenting that
  ordering behavior — but that documentation is the same `FORGE.md` addition this
  task's plan already flagged as out of the issue's stated scope (`docs/adapters/
  TRACKER.md` only). Porting the t-ship step without the FORGE.md text behind it would
  leave a citation pointing at a file that doesn't say what the citation claims. Left
  for the human to decide alongside the FORGE.md question in the closing report —
  fold both in together, or split both to a follow-up issue.
- **t-work** — one-line diff (not named as drifted in the issue's Goal paragraph, but
  in scope per the Done-when line, which covers all nine skills): draft-PR title
  changed from the issue title alone to `[<id>] <issue title>`, matching the t-ship
  subject format decision above.
- **t-wtree** — locklane's clearer restatement of why creating from `origin/main`
  needs no separate freshness check (explicitly says uncommitted work elsewhere in the
  primary checkout never blocks the step) — adopted verbatim; equivalent meaning to
  this repo's prior wording, just more explicit.
- **t-plan, t-review, t-status** — confirmed byte-identical to locklane's copies; no
  change.

## Deviations / notes
- This task's session working directory (`t-workflow-2-18`) was a broken git worktree
  on start — its `.git` file pointed at a worktree registration that was never created
  in the parent checkout (`t-workflow-2`). Verified byte-identical to `main` (no
  divergent content), so it was deleted and recreated with `git worktree add -b
  wip/18-consolidate-skill-drift-from-locklane-ba` — human-confirmed before the
  destructive step. Not part of this task's file scope; noted here only because it
  happened during this session.
