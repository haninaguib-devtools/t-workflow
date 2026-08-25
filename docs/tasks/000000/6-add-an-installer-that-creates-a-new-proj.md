# 6 — Add an installer that creates a new project from the template in one command

Issue: #6

## Asked

Starting a project from this template is a manual checklist today: copy the repo, delete
its history, fill in placeholders, commit, push, run a bootstrap script. Steps can be
skipped or done out of order, and the result looks right while missing something. Replace
that checklist with one command a person pastes into a terminal, the way Homebrew is
installed. It asks for a project name, creates a directory with that name, puts the
workflow skeleton inside it, and — unless told not to — creates the GitHub repository and
applies the repository settings. What comes out is ready for `/t-open`, minus the two
things no installer can know: the stack constraints and the build/test command.

Everything the installer needs lives under a new `installer/` directory, so removing it
from a generated project is one `rm -rf`.

## Done when

- `installer/install.sh` is the fetched entry point: it shallow-clones this repository to
  a temporary directory and hands off to `installer/bootstrap.sh` from inside that clone.
- `installer/bootstrap.sh` holds the real logic.
- `bash installer/install.sh --name demo --no-remote` in an empty directory creates
  `demo/` and exits 0 with no prompts; every prompt has a matching flag; `--help` lists
  them.
- Every interactive prompt reads from `/dev/tty`, so `curl -fsSL <url> | bash` can still
  ask questions.
- In a project generated as `demo/`: `demo/installer` and `demo/LICENSE` do not exist;
  `demo/.git` is a fresh repository with exactly one commit; `demo/CLAUDE.md`,
  `demo/GEMINI.md`, `demo/.agents/skills` and `demo/.github/copilot-instructions.md` are
  still symlinks; `demo/README.md` comes from `installer/templates/README.md` and carries
  a line matching `Generated from t-workflow @ [0-9a-f]\{7,\}`; `demo/docs/tasks/` holds
  only `TEMPLATE.md` and `README.md`; `cd demo && ./scripts/consistency-check.sh` exits 0.
- `CONSTITUTION.md` §4 and `AGENTS.md` §Checks ship unfilled, and the installer prints on
  exit exactly what must be filled and that no LICENSE was created.
- Without `--no-remote` the installer offers to create the GitHub repository and run the
  generated project's `scripts/github-bootstrap.sh`; declining, or `gh` being absent or
  logged out, leaves a valid local project and printed instructions — never a hard
  failure.
- `installer/test.sh` asserts the generated-project list above, matching the provenance
  line by shape rather than by value.
- `.github/workflows/ci.yml` gains a job running `installer/test.sh`; the `consistency`
  and `record` job names are unchanged.
- `scripts/protected-paths.sh` protects `installer/*`, `CONSTITUTION.md` §3 names
  `installer/`, and `bash scripts/protected-paths.sh installer/bootstrap.sh` exits 0.
- `CONSTITUTION.md` §3's genesis exception recognises the installer as a way to perform
  genesis, still ending at the first pushed commit.
- `README.md` §Bootstrapping leads with the one-line install command and keeps the manual
  steps as fallback; §License states the MIT licence covers this template and that
  generated projects ship with no LICENSE; the file inventory mentions `installer/`.

## Explicitly not

Boundaries, not deferred work — none are planned, and each becomes its own issue only if
the project later decides it wants it.

- No tracker/forge choice at install time. `docs/adapters/` describes GitHub and only
  GitHub; a prompt offering choices that do not exist would be a lie.
- No releases, tags, or version pinning. The installer clones `main` and records the
  commit hash. Accepted cost: a broken push to `main` breaks installs until fixed,
  mitigated by `installer/test.sh` in CI.
- No custom domain for the install URL; it points at `raw.githubusercontent.com`.
- The installer never invents project content — it does not fill `CONSTITUTION.md` §4,
  `AGENTS.md` §Checks, or add a CI job for a build command.
- No update or upgrade path for an existing generated project.
- `scripts/github-bootstrap.sh` is out of scope, so the new CI job is advisory rather than
  a required status check (decision below).

## Decisions made along the way

- (human, 2026-08-24, at `/t-plan`) The installer CI job stays **advisory**, not a
  required status check. Making it required means editing `scripts/github-bootstrap.sh`,
  the only place that names required contexts, which would widen the scope #6 declared.
  The job still runs on every pull request and shows red on failure; branch protection
  simply does not block a merge on it. Making it required is a separate task if wanted.
- (human, 2026-08-24, in the design conversation) The generated project gets **no LICENSE
  file at all**. Since the installer copies this repository's tree, `LICENSE` arrives
  whether or not it is wanted, so the installer actively deletes it — otherwise every
  generated project would silently ship MIT under this repository's copyright holder.
  A project with no LICENSE is "all rights reserved" by default, which is the safe
  starting point; the owner chooses their own licence as ordinary pipeline work.
- (human, 2026-08-24, in the design conversation) The generated project also has
  `installer/` deleted: a new project does not ship the thing that made it.
- (human, 2026-08-24, in the design conversation) Provenance is recorded as the short
  commit hash rather than a release tag, because no release process exists yet. This
  replaced an earlier suggestion to clone a tag. The provenance line is shaped so a tag
  can be added later without moving it.
- (agent, 2026-08-24) `installer/` is split into a small fetched entry point
  (`install.sh`) and the real logic (`bootstrap.sh`). What `curl` fetches must be one
  self-contained file, but the installer clones the whole repository anyway, so every
  supporting file is available after the clone. Keeping the entry point tiny also keeps
  its public URL stable.
- (agent, 2026-08-24) The generated tree is produced by moving the clone's working tree
  and deleting `.git`, rather than by copying file by file. This preserves the four
  symlinks exactly, which a copy that follows symlinks would silently destroy.

## Deviations / notes

- The generated project keeps the `installer/*` pattern in `scripts/protected-paths.sh`
  and the `installer/` bullet in its `CONSTITUTION.md` §3, even though the directory was
  deleted. This is deliberate: `scripts/consistency-check.sh` check 9 compares a spelling
  against a decision and never tests existence, so the generated tree still passes; and a
  project that later grows an installer of its own is protected by default. Having the
  installer mechanically edit two protected files to strip the rule would be fragile and a
  partial edit would break check 9 for the new project's owner.
