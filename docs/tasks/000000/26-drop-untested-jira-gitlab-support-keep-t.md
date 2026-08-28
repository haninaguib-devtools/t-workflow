# 26 — Drop untested Jira/GitLab support, keep the adapter seam
Issue: #26 · Part of: #22

## Asked
Make the adapters GitHub-only while keeping the backend-neutral seam, per ADR-002. Keep
the `tracker:*` / `forge:*` operation names and `docs/adapters/` as the single home of
commands; delete the untested GitLab and Jira rows and prose from both adapter files;
remove the non-numeric-id machinery that exists only for Jira-style keys — the
"PROJ-142 → proj-142" lowercasing rules repeated in the skills, consistency check 8b,
and the alpha-key branch of CI's `record` job id regex; drop the GitLab forge-config
patterns (`.gitlab-ci.yml`, `.gitlab/*`) from `scripts/protected-paths.sh` and the
matching CONSTITUTION.md §3 bullet (the two change together). ADR-001 D4's non-numeric
detail is superseded by ADR-002, not edited.

## Done when
- `grep -rni "jira\|gitlab\|glab\|proj-142" docs/adapters .claude/skills scripts .github/workflows AGENTS.md CONSTITUTION.md docs/workflow.md README.md` shows no living-guidance hits (historical ADRs and task records exempt).
- Consistency check 9 still passes both directions after the §3/script edit.
- `./scripts/consistency-check.sh` exits 0; CI green on the PR.

## Explicitly not
- The operation-name indirection stays — this is not a move to raw `gh` calls in skills.
- No new backend support of any kind; a future backend arrives with its own tests.
- `docs/adr/001-phase0-delivery-workflow.md` — append-only, not edited; ADR-002 already
  supersedes D4's non-numeric clause and names this task as the sibling implementing it.
- `docs/architecture/issue-templates.md`'s Jira/GitLab mention — outside this issue's
  Scope line and done-when grep list, left untouched.

## Decisions made along the way
- The `/t-plan` report widened Allowed paths to include `CLAUDE.md` and `GEMINI.md`,
  reasoning they were byte-identical copies of `AGENTS.md` needing mirrored edits. On
  starting the work, both turned out to be symlinks to `AGENTS.md`
  (`CLAUDE.md -> AGENTS.md`, `GEMINI.md -> AGENTS.md`), not separate files — editing
  `AGENTS.md` updates what they resolve to with no separate edit needed. No behavior
  change from the plan, just a correction to how it's satisfied (hani, 2026-08-28).

## Deviations / notes
- none
