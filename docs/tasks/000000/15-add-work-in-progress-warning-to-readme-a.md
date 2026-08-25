# 15 — Add work-in-progress warning to README and GitHub Pages site
Issue: #15

## Asked
t-workflow is currently being adopted and stress-tested across several internal tools,
and is expected to churn significantly before it stabilizes. People discovering the repo
(via README or the GitHub Pages site) need a clear, visible warning that this is not yet
a stable, released project, so they don't build on it prematurely. Add a prominent
work-in-progress notice to both the README and the project's GitHub Pages site, asking
readers to wait for a released version before adopting t-workflow.

## Done when
- The README has a clearly visible (near the top) notice stating the project is a work
  in progress, undergoing active internal use and expected to churn, and asking readers
  to wait for a released version.
- The GitHub Pages site (docs/ or whatever generates the site) carries an equivalent
  visible notice.
- The wording is consistent between the two locations.

## Explicitly not
- Does not define what "a released version" means (versioning/release process) — that's
  a separate concern.

## Decisions made along the way
- none

## Deviations / notes
- none
