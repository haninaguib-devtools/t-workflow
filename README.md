# t-workflow

A template repo for an agent-driven delivery workflow. It contains no application code —
only the pipeline that moves any change from idea to `main`:

- `CONSTITUTION.md` — the project's invariants. Binding on every task.
- `AGENTS.md` — what an agent reads on session start: pipeline, conventions, checks.
- `docs/workflow.md` — the shape of the pipeline, from idea to merge.
- `.claude/skills/t-*` — the executable stages: `/t-open`, `/t-plan`, `/t-wtree`,
  `/t-work`, `/t-review`, `/t-ship`, `/t-cancel`, `/t-status`, `/t-fix`.
- `docs/adr/` — the decision log (one file per decision). Ships with ADR-001, the
  baseline decision defining the workflow itself; your project's own decisions start
  at the next number.
- `docs/tasks/` — task records, one per shipped task, sharded into ID buckets of 100
  (task 142 → `docs/tasks/000100/`).
- `docs/architecture/confirmation-gates.md` — how `/t-ship` and `/t-cancel` ask for
  confirmation: one plain question, evidence first, never proceeding on silence.
- `.github/ISSUE_TEMPLATE/` — GitHub issue forms mirroring `/t-open`'s task and
  initiative shapes, so hand-opened issues arrive with the same structure
  (`docs/architecture/issue-templates.md` is the spec).
- `scripts/consistency-check.sh` — cross-artifact document consistency, run by
  `.github/workflows/ci.yml` on every PR.
- `scripts/github-bootstrap.sh` — applies branch protection / repo settings via `gh`.
- `CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md` — symlinks to `AGENTS.md`,
  so Claude Code, Gemini CLI, and GitHub Copilot read the same instructions as agents
  that support `AGENTS.md` natively (Codex, Cursor, …). Edit only `AGENTS.md`.
- `.agents/skills` — symlink to `.claude/skills`, the real home of the skill files, so
  tools that look for skills in the neutral location find the same ones. Edit only
  `.claude/skills/`. (Symlinks need `core.symlinks` on Windows checkouts.)

  **How far the agent-neutrality goes:** the *instructions* are shared — four agents read
  the same `AGENTS.md`, and the skill files are plain markdown any agent can be pointed
  at. What is Claude Code-specific is invoking them as `/t-open`, `/t-work`, and so on.
  Another agent runs a stage by being told to follow `.claude/skills/t-work/SKILL.md`;
  it gets the same instructions without the slash command.
- `docs/adapters/` — `TRACKER.md` and `FORGE.md`: the backend maps (GitHub by default)
  the skills use for every issue/PR operation. Swap Jira or GitLab in by editing these
  two files only.

## Bootstrapping a new project

Steps 1–3 are the **genesis exception** (`CONSTITUTION.md` §3): they are done by hand,
because there is no tracker and no `main` to open a PR against yet. The order matters —
edit *before* the first commit, so the exception closes when that commit is pushed.

1. Copy this repo (or use it as a GitHub template) and `git init`.
2. Fill in the placeholders:
   - `CONSTITUTION.md` §3 — add your protected application surfaces as they appear, and
     the matching patterns in `scripts/protected-paths.sh`; the two change together.
   - `CONSTITUTION.md` §4 — your stack constraints, each ratified by an ADR.
   - `AGENTS.md` §Checks — your build/test commands. This is the only place the skills
     get them from.
3. Create the repository on your forge and point the checkout at it, then commit and
   push. **The genesis exception ends here.**

   ```bash
   gh repo create <owner>/<name> --private --source=. --remote=origin   # or add it by hand
   git add -A && git commit -m "Bootstrap the delivery system"
   git push -u origin main
   ```
4. Run `scripts/github-bootstrap.sh` to set up labels, merge mechanics, and branch
   protection. Re-run it after CI's first run on `main` to make the checks required.
5. From now on every change goes through the pipeline, starting with `/t-open`. That
   includes adding your build/test command to `.github/workflows/ci.yml` as a third job
   once the stack exists.

## License

MIT — see `LICENSE`. A template exists to be copied, so the permissive default is the
useful one; change it before publishing if your project needs otherwise.

## Notes

The workflow is stack-agnostic: nothing in the skills assumes a language or framework.
It does assume the trunk is called `main` — that name is written literally in the skills
and scripts, so a repo on `master` or `trunk` renames it there first (one task, one
find-and-replace across protected surfaces).
