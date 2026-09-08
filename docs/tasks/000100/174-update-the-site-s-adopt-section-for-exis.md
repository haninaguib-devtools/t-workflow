# 174 — Update the site's Adopt section for existing repositories
Issue: #174 · Part of: #168

## Asked
The project site's Adopt section said "Install the delivery system before the first
application commit" and showed only the new-project route (the `install.sh` curl
command that generates a brand-new project). Once `installer/adopt.sh` exists (#172,
now merged into this initiative's integration branch), a person with an existing
repository should find their own route there too: the command to run inside their
repo, that it merges what it can automatically and refuses the rest rather than
guessing, that the resulting adoption PR is planned and independently reviewed from
its own branch like any other protected change, and that repository settings are
applied with `github-bootstrap.sh` after it merges. Add that as a second route beside
the existing one, in the site's own voice and structure, and reword the heading so it
no longer reads as excluding existing projects.

## Done when
- `site/index.html`'s Adopt section presents both routes, and its heading no longer
  says adoption must precede the first commit.
- The adoption route's command and flags match `installer/adopt.sh --help`.
- The page renders without layout regressions in both themes (a human check, with
  screenshots in the record).
- `./.t-workflow/scripts/consistency-check.sh` exits 0.

## Explicitly not
- Any change to the installer or its docs.
- Restructuring other sections of the site.

## Origin
none

## Verification
none — the plan declares no structured `verification:` list, only the ordinary
`human_checks:` under its `### Validation` heading (`docs/architecture/verification.md`
§Relationship to `human_checks`).

## Feedback
none

## Decisions made along the way
- **Read `installer/adopt.sh --help` from this branch's own merged copy of #172**
  (agent, 2026-09-08), not from #172's issue text, per the plan's own risk note — the
  flags documented on the site (`--ref`, `--source`, `--template`, `--build-command`,
  `--dry-run`) and the described behavior (works out loud before writing anything,
  refuses on anything needing a person's judgment, opens a tracking issue and commits
  to a new branch without ever pushing or opening the PR itself, prints the push /
  `/t-plan` / `/t-review` / `github-bootstrap.sh` commands on exit) are copied from the
  actual `--help` output and `docs/architecture/adoption.md`, not guessed.
- **Reworded the heading to "Install the delivery system before the first commit, or
  retrofit it in."** (agent, 2026-09-08) — kept close to the original's length and
  cadence rather than spelling out "existing repository" in the `<h2>` itself (which
  would have roughly doubled its length against every other section heading on the
  page, all of which stay well under it at `h2`'s `max-width: 21ch` display-heading
  styling). The two routes are labeled "New project" / "Existing repository" directly
  underneath, so the heading's "retrofit it in" is disambiguated immediately below it
  rather than needing to carry the whole distinction on its own.
- **Wrapped each route in a new `.adopt-route` container** (agent, 2026-09-08) instead
  of interleaving a label into the existing flat structure, so the divider between the
  two routes could reuse the same margin/border-top/padding-top pattern the page
  already uses for section-internal transitions (`.ci-story`), rather than inventing a
  new visual language. Only additive CSS was introduced (`.adopt-route`,
  `.adopt-route + .adopt-route`); no existing rule was changed, so the new-project
  route's own rendering is unaffected.

## Deviations / notes
- **Visual verification performed by this agent, not just described from HTML/CSS.**
  A headless Chrome (`google-chrome --headless=new`) was available in this environment,
  so rather than only reading the stylesheet, the actual page was rendered and
  screenshotted: light theme (default), dark theme (a throwaway local copy of
  `index.html` with `data-theme="dark"` forced before the stylesheet loads — never
  committed), and a 390px-wide mobile viewport, each with
  `--force-prefers-reduced-motion` so the page's own scroll-triggered `.reveal`
  animations resolve to their final state immediately (matching what
  `site/script.js`'s own reduced-motion branch does) instead of capturing a
  render caught mid-fade. All three were cropped to the Adopt section and inspected:
  - **Light desktop (1400px):** both routes render with clear "New project" /
    "Existing repository" labels, each command box and its five-/four-item numbered
    list laid out identically to the pre-existing structure; the border-top divider
    between routes reads as a clean section break; no overlapping or clipped text.
  - **Dark desktop (1400px):** same layout, correct dark-theme colors throughout (the
    new markup introduces no new color values — it reuses `.section-kicker`,
    `.adopt-command`, `.adopt-steps`, and existing CSS custom properties only), no
    contrast or visibility issues in either command box or the numbered steps.
  - **Mobile (390px):** the existing `.adopt-command` mobile breakpoint (single-column,
    copy button below the command) applies identically to the new second route; long
    inline `--flag` text and the raw curl URL wrap without overflowing; both routes'
    numbered steps stack cleanly.

  No layout regression was found in any of the three renders. That said, the issue's
  own Done-when calls this out explicitly as **a human check** ("this is stated as a
  human check in the issue itself, not something to try to automate" — the plan's own
  risk note) — an agent's own visual read is corroborating evidence, not a substitute
  for it. The rendered screenshots themselves are session-local artifacts (this task's
  scope is `site/` only, and there is no existing convention in this repository for
  committing binary screenshots into a task record); they were not committed. A human
  reviewer can reproduce the exact same check with:
  `google-chrome --headless=new --force-prefers-reduced-motion --window-size=1400,2000 --screenshot=out.png "file://$(pwd)/site/index.html#adopt"`
  (append a small inline script forcing `data-theme="dark"` before `styles.css` loads,
  as this session did, for the dark-theme render).
- The new-project route's own markup, copy, and command are byte-for-byte unchanged —
  only wrapped in the new `.adopt-route` container — so its previously-reviewed
  rendering is not a new surface here.
