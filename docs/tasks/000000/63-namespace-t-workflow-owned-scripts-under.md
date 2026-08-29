# 63 — Namespace t-workflow-owned scripts/ under a dotted directory
Issue: #63

## Asked
The installer generates every new project by wholesale-copying this template's tree
into the target repository's root. Everything that lands at the root becomes part of
the consuming project's own namespace, and `scripts/` is a name almost any real project
will eventually want for its own build/deploy/migration scripts — a collision the
moment a generated project needs a `scripts/` of its own. Move the workflow's own
scripts into a dot-prefixed directory (`.t-workflow/scripts/`), consistent with the
existing convention that tooling this repository owns is dot-prefixed (`.claude/`,
`.github/`) while app-level directories are not.

## Done when
- `scripts/` no longer exists at the repository root; its contents live under
  `.t-workflow/scripts/`.
- Every reference to the old `scripts/` path is updated to the new one, across
  `CONSTITUTION.md`, `AGENTS.md`, the skills under `.claude/skills/`, the adapters,
  `docs/workflow.md`, `docs/architecture/`, `installer/`, `.github/workflows/*.yml`, and
  the root `README.md`. `docs/tasks/` and `docs/adr/` are historical and not rewritten.
- `scripts/protected-paths.sh` (at its new path) keeps the executable protected-path
  check and `CONSTITUTION.md` §3 in agreement.
- `./.t-workflow/scripts/consistency-check.sh` passes, and CI is green.
- A fresh install produces a project with the scripts at the new path and no leftover
  reference to the old one.

## Explicitly not
- Renaming `docs/` or any other root-level directory for the same collision reason —
  deferred, no issue opened.
- Any change to how `installer/bootstrap.sh` decides what to strip from a generated
  project — that logic stays; only the paths it names move.

## Decisions made along the way
- The plan's validation grep (`grep -rn "scripts/" ...`) is a substring match, so as
  literally written it can never return empty once files reference the new
  `.t-workflow/scripts/` path — that path still contains the substring `scripts/`.
  Interpreted the check by its stated intent ("no stale reference to the old path
  survives") and ran it with an added `| grep -v '\.t-workflow/scripts/'` to isolate
  genuinely old-style, un-prefixed `scripts/` references. Confirmed zero. Did not
  re-plan a second time over a validation-command wording nit; flagging it here for
  `/t-review` and worth fixing in a future plan's command text (haninaguib, during
  implementation).
- `.t-workflow/scripts/plumbing-test.sh` computes its own repo root as
  `"$(cd "$here/.." && pwd)"` relative to its own directory (`here`). The plan's Risks
  section said the move "does not break their internal logic" for scripts using
  `dirname "$0"`, but this one specifically walks up from its own directory to the repo
  root — and the move added one level of nesting (`scripts/` → `.t-workflow/scripts/`),
  so unpatched it would have resolved `.t-workflow/` as "root" instead of the actual
  repo root, silently breaking every fixture path built from `$root` (e.g.
  `$root/docs/tasks/TEMPLATE.md`). Fixed by walking up two levels
  (`$here/../..`) instead of one. `check-plan-gate.sh`, `check-review-gate.sh`, and
  `template-owned-paths.sh` were unaffected — they reference `"$here/protected-paths.sh"`,
  a same-directory sibling, so nesting depth doesn't change that relationship
  (haninaguib, during implementation).
- `.t-workflow/scripts/consistency-check.sh`'s §-reference checks (1 and 2b) candidate a
  line for `docs/workflow.md` whenever the line contains the substring `workflow`. The
  new directory name `.t-workflow/` contains that same substring, so any line that
  mentions `.t-workflow/scripts/...` near a `§`-reference — e.g. `.claude/skills/t-review/SKILL.md`'s
  "`AGENTS.md` §Checks ... `.t-workflow/scripts/consistency-check.sh`" — was
  false-flagged as an unresolved `docs/workflow.md` reference. Fixed by stripping the
  literal `.t-workflow` substring from the line before the `*workflow*` case-match in
  both checks, rather than loosening or skipping the check (haninaguib, during
  implementation).

## Deviations / notes
- Re-planned mid-`/t-work` (haninaguib, before any file was touched). `/t-work`'s Phase 1
  gate check ran a full-repo `grep -rl "scripts/"` and found two protected files the
  original plan's Allowed paths never covered — `.claude/skills/t-update/SKILL.md` (6
  references) and `docs/architecture/manifest.md` (5 references) — plus eight
  unprotected `site/reference/*.html` pages describing the same tooling. Since the two
  protected files would have grown the diff onto surfaces the plan never named, work
  stopped for `/t-plan 63` rather than editing them under a scope that didn't cover
  them.

  Previous Allowed paths (first plan pass): `scripts/**`, `.t-workflow/scripts/**`,
  `CONSTITUTION.md`, `AGENTS.md`, `.claude/skills/t-work/SKILL.md`,
  `.claude/skills/t-review/SKILL.md`, `.claude/skills/t-ship/SKILL.md`,
  `.claude/skills/t-status/SKILL.md`, `.claude/skills/t-drive/SKILL.md`,
  `docs/adapters/TRACKER.md`, `docs/adapters/FORGE.md`, `docs/workflow.md`,
  `docs/architecture/local-slots.md`, `docs/architecture/issue-templates.md`,
  `installer/bootstrap.sh`, `installer/install.sh`, `installer/test.sh`,
  `installer/templates/README.md`, `.github/workflows/ci.yml`,
  `.github/workflows/review-gate.yml`, `.github/workflows/installer.yml`, `README.md`.

  New Allowed paths (second plan pass) add: `.claude/skills/t-update/SKILL.md`,
  `docs/architecture/manifest.md`, `site/reference/*.html` (docs.html, index.html,
  installer.html, migrations.html, scripts.html, skills.html, structure.html,
  workflows.html). The re-plan also widened the validation grep's `--include` list to
  add `*.html` — the first pass's check would not have caught a stale reference left in
  the site pages even if they went unfixed.
