# 172 — Add installer/adopt.sh to retrofit t-workflow into an existing repository
Issue: #172 · Part of: #168

## Asked
Let a person retrofit t-workflow into a repository that already has code, history, and a
team, with one command run inside that repository. `installer/adopt.sh` writes the
delivery system at a pinned release tag onto an adoption task branch, merging with what
is already there only where that is mechanical and lossless, refusing with a complete
list where a merge would need judgment, and leaves behind a pinned template consumer
with an adoption PR to plan, review, and merge like any other protected change
(initiative #168; `docs/architecture/adoption.md` from #166 is the binding spec — where
this issue and that document disagree, the document wins).

## Done when
- `installer/adopt.sh` exists with `--help` documenting every flag, bash 3.2 compatible
  like its siblings.
- `installer/test.sh` covers: a happy path into a fixture repository with a real
  `CLAUDE.md`, its own `.gitignore`, its own `ci.yml`, and a non-colliding `docs/adr/`,
  asserting the manifest validates, `consistency-check.sh` exits 0 there, the record
  exists in the right bucket, no consumer content was lost, and nothing was pushed; a
  refusal path for each refusing class (a `t-*` skill, a colliding ADR number, an
  existing `CONSTITUTION.md`) asserting nothing was written; `--dry-run` writing
  nothing; and a non-`main` trunk landing in the slot.
- The tracker write in tests is stubbed or pointed at a throwaway, never at this
  repository.
- The record states the one external fact the design relies on and how it was
  verified: GitHub evaluates a pull request's workflow file from the PR head when the
  base has none.
- `./.t-workflow/scripts/consistency-check.sh` exits 0.
- A cold review (`/t-review`) reports `readiness: ready` — `installer/` is a protected
  surface (`CONSTITUTION.md` §3).

## Explicitly not
- Constitution, README, `AGENTS.md`, and ADR wording — split to #173.
- The site's Adopt section — split to #174.
- Running `github-bootstrap.sh`, pushing, or opening the PR from the script.
- Folding a consumer's existing CI steps into the template workflow's slot — a
  judgment merge left to the consumer, named in the generated record.
- Any forge other than GitHub.
- Adding a mention of `adopt.sh` to `install.sh --help` — the entry point never came to
  need one; `install.sh` is untouched.

## Origin
none

## Verification
none

## Feedback
none

## Decisions made along the way
- **adopt.sh is self-contained, not split like install.sh/bootstrap.sh** (this
  session, 2026-09-08): install.sh clones the template then hands off to
  bootstrap.sh because it builds a *new* directory from scratch. adopt.sh instead
  merges into the *existing* checkout it is run from, so one script does the argument
  parsing, the clone, the plan, and the merge — there is no fresh-directory hand-off
  to split across two files.
- **Trunk detection uses `gh repo view`, not `origin/HEAD`** (this session,
  2026-09-08): `.t-workflow/scripts/trunk-ref.sh` does not exist in the target repo
  until this very run adds it, and an existing clone's `origin/HEAD` symref is not
  guaranteed set. `gh repo view --json defaultBranchRef` is authoritative and already
  required by the "logged-in gh" precondition — the same reasoning
  `.t-workflow/scripts/github-bootstrap.sh` already uses at genesis.
- **The rename target for a consumer's own `ci.yml` is `.github/workflows/ci-legacy.yml`**
  (this session, 2026-09-08): `docs/architecture/adoption.md` leaves the exact name to
  the implementer; `ci-legacy.yml` reads clearly and sits beside the template's own
  file.
- **`--template <owner/name>` is a new flag, not implied only by `--source`**
  (this session, 2026-09-08): `docs/architecture/manifest.md`'s `template` field needs a
  real `owner/name`, which a `--source` pointing at a local path (used for testing, and
  potentially for an internal mirror) cannot supply on its own. Parsed automatically
  from a `github.com` URL; required explicitly otherwise.
- **The manifest's per-file hashes are computed after every file is already written**
  (this session, 2026-09-08): `.t-workflow/scripts/check-manifest.sh --hash-file` must
  exist in the target tree to call, which is only true once the generic-add pass has
  already copied `.t-workflow/scripts/*` into place — so the manifest write is the very
  last step before the record and the commit.
