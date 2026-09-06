# 146 — Define a project preview adapter contract
Issue: #146 · Part of: #139

## Asked
Define a generic contract through which a project can publish a reviewable version of a
draft task branch. t-workflow should describe the inputs and evidence expected while
leaving deployment technology and hosting entirely to the consuming project.

## Done when
- The contract identifies the task, branch, commit, and draft PR supplied to a preview
  provider.
- Preview evidence can report its type, status, revision, review URL, instructions,
  expiry, and failure reason.
- Evidence is tied to an exact commit.
- The contract supports non-web previews, including packages, binaries, images,
  environments, or manual installation instructions.
- A project can implement the contract in its local workflow slots without editing
  template-owned workflow files.
- The documentation explains how preview success differs from human verification
  success.
- Draft PRs continue to skip final merge CI unless a project deliberately defines
  separate preview automation.
- No particular deployment platform, container system, or cloud provider is assumed.

## Explicitly not
- Building a preview service.
- Shipping a Docker- or Kubernetes-specific deployment.
- Requiring every consumer project to provide previews.
- Running final merge CI on every draft-PR update.

## Origin
none

## Verification
none — this task's own plan declares no `verification:` entries.

## Feedback
none — no feedback pass has run against this task itself.

## Decisions made along the way
- **No new ADR** (haninaguib, via the driving session, 2026-09-06): the issue's Scope
  line omits `docs/adr/`, and ADR-010 (already merged into this integration branch)
  already licenses this task to draw the §D2/§D7 boundary concretely for the preview
  case; `docs/architecture/verification.md`'s own Non-goals already deferred "how a
  project deploys a preview" to this task by number. A documentation-and-checks task
  that loosens no gate needs no ADR-grade rationale of its own.
- **No skill file changes** (`t-work`, `t-plan`, `t-review`, `t-ship`, `t-drive` all
  untouched): the issue's Scope line ("adapter documentation, local extension points,
  example evidence shape, and contract checks") and Non-goals ("building a preview
  service", "running final merge CI on every draft-PR update") together rule out wiring
  this contract into any existing gate. `docs/adapters/PREVIEW.md` documents a contract
  no skill invokes yet — the same way `TRACKER.md`/`FORGE.md` document `tracker:*`/
  `forge:*` operations the skills *do* call, except this one has no caller inside this
  repository today; a future task that wires a preview-evidence type into the
  `verification:` schema's `evidence` field reads this document rather than repeating
  its shape.
- **No new local slot**: Done-when's "local workflow slots" requirement is satisfied by
  documenting the existing slots `docs/architecture/local-slots.md` already names
  (chiefly `.github/workflows/ci.yml`'s trailing `steps:` slot, or a project's own
  separate workflow file for a preview trigger that must run on draft-PR pushes too) —
  not by inventing a ninth slot for a mechanism this task builds no automation for.
- **Preview-evidence schema kept generic on purpose**: `type` and `instructions` stay
  free text rather than a closed enum, so a project can name a preview kind this
  document never anticipated (Done-when: "environments") without a template change.
  `status` is a closed, small vocabulary (`pending`, `ready`, `failed`, `expired`) —
  deliberately distinct wording from verification's `pending`/`verified`/`rejected`/
  `risk-accepted`, so the two can never be typo-confused into meaning the same thing:
  a `ready` preview is a fact about the software running, never a resolved verification
  entry (ADR-010 §D4; `docs/architecture/verification.md`).
- **`check-preview-evidence.sh` validates shape only, and is wired into no gate**:
  matches `check-verification-gate.sh`'s pure, fixture-testable style, but unlike that
  script this one is never called by `/t-ship`, `/t-review`, or CI — Done-when never
  asks for a shipping gate here, and Non-goals rule out requiring every project to
  supply evidence at all. It exists so a project's own tooling (or this repo's own
  `plumbing-test.sh`) can check a preview-evidence object against the contract before
  trusting it, exactly the way `docs/adapters/PREVIEW.md`'s own worked example is
  checked.

## Deviations / notes
- Noted at plan time (`/t-plan 146`'s report): concurrently open siblings #142 ("Allow
  t-drive to stop before shipping") and #145 ("Add a feedback implementation pass to
  t-work") touch `/t-drive`, `/t-work`, and their own documentation, neither naming
  `docs/adapters/` or a new `check-*.sh` script — no path collision expected except
  `.t-workflow/scripts/plumbing-test.sh`, which every new check script (this one
  included, following #144's own section 17) appends a fixture section to. Flagged for
  whichever PR merges into `wip/139-integration` later to resolve as a trivial
  append-only conflict, not a scope violation.
