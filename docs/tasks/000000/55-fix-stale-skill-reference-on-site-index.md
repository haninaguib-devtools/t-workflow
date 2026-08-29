# 55 — Fix stale skill reference on site/index.html
Issue: #55

## Asked
The public project website (`site/index.html`) describes the delivery pipeline's skill
set, but it has drifted out of sync with the actual pipeline. It still advertises
`/t-wtree` and `/t-fix`, both removed, and never mentions `/t-clean`, `/t-drive`, or
`/t-update`, all added later.

## Done when
- `site/index.html`'s skill reference section lists exactly the ten current skills —
  `/t-open`, `/t-plan`, `/t-work`, `/t-review`, `/t-drive`, `/t-ship`, `/t-cancel`,
  `/t-clean`, `/t-update`, `/t-status` — matching `AGENTS.md`'s pipeline table and
  `.claude/skills/`.
- `/t-wtree` and `/t-fix` no longer appear anywhere on the site.
- `/t-clean`, `/t-drive`, and `/t-update` each have their own skill card, worded from
  `AGENTS.md`'s pipeline table.
- The section's summary copy is corrected to reflect ten commands total, with a clear
  split between the core task-path commands and the supporting ones.
- `./scripts/consistency-check.sh` exits 0.
- A human visually approves the rendered desktop and mobile result.

## Explicitly not
- No change to README.md, docs/workflow.md, or any other documentation surface.
- No redesign of the site beyond correcting the stale skill list; the hero and "Five
  stages" workflow-path sections describe only the always-on core path and are
  unaffected.

## Decisions made along the way
- Widened the issue's Done-when from 8 to 10 skills before implementation (haninaguib,
  2026-08-28, at `/t-plan` time): `/t-drive` and `/t-update` merged the same day the
  issue was filed, so the original 8-skill wording would have made the site stale again
  immediately. Confirmed with the human via AskUserQuestion before editing the issue.

## Deviations / notes
- Fast-forwarded local `main` and this branch from `cb698a4`/`a33c33f` to `a5909d9`
  before starting work — the branch had zero unique commits, so this was a pure
  fast-forward, not a rebase. Picked up an unrelated merged PR (#57, FORGE.md's stale
  `/t-fix` reference) that doesn't touch this task's scope.