- **A pre-existing, out-of-scope defect surfaced by testing this end-to-end** (this
  session, 2026-09-08): `CONSTITUTION.md` §3 cites `README.md §Bootstrapping` three
  times. `consistency-check.sh`'s named-section check (§2b) resolves that citation
  against whatever `README.md` is actually present — and `adopt.sh` deliberately never
  touches `README.md` (`docs/architecture/adoption.md` §2: "never touched, in either
  direction"). A real team's own pre-existing `README.md` essentially never carries a
  heading named "Bootstrapping", so `consistency-check.sh` — required check 2, wired
  into every consumer's own CI — fails in **every real adoption** until it does. This is
  a gap in the adoption design this task inherited, not something `installer/` can fix:
  `CONSTITUTION.md` is outside this task's scope (`installer/` only) and is itself a
  protected surface requiring its own plan and review. `installer/test.sh`'s happy-path
  fixture works around it by giving its own `README.md` a `## Bootstrapping` heading, with
  a comment explaining why — the mechanics under test (the plan/merge/refuse logic) are
  what the fixture exists to exercise, not this separate, already-flagged defect.
  **Recommended follow-up** (proposed here, not opened — `AGENTS.md` §Conventions):
  either loosen `CONSTITUTION.md` §3's wording so it no longer requires an adopted
  repository's own README to carry that heading, or give `adopt.sh` a narrower,
  explicitly-scoped exception to append a minimal `## Bootstrapping` stub to an
  adopted repo's README pointing at the printed next steps. Likely belongs with #173's
  `CONSTITUTION.md` wording change, or as its own follow-up task.
- **The external-behaviour claim was verified empirically, not just documented**
  (this session, 2026-09-08): the design's own §5 relies on "GitHub evaluates a pull
  request's workflow file from the PR head when the base has none." GitHub's own docs
  are ambiguous/contradictory on this point across different pages (one page's generic
  "workflow must exist on the default branch" language does not describe `pull_request`
  specifically). A real, throwaway private repository was created
  (`github.com/haninaguib/tworkflow-ci-verify-throwaway`) with two branches: `main`
  carrying no workflow file at all, and `test-branch` adding a `.github/workflows/probe.yml`
  with an unconditional `pull_request` trigger — nowhere else in the repository's history.
  A PR from `test-branch` to `main` was opened (PR #1), and `gh api
  repos/haninaguib/tworkflow-ci-verify-throwaway/actions/runs` showed the `probe`
  workflow ran and completed successfully (`event: pull_request`, `conclusion:
  success`) for that same PR — confirming the claim: a workflow introduced only on a
  PR's head branch does run for that PR, even though the base branch has no such file.
  This is why the newly-added `ci.yml` gates the adoption PR itself, per
  `docs/architecture/adoption.md` §3. **The throwaway repository is still private and
  still exists** — this agent's `gh` token lacks the `delete_repo` scope
  (`gh auth refresh -s delete_repo` was not run, since scope changes are outside this
  task and were not asked for) — a human should delete
  `github.com/haninaguib/tworkflow-ci-verify-throwaway` when convenient.
- **Test fixtures build "the template at `--ref`" from this checkout's own committed
  HEAD, never the public tag** (this session, 2026-09-08): the plan's own Risks section
  flagged that the public template's latest tag (`v0.1.1`) predates #166/#169/#170/#171,
  so a real run against the published default would not see this initiative's own
  changes. `installer/test.sh` already stages a throwaway bare repository
  (`$work/source.git`) from this checkout's committed `HEAD` for the existing
  `install.sh` tests; this task's own fixtures reuse that same bare repository and add
  one more ref to it — `refs/tags/adopt-fixture-tag`, pointing at the same commit — so
  `adopt.sh --ref adopt-fixture-tag --source "$srcrepo"` clones a real tag carrying
  every merged change, entirely offline. A fresh public tag still needs cutting before
  `adopt.sh`'s own *default* `--ref` (no `--source`/`--ref` given at all) is genuinely
  exercisable end-to-end against the public repository — unchanged from what the plan
  already flagged, and not something this task can resolve (release cuts are a
  maintainer's own manual step, `docs/architecture/manifest.md`).
- **Test safety: the tracker write is fully stubbed, not merely pointed at a
  throwaway** (this session, 2026-09-08): `installer/test.sh` prepends a fake `gh`
  executable to `PATH` for every `adopt.sh` invocation under test. It never shells out
  to the real `gh` and never touches the network for any subcommand `adopt.sh` calls
  (`auth status`, `repo view`, `issue create`, `issue view`, `issue edit`) — so no code
  path in `installer/test.sh` can reach `haninaguib-devtools/t-workflow`, or any other
  real repository, regardless of what `adopt.sh` itself does. A separate log file
  records every `issue create` the fake actually received; the refusal and `--dry-run`
  tests assert that log stays empty, proving — not merely claiming — that a refused or
  dry-run adoption never reaches the tracker at all (by construction: `adopt.sh` itself
  only calls `gh issue create` after the plan has already been printed with no
  refusals and `--dry-run` was not given).

## Deviations / notes
none
