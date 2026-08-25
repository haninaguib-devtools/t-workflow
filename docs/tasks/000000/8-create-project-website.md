# 8 — Create the project website
Issue: #8

## Asked
Give visitors a clear, polished introduction to the delivery-system template: what problem it solves, how work moves from an idea to a trusted merge, and where to go next. Publish the result as a fast, accessible GitHub Pages site that feels intentional on phones and desktop.

## Done when
- The repository contains a self-contained static website with a distinctive visual design, responsive behavior, semantic structure, keyboard-visible focus states, reduced-motion handling, and no required third-party runtime dependencies.
- The page explains the project in plain language, presents the delivery stages and core guarantees accurately, and links visitors to the repository documentation.
- A GitHub Actions workflow deploys the site to GitHub Pages from `main` using the official Pages actions.
- The site can be served locally without a build step and all internal asset links resolve beneath a repository Pages subpath.
- `./scripts/consistency-check.sh` exits 0.
- The final diff stays within the declared scope and a human visually approves the rendered desktop and mobile result.

## Explicitly not
No application backend, accounts, analytics, content-management system, custom domain, or change to the project delivery rules.

## Decisions made along the way
- Codex, 2026-08-24 — use dependency-free HTML, CSS, and progressive-enhancement JavaScript so the site adds no stack decision to this stack-neutral template.
- Human, 2026-08-24 — use a practical, white, developer-focused landing page: explain the project directly, make the installer command prominent and copyable, show the core workflow, and describe every skill. Use nginxproxymanager.com only as a tone and layout reference.
- Codex, 2026-08-24 — publish the contents of `site/` as the Pages artifact with official GitHub actions pinned to the current immutable SHAs behind their major-version tags.

## Deviations / notes
- The initial editorial “control room” concept was rejected by the human as too theatrical for a developer tool and was completely replaced before the draft PR. The issue scope and allowed paths did not change.
