# 75 — Update site/reference/scripts.html for the current script set
Issue: #75

## Asked
The GitHub Pages site's scripts reference page (`site/reference/scripts.html`) was
written before several scripts were added to `.t-workflow/scripts/`, so it now
undersells what the workflow ships. Bring it in line with what actually exists in that
directory.

## Done when
- `site/reference/scripts.html` documents every script currently in
  `.t-workflow/scripts/`, including the ones missing today: `check-manifest.sh`,
  `check-record.sh`, `github-bootstrap.sh`, `protected-paths.sh`,
  `review-snapshot.sh`, `status-snapshot.sh`, `template-owned-paths.sh`.
- Each entry follows the page's existing format/tone for describing a script (one-line
  purpose, matching the style already used for `consistency-check.sh` etc.).
- `diff <(grep -oE '[a-z][a-z-]+\.sh' site/reference/scripts.html | sort -u) <(ls
  .t-workflow/scripts/ | sort -u)` shows no missing entries (a human judges
  wording/prose quality).

## Explicitly not
- Auditing or updating any other site page (e.g. `site/reference/skills.html`,
  `site/reference/workflows.html`) for staleness — out of scope here, not opened as a
  separate issue since no specific gap was found on those pages yet.

## Decisions made along the way
- none

## Deviations / notes
- Of the seven scripts the issue names as missing, five (`check-manifest.sh`,
  `check-record.sh`, `github-bootstrap.sh`, `protected-paths.sh`,
  `template-owned-paths.sh`) were already documented on the page before this task
  started — an earlier task (#69/#65-adjacent script additions) evidently added them.
  Confirmed with the issue's own diff command before implementing. Only
  `review-snapshot.sh` and `status-snapshot.sh` were actually missing; those two are
  the only entries this task adds.
