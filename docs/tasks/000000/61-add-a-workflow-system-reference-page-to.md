# 61 — Add a workflow-system reference page to the site
Issue: #61

## Asked
The public site (`site/`) gives a high-level pitch for the workflow but has no page
that goes deep on mechanics. Add a reference section — a small set of linked pages
under `site/reference/`, not one long page — linked from the site's home page, that
documents the delivery system this template installs end to end: every file/directory
the installer places in a new project and what it is for; what each `/t-*` skill does
(its steps, and the concrete `tracker:*`/`forge:*` operations and scripts it calls and
when); every script under `scripts/` and every GitHub Actions workflow under
`.github/workflows/` — what each does and when it runs; how the migrations mechanism
works (the versioned manifest and `/t-update`); the contents of `docs/adr/`,
`docs/adapters/`, `docs/architecture/`, and `docs/tasks/`; and how a project is
actually created and configured from the template via `installer/install.sh` and
`installer/bootstrap.sh`.

## Done when
- A reference section exists under `site/reference/`: an index page
  (`site/reference/index.html`) presenting a contents list at the top, then an intro,
  then an overview of the whole system — followed by separate topic pages it links to,
  not one single long page. All pages styled consistently with the existing
  `site/index.html` / `site/styles.css`.
- Together the pages document, in enough detail for a reader to understand the system
  without opening the source: every file/directory the template installs; each skill
  in `.claude/skills/` (what it does, and the concrete `tracker:*`/`forge:*` operations
  and scripts it invokes and when); every script under `scripts/`; every GitHub Actions
  workflow under `.github/workflows/`; how the migrations mechanism works; the contents
  of `docs/adr/`, `docs/adapters/`, `docs/architecture/`, and `docs/tasks/`; and how
  `installer/install.sh` plus `installer/bootstrap.sh` create and configure a new
  project.
- `site/index.html` links to the reference section's index page from its nav or footer.
- `./scripts/consistency-check.sh` passes.
- A human can read the pages start to finish and come away understanding the whole
  delivery system.

## Explicitly not
- Changing the existing pitch/marketing content of `site/index.html` beyond adding the
  one link.
- Changing the migrations mechanism, `/t-update`, or any script/workflow behavior —
  documented as they exist, not modified.

## Decisions made along the way
- Re-planned mid-`/t-plan` (before any implementation) from a single `site/reference.html`
  page to a multi-page `site/reference/` section with an index hub, at the human's
  direct request for fuller coverage (GitHub Actions workflows, all scripts, the
  migrations mechanism, `docs/` contents) split across linked pages rather than one long
  page. Previous Allowed paths (`site/reference.html`) are superseded; see the issue's
  `## Plan` for the full reasoning (haninaguib, 2026-08-28).
- Corrected the issue's original Non-goals bullet claiming no update mechanism exists —
  `/t-update` and the migrations convention merged (`a33c33f`) before this task was
  planned; the page documents them as they exist (haninaguib, 2026-08-28).

## Deviations / notes
- At Phase 1, `origin/main` was one commit ahead of this branch's base: #59 ("Remove the
  `/t-clean` skill", PR #60) had merged, deleting `.claude/skills/t-clean/` and updating
  `AGENTS.md`, `docs/workflow.md`, `docs/adapters/FORGE.md`, and `site/index.html`
  accordingly (nine skills now, not ten; ADR-005 supersedes ADR-002's `/t-clean` piece).
  This branch had zero commits of its own, so it was fast-forwarded onto `origin/main`
  before any file was touched — no rebase/merge conflict, no follow-up needed. The plan's
  anticipated scope-overlap risk with #59 resolved itself: this task's content is written
  fresh against the post-#59 tree (nine skills, no `/t-clean`), never describing ten.
- `gh` in this environment is 2.45.0, older than the ≥2.94.0 `docs/adapters/TRACKER.md`
  requires for native `blockedBy`/`parent`/`subIssues` fields (ADR-003). The Phase 1
  blocker check (`tracker:list-blockers 61`) could not run natively; issue #61's body
  names no blocking relationship and none was otherwise apparent, so work proceeded — a
  standing environment gap, not specific to this task.
