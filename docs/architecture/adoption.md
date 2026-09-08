# Adopting t-workflow into an existing repository

**Status:** binding design decision (initiative #168, task #166). Settles the shape of
an `installer/adopt.sh` mode and the rule changes it needs, so the follow-up
implementation tasks (#169–#174) can be built against one agreed spec rather than each
guessing the shape on its own. Merging this document is the act of deciding
(`docs/workflow.md` §7) — the follow-ups carry the actual code, constitution wording,
and site copy; nothing here changes any file outside itself.

## Why this exists, in plain terms

Today the delivery system only knows how to arrive at the very start of a project: the
installer refuses to run against a directory that already has something in it, and the
by-hand route in `README.md` begins with `git init`. A team that already has code,
history, and a working repository has no supported door in. The obvious workaround —
copying the template's files in by hand — breaks the very rules it is trying to
install, because there is no tracker issue, no branch, and no reviewed PR behind the
copy. This document answers, with a decision and rationale for each, the six questions
that block a clean retrofit, and ends with the list of follow-up tasks the decisions
imply.

**The short version:** adopting t-workflow into an existing repository is ordinary
work, not a second genesis. A person runs one command inside their repository. It
figures out what can be merged automatically and what needs a human's judgment, refuses
cleanly on the latter, and leaves behind a normal draft pull request — planned,
reviewed, and merged exactly the way any other protected change is — that a human
reviews before anything lands on their trunk. Nothing about how the *rest* of the
pipeline works changes because of this.

## 1. Which rule lets the adoption change land?

**Decision: no constitutional exception is created for adoption. It lands through the
same rule that already lets `/t-update` change every template-owned file in a pinned
consumer — an ordinary protected task, with a plan, a record, and an independent cold
review, run from the adoption branch itself.**

The apparent problem is a chicken-and-egg one: the diff that adoption produces *is* the
skills, the adapters, the scripts, and the CI gates the pipeline needs to process a
task — so how can the pipeline process the task that adds them? The answer is that
nothing about running `/t-plan` or `/t-review` requires those files to exist on the
*trunk* — only on the checkout the session is reading from. `installer/adopt.sh` writes
the whole template tree onto a task branch (`wip/<id>-adopt-t-workflow`) *before* a plan
or review ever runs; from that point on, the checkout has every skill, script, and
adapter the pipeline needs, and `/t-plan <id>` and `/t-review <id>` run against it
exactly as they would for any other task. The trunk only gains those files once the
adoption PR is reviewed and merged — the same as any other change. There is no moment
where the pipeline is asked to process a diff it cannot read.

`CONSTITUTION.md` §3's genesis exception was considered and rejected as the vehicle.
Three reasons, each independently sufficient:

- The exception's own text already forecloses this: it "never covers a second round of
  'just this once'" and belongs only to "the repository being *created*," never to
  "work on the tooling that creates one." An existing repository already had its
  genesis — reusing the same exception for a second, later event is exactly the "second
  round" the text rules out, not a natural extension of it.
- It is unnecessary, per the chicken-and-egg resolution above: the adoption branch
  carries everything the pipeline needs before any pipeline stage runs against it, so
  there is no gap the exception would need to bridge.
- `/t-update` is the working precedent for "change every template-owned file in a
  consumer repo" and already does it as an ordinary protected task with no exception of
  its own (`docs/architecture/manifest.md`). Adoption is `/t-update`'s first sync,
  arriving by a different door (a script that also builds the initial manifest, rather
  than one that reads an existing one) — treating it as a special case would be an
  inconsistency to defend, not a simplification.

**Does landing this decision need a constitutional amendment via ADR?** In the narrow
sense, yes, but not the amendment the initiative's own starting proposal floated.
`CONSTITUTION.md` §3's genesis paragraph currently reads as though the only way into
the pipeline is before a repository's first commit; leaving it unedited would keep
inviting exactly the reading this document rejects. The fix is one clarifying sentence
in that paragraph — pointing at adoption as ordinary work, changing neither the
exception's own wording nor its stated end-point — never a widening of what the
exception itself covers. `CONSTITUTION.md` changes only by PR at the heightened bar,
"normally alongside an ADR" (`CONSTITUTION.md` §Amendment), so that one sentence rides
with a new ADR recording this decision, its rejected alternative (extending the genesis
exception), and its revisit triggers. Both land together in the follow-up task that
owns constitution wording (see §Follow-up tasks below) — this document does not add the
sentence or the ADR itself, per its own Scope.

## 2. Collision rules — what `installer/adopt.sh` does on each existing file

The script computes its whole plan — one decision per template-owned path: add, merge
by rule, rename, or refuse — before writing a single byte, and prints it.
`--dry-run` stops there. Any refusal aborts before anything is written, listing every
collision at once rather than stopping at the first. **Consumer content is never
deleted**, by construction: every rule below either adds a new file, folds existing
content into a marked local slot the template already reserves for per-repo content
(`docs/architecture/local-slots.md`), or refuses and leaves the tree untouched.

| What's found | What `adopt.sh` does |
|---|---|
| A real `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, or `.github/copilot-instructions.md` (a regular file, not the template's symlink) | Moves verbatim into `AGENTS.md`'s project-notes local slot (§169 below), under a heading naming which file it came from. Several such files present at once are all concatenated the same way, each under its own heading — nothing is summarized or reworded. The aliases then become the template's own symlinks, same as a generated project. |
| An existing `.gitignore` | Its whole content goes into the template `.gitignore`'s own trailing local slot (`docs/architecture/local-slots.md`), verbatim, appended after the template's own entries. |
| An existing `.github/workflows/ci.yml` | Renamed (to a fixed name the implementing task picks) so it keeps running unmodified; folding its build step into the template workflow's own trailing slot is listed in the generated task record as the consumer's own follow-up, never attempted automatically — merging two CI files' semantics is exactly the kind of judgment call this script does not make for a person. |
| Existing `.claude/` content | Kept as-is. The only refusal inside this directory is a skill directory literally named `t-*` — that name is reserved for the pipeline's own skills, and a consumer's existing skill sharing it cannot coexist without a person choosing which one wins. Everything else under `.claude/` (a consumer's own non-`t-*` skills, `settings.json`, `agents/`) is left exactly where it is. |
| Existing `docs/adr/` | Coexists. Refuses only when a consumer file's own number matches the template's `NNN-` prefix range **below 100** (`docs/architecture/local-slots.md` §Consumer ADR numbering already fixes 000–099 as template-owned and 100+ as a consumer's own) — the refusal message says exactly that and tells the person to renumber their colliding files to 100 and up before retrying. A consumer already numbering locally at 100+ collides with nothing and needs no changes. |
| Any other template-owned path already present (per `.t-workflow/scripts/template-owned-paths.sh --list` at the target tag) that this table does not name a merge rule for | Refusal. The script never guesses at a merge it has no rule for. |
| `README.md`, the consumer's `LICENSE` | Never touched, in either direction. A generated project stamps `README.md` at genesis and deletes the template's `LICENSE`; an adopted one already has both, doing whatever it already did, and adoption does not start managing either. |

Two fills happen alongside the merges above, both mechanical, never a "collision" in
the refuse/merge sense: the detected trunk name goes into `ci.yml`'s trunk-name local
slot (§170 below), and the check-manifest CI step goes into `ci.yml`'s trailing local
slot the same way a generated project's does; the build/test command goes into
`AGENTS.md` §Checks item 1 only when the person running the script supplies it with a
flag — the script never infers a build command from what it finds in the repo.

## 3. CI gate behavior on non-task branches after adoption

**Decision: the gates land strict, exactly as a generated project's do — no warn-only
mode.** A pull request whose head branch is not shaped `wip/<id>-<slug>` fails the
record/plan/title checks the moment the adoption PR merges, the same as it always has
for a generated project. This is true of any pre-existing open PR, a Dependabot- or
Renovate-style branch, or a teammate's habitual branch name — they go red because they
genuinely do not carry what the pipeline now requires, not because of a bug.

The rollout lever is **not** in the tree: `.t-workflow/scripts/github-bootstrap.sh` — squash-only
merges, delete-branch-on-merge, branch protection making the new checks required — is a
separate, explicitly confirmed step run only after the adoption PR itself has merged
(§5 below). Before that script runs, the new CI workflow reports red or green on a PR
but blocks nothing, because nothing on the forge yet requires it to pass; a
pre-existing PR stays mergeable in that window. Once the team runs
`github-bootstrap.sh`, the requirement becomes real for everyone at once, on their own
schedule, and only when they are ready for it. The initiative's own starting proposal
floated a warn-only mode built into the workflow file itself (a `continue-on-error`-style
softening) — rejected, because it is a second, tree-based on/off switch duplicating what
branch protection already gives for free, and because a warn-only gate that a person
must remember to later tighten is exactly the kind of guardrail
`CONSTITUTION.md` §1.5 warns against building softly in the first place.

## 4. ADR numbering across an existing decision log

No new rule is needed here — `docs/architecture/local-slots.md` §Consumer ADR numbering
already fixes the answer for exactly this situation, decided before this initiative
existed: the template owns ADR numbers **000–099**; a consumer's own ADRs start at
**100**. `adopt.sh`'s refusal in §2 above (a consumer ADR file numbered below 100
collides) is this existing rule applied at adoption time, not a new one invented for
it. A consumer whose own decision log already started at 100 or higher — the numbering
this document recommends for anyone starting fresh — collides with nothing.

## 5. When does `github-bootstrap.sh` run?

**Decision: it stays a separate, explicitly confirmed step, run by a human after the
adoption PR has merged — never invoked by `adopt.sh` itself.** The script changes
forge-wide settings that affect everyone with access to the repository at once: merge
strategy, delete-branch-on-merge, branch protection contexts, labels. For a brand-new
generated project nobody has habits to disrupt yet, so `README.md`'s bootstrapping flow
already treats it as a distinct step the person runs when ready, not something
`bootstrap.sh` folds into itself. An existing team's repository already has merge
habits, branch protection, and possibly rulesets of its own; changing those is a policy
decision for the team, not a mechanical step that should happen silently as a side
effect of a tree edit. `adopt.sh` prints the exact command on exit, the same way it
prints the push and draft-PR commands — naming the next step is the whole of what it
does at that boundary, per `docs/architecture/manifest.md`'s adjacent precedent, and
per `AGENTS.md` §Conventions' "nothing chains automatically" rule applied to the
adoption script's own boundary with the forge.

## 6. Becoming a pinned consumer

**Decision: `adopt.sh` writes `.template-manifest.json` directly, computed at the
target release tag — it never goes through `/t-update`'s existing first-adoption path,
and `README.md`'s provenance line is not written and not needed.**

`docs/architecture/manifest.md` already defines two ways a consumer's identity gets
established: a manifest written directly (the ordinary case, kept current release over
release), or, when no manifest yet exists, `/t-update` reading a `Generated from
t-workflow @ <ref>` line `installer/bootstrap.sh` stamps into `README.md` at genesis to
infer one. Adoption uses the first path, not the second, because the second exists only
to cover a gap this script does not have: `adopt.sh` already knows exactly which
template repository and tag it is applying — it just cloned it into the scratch clone
its plan is computed from — so there is nothing for the provenance-line inference to
recover that the script does not already know first-hand. Writing the manifest
directly also means `README.md`, which §2 above already leaves untouched, never needs
the sentence in the first place.

Concretely, per `docs/architecture/manifest.md`'s existing shape: `template` is the
template repository (`owner/name`) `adopt.sh` was pointed at; `tag` is the release tag
`--ref` named (never a branch — `adopt.sh`'s own preconditions refuse a non-tag `--ref`
outright, because the manifest's whole point is pinning to something that does not move
underneath a later `/t-update`); `migrations_applied` is set to that tag's own highest
migration number (`docs/architecture/migrations.md`), on the same reasoning
`/t-update` already uses for a fresh sync target — a repository adopting *at* a tag has
implicitly already "applied" every migration that shipped at or before it, there is
nothing left for a later `/t-update` to replay; `files` is every template-owned path at
that tag, each mapped to the **normalized** hash `.t-workflow/scripts/check-manifest.sh
--hash-file` computes for it (`docs/architecture/manifest.md` §Normalized hashing) —
the same hashing rule and the same script a generated project's first manifest write
and every later `/t-update` both already use, so adoption introduces no second way to
compute a hash.

From the moment that manifest is committed on the adoption branch, the repository is an
ordinary pinned consumer in every sense `docs/architecture/manifest.md` already defines:
`.t-workflow/scripts/check-manifest.sh` in its own CI (once wired up, per §3 above)
verifies it the same way, and the next `/t-update` moves it forward the same way, with
no special-cased "first adoption" branch to fall into — that branch exists in
`/t-update`'s procedure for exactly one situation (no manifest and no explicit
`--template`/`--ref`), and `adopt.sh` never leaves a repository in that situation.

## Follow-up tasks

Six tasks already exist as fully-specified sibling issues under this initiative,
opened alongside this one rather than minted from this document after the fact
(`/t-open` mints from a document only when the follow-ups were not already known at
the point of writing it — here they were, and are listed below as the answer to that
requirement rather than a second list being drafted). Each is consistent with the
decisions above; none is opened by this task or this document — `/t-open` already
opened them, and each proceeds only when a human names it (`AGENTS.md` §Conventions).

- **#169 — Add a project-notes local slot to `AGENTS.md`.** The destination §2's
  `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` collision rule moves consumer content into.
- **#170 — Make `ci.yml`'s push-trigger trunk name a local slot.** What §2's trunk-name
  fill (and a non-`main` consumer generally) lands in.
- **#171 — Share the consumer exclusion set between `bootstrap.sh` and the adoption
  script.** The refactor that gives `adopt.sh` a single source of truth for "what a
  template clone strips before it becomes a consumer tree," reused rather than
  duplicated from `installer/bootstrap.sh`.
- **#172 — Add `installer/adopt.sh` to retrofit t-workflow into an existing
  repository.** The implementation of §§1–2, 5–6 above: preconditions, the plan/refuse
  computation, the collision rules, the manifest write, the record and draft-PR
  hand-off. Blocked on the three tasks above plus this one.
- **#173 — State that adoption is an ordinary task in the constitution, README,
  `AGENTS.md`, and an ADR.** Carries the one clarifying sentence in `CONSTITUTION.md`
  §3 and the new ADR §1 above requires, the `README.md` adoption section, and the
  `AGENTS.md` §Conventions clause naming `adopt.sh` on the adoption branch as that
  task's own work stage.
- **#174 — Update the site's Adopt section for existing repositories.** The
  non-protected, optional follow-up presenting both routes on the project site.

No additional follow-up beyond these six is implied by the decisions above.
