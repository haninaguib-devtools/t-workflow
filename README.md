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

## Adopting an existing repository

If you already have a repository — code, history, its own CI — and want the delivery
pipeline without starting over, run the adoption script from a clean, up-to-date
checkout of its trunk:

```bash
curl -fsSL https://raw.githubusercontent.com/haninaguib-devtools/t-workflow/main/installer/adopt.sh | bash
```

(or clone this repo and run `installer/adopt.sh` directly.) `--ref <tag>` pins the
template release (a tag, never a branch — the manifest it writes pins one);
`--source <url|path>` and `--template <owner/name>` point it at a template source
other than this public repository; `--build-command <cmd>` fills `AGENTS.md` §Checks
item 1 and adds the matching CI step, left as the template's own placeholder when
omitted; `--dry-run` computes and prints the plan, then stops, writing nothing;
`--help` lists all of it.

It works out loud before writing a byte: it computes the whole plan first and prints
it. What it merges automatically: a real `CLAUDE.md`/`AGENTS.md`/`GEMINI.md`/
`.github/copilot-instructions.md` moves verbatim into `AGENTS.md`'s project-notes
slot, becoming the template's own alias symlink; an existing `.gitignore` folds into
the template file's own trailing slot; an existing `.github/workflows/ci.yml` is
renamed so it keeps running unmodified, with folding its build step into the new
workflow left as a follow-up in the generated task record. What it refuses outright,
listing every collision at once rather than stopping at the first: a `.claude/`
skill directory literally named `t-*` that collides with the pipeline's own, a
consumer `docs/adr/` file numbered below 100, or any other template-owned path it has
no merge rule for. Any refusal stops it before anything is written — **consumer
content is never deleted**. `README.md` and `LICENSE` are never touched, in either
direction.

On success it opens a tracking issue, checks out a new branch
(`wip/<id>-adopt-t-workflow`) from the trunk, and commits the merged tree there —
**it never pushes, opens a PR, or changes any forge-wide setting.** It prints the
push and draft-PR commands on exit, plus `/t-plan` and `/t-review`: from the moment
that branch exists, the checkout already carries every skill, script, and adapter the
pipeline needs, so those run against it exactly like any other protected task's plan
and review — the trunk only gains the pipeline once that PR is reviewed and merged
(`docs/architecture/adoption.md`; `CONSTITUTION.md` §3, ADR-011). Once it merges, run
`.t-workflow/scripts/github-bootstrap.sh` yourself — a separate step a human confirms
deliberately, never run by `adopt.sh` itself, because it changes settings (merge
strategy, delete-branch-on-merge, branch protection) that affect everyone with access
to the repository, and an existing team already has habits around them that a tree
edit should not silently override.

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
It also does not assume the trunk is called `main`: the skills and scripts resolve the
real trunk name at run time (`.t-workflow/scripts/trunk-ref.sh`), and
`.github/workflows/ci.yml`'s push trigger names it in its own local slot
(`docs/architecture/local-slots.md`) rather than writing it in literally — a repo on
`master` or `trunk` fills that one slot with its own name instead of a repo-wide
find-and-replace.
