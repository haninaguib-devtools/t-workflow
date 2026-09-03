# 124 — Resolve the project's actual trunk instead of hardcoding `main` in skills and scripts

Issue: #124

## Asked
Every skill and script in this template assumes the repository's trunk branch is
literally named `main`, written directly into `git` and `gh` commands. A project whose
default branch has a different name (for example `master`) breaks silently: a check
against `origin/main` fails because that ref does not exist, and every such failure
already resolves to a safe "not landed" / "not clean" outcome rather than a visible
error, so nothing tells anyone something is wrong. The application built from this
template hit this exact problem in its own engine (issue #582) and fixed it with
ADR-108: `WorktreeCreationService.trunkRef(ProjectRecord)` resolves the project's
recorded default branch, falling back to `main` only when none is recorded. This task
applies the same idea to the template's own skills and scripts, which never got the
equivalent fix.

## Done when
- A single shared resolver (e.g. a new `.t-workflow/scripts/trunk-ref.sh`) determines
  the repo's actual trunk — for example via `git symbolic-ref refs/remotes/origin/HEAD`,
  falling back to `main` only if that lookup fails — and is the one place that fallback
  is written.
- Every literal `main` / `origin/main` used as a git ref across `.claude/skills/` and
  `.t-workflow/scripts/` calls that resolver instead of hardcoding the name. A grep for
  `origin/main` and bare `main` as a ref across those directories turns up only the
  resolver's own fallback line.
- Skill prose that names `main` directly as if it were the only possible trunk (e.g.
  "never against `main`" in `t-ship`, `t-drive`, `docs/adapters/FORGE.md`) is reworded
  to say "the project's trunk" instead.
- Verified against a checkout whose default branch is not `main` (e.g. `master`): the
  affected skills and scripts follow the resolved name instead of failing or silently
  misbehaving.
- `.t-workflow/scripts/consistency-check.sh` still passes.

## Explicitly not
- Does not introduce a second branch tier (e.g. a `develop` branch) between task
  branches and the trunk.
- Does not add a release branch distinct from the trunk.
- Does not touch the Java engine's `WorktreeCreationService` /
  `WorktreeCleanupSweeper` — already fixed there by ADR-108.
- `.claude/skills/l-release/SKILL.md`, `scripts/release.sh`,
  `scripts/generate-release-notes.sh`, `scripts/build-inputs.sh` — named in the issue's
  Scope but do not exist in this repository (confirmed by `find` over the tree); `l-release`
  is a consumer-local skill per `AGENTS.md`'s own reserved note, added by a downstream
  repo, not shipped by this template. Nothing to change here.

## Decisions made along the way
- Plan added a one-line `AGENTS.md` edit beyond the issue's declared Scope — the
  §Conventions sentence stating the trunk name "is not abstracted the way the tracker
  and forge are" directly contradicts this task's own resolver once it ships. Flagged in
  the `/t-plan` report for human sign-off (t-drive session, 2026-09-03).

## Deviations / notes
- none yet
