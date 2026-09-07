# 164 — Deploy the project site only by manual workflow dispatch, never on push to main
Issue: #164

## Asked
The project's GitHub Pages site should go live only when a human deliberately runs the
deploy workflow, not automatically every time `main` moves. Today
`.github/workflows/pages.yml` triggers on both `push` to `main` and `workflow_dispatch`,
and every recent deployment (including the one after #162) was a push-triggered run.
Remove the `push` trigger so `workflow_dispatch` is the workflow's only trigger, leaving
the build and deploy jobs themselves unchanged.

## Done when
- `.github/workflows/pages.yml` has `workflow_dispatch:` as the sole entry under `on:`;
  `grep -nE '^\s+push:' .github/workflows/pages.yml` matches nothing.
- The workflow's jobs, steps, pinned action SHAs, permissions, concurrency group, and
  `path: site` are byte-for-byte unchanged: `git diff <trunk> -- .github/workflows/pages.yml`
  touches only the `on:` block.
- After merge, a push to `main` does not start a "Deploy website to Pages" run, and a
  manual dispatch does. This is verified by a human on the live repository after the PR
  lands: `gh run list --workflow=pages.yml --limit 3 --json event` shows no `push` event
  for runs created after the merge commit.
- `./.t-workflow/scripts/consistency-check.sh` passes.

## Explicitly not
- No change to what the workflow builds or deploys, to the `site/` contents, or to any
  other workflow under `.github/workflows/`.
- No replacement trigger (a tag, a release, a path filter) — manual dispatch is the
  intended and only trigger.
- No documentation of the deploy procedure beyond this issue; if a "how to deploy the
  site" note is wanted in the README or the site itself, that is its own task.
- Note: once this lands, a merged change to `site/` (for example #163) is not visible on
  the live site until someone runs the workflow by hand.

## Origin
none

## Verification
none

## Feedback
none

## Decisions made along the way
- none

## Deviations / notes
- The plan originally carried the post-merge live-behavior check ("a push to `main`
  does not redeploy, a manual dispatch does") as a `required: true` `## Verification`
  entry. Corrected via a re-plan: `/t-ship`'s gate blocks on any required entry that is
  `pending`/`rejected`/stale, and this entry's evidence is only obtainable *after*
  merge — it could never become `verified` before `/t-ship` runs, and there is no
  actual risk to accept, so `risk-accepted` would have been the wrong state too. Moved
  to a `human_checks` item on the issue's `## Plan` instead, per `/t-plan`'s own
  guidance for a criterion "verification only possible post-merge." Does not gate
  `/t-ship`; a maintainer performs it as a follow-up once the PR is merged.
