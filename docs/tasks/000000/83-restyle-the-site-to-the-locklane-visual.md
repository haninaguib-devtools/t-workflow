# 83 — Restyle the site to the locklane visual language
Issue: #83

## Asked
The project's GitHub Pages site (`site/`) looks like a generic modern SaaS page: white
background, Inter sans-serif, indigo accent, rounded cards with large soft drop shadows,
a wide 1180px column. The sibling project locklane has a distinctly different look we
want here instead: warm off-white "paper", brown ink, a terracotta accent, monospace type
throughout, hairline 1px rules instead of shadows, and a narrow reading column. This task
restyles our site to that visual language. Nothing a reader reads changes — the same
pages, the same sections, in the same order, with the same words. Only the presentation
changes.

## Done when
- `site/styles.css` uses the locklane design tokens: `--paper: #faf9f7`, ink `#35322c`,
  muted `#837c72`, hairline `#ddd8d0`, accent `#c15f3c`, and a monospace stack as the
  body font at 15px/1.6.
- No `box-shadow` remains as a surface treatment in `site/styles.css`; panels are
  separated by 1px borders.
- The main content column is ~880px wide, not 1180px.
- `site/index.html` and every page under `site/reference/` render in the new style — no
  page is left on the old tokens.
- The rendered text content of every page is unchanged: for each page, the visible prose,
  headings, links, and their order are identical to `main`. Section anchors and nav
  targets still resolve.
- Human judgment: opened side by side with the locklane site, ours reads as the same
  design family.

## Explicitly not
- No copy, section, or page-structure edits — this is a restyle, not a content revision.
- No new pages, and no navigation changes.
- Not copying locklane's content, sections, or layout structure — only its visual
  language.
- No dark-mode support.

## Decisions made along the way
- none

## Deviations / notes
- none
