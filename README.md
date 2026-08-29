# t-workflow

> **⚠️ Work in progress.** t-workflow is under active internal use and expected to churn
> significantly before it stabilizes. Please wait for a released version before adopting
> it in your own projects.

A template repo for an agent-driven delivery workflow. It contains no application code —
only the pipeline that moves any change from idea to `main`:

- `CONSTITUTION.md` — the project's invariants. Binding on every task.
- `AGENTS.md` — what an agent reads on session start: pipeline, conventions, checks.
- `docs/workflow.md` — the shape of the pipeline, from idea to merge.
- `.claude/skills/t-*` — the executable stages: `/t-open`, `/t-plan`, `/t-work`,
  `/t-review`, `/t-ship`, `/t-cancel`, `/t-status`.
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
- `.t-workflow/scripts/consistency-check.sh` — cross-artifact document consistency, run by
  `.github/workflows/ci.yml` on every PR.
- `.t-workflow/scripts/github-bootstrap.sh` — applies branch protection / repo settings via `gh`.
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
- `docs/adapters/` — `TRACKER.md` and `FORGE.md`: the backend maps (GitHub today) the
  skills use for every issue/PR operation. Swap in a future backend by editing these
  two files only.
- `installer/` — the one-command bootstrap that turns this template into a new project.
  `install.sh` is the URL people fetch; `bootstrap.sh` does the work after the clone.
  Deleted from every project it generates, along with `LICENSE`, this repo's git history,
  the template website in `site/`, and the website and installer workflows under
  `.github/workflows/`. Those workflows live in their own files precisely so removing
  them is a deletion rather than an edit.

## Bootstrapping a new project

```bash
curl -fsSL https://raw.githubusercontent.com/haninaguib-devtools/t-workflow/main/installer/install.sh | bash
```

It asks for a project name, creates a directory with that name, puts the workflow in it,
and makes the first commit. That is all it does: the project is local-only, nothing is
pushed, and no repository is created anywhere — it prints the `gh repo create` and
`.t-workflow/scripts/github-bootstrap.sh` commands for you to run when you are ready.

To run it without questions, the flags have to reach the script rather than `bash`, which
means `-s --`:

```bash
curl -fsSL https://raw.githubusercontent.com/haninaguib-devtools/t-workflow/main/installer/install.sh \
  | bash -s -- --name my-project
```

`--help` lists every option. What it deliberately does not do: choose a licence for you
(the generated project has no `LICENSE` — see §License below), or invent your stack.

### The two fills, and when they stop being free

The installer cannot know two things, and leaves them exactly as they ship:

- `CONSTITUTION.md` §4 — your stack constraints, each ratified by an ADR.
- `AGENTS.md` §Checks — your build/test command. This is the only place the skills get
  it from; the same command also goes into `.github/workflows/ci.yml` as a third job.

**When you may fill them in by hand depends on one thing: whether the first commit has
been pushed.** That is the genesis exception (`CONSTITUTION.md` §3), and **the exception
ends when that first commit is pushed** — the same end-point whichever route you took to
get there.

The installer never pushes, so right after it runs the exception is always still open:
edit both files by hand, fold them into the first commit, then create the repository and
push — the exact commands the installer prints on exit. Once you have pushed, the
exception has closed: both files are protected surfaces, so each fill is ordinary work —
`/t-open`, then a plan, then a review — and branch protection will refuse a direct push
to `main` in any case.

`CONSTITUTION.md` §3 is a third file worth editing early — add your protected application
surfaces as they appear, along with the matching patterns in `.t-workflow/scripts/protected-paths.sh`.
The two change together, and the same rule about the push applies.

Running `.t-workflow/scripts/github-bootstrap.sh` is never a tree edit — it changes settings on the
forge and produces no diff — so it needs no task, before or after the push. Re-run it
once CI has run on `main`, which is when the status checks can be marked required.

### By hand, without the installer

The installer only automates the steps below; nothing depends on having used it.

1. Copy this repo (or use it as a GitHub template) and `git init`.
2. Replace `README.md` with one describing your project. `installer/templates/README.md`
   is the version the installer writes — copy it **before** step 3 deletes it.
3. Delete `LICENSE`, `installer/`, `site/`, `.github/workflows/installer.yml`, and
   `.github/workflows/pages.yml`; then empty `docs/tasks/` of everything except
   `TEMPLATE.md` and `README.md`.
4. Make the two fills above, plus `CONSTITUTION.md` §3 if you already know your
   application surfaces. Doing them here is the cheap moment — the exception is open.
5. Create the repository on your forge and point the checkout at it, then commit and
   push. **The genesis exception ends here.**

   ```bash
   gh repo create <owner>/<name> --private --source=. --remote=origin   # or add it by hand
   git add -A && git commit -m "Bootstrap the delivery system"
   git push -u origin main
   ```
6. Run `.t-workflow/scripts/github-bootstrap.sh` to set up labels, merge mechanics, and branch
   protection, and re-run it after CI's first run on `main`.
7. From then on every change goes through the pipeline, starting with `/t-open`.

## License

MIT — see `LICENSE`. That covers **this template**, not the projects made from it.

A project generated by the installer ships with **no `LICENSE` file at all**. The
template's file names this repository's copyright holder, so copying it onto someone
else's project would be wrong; and a project with no licence is "all rights reserved" by
default, which is the safe place to start. Whoever generated the project chooses their
own licence and adds it before publishing — ordinary pipeline work, like any other
change.

## Notes

The workflow is stack-agnostic: nothing in the skills assumes a language or framework.
It does assume the trunk is called `main` — that name is written literally in the skills
and scripts, so a repo on `master` or `trunk` renames it there first (one task, one
find-and-replace across protected surfaces).
