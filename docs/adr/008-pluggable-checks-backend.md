# ADR-008: A pluggable CHECKS backend, alongside the tracker and forge adapters

**Status:** Accepted · 2026-08-30
**Deciders:** project owner *(solo phase; queued for review alongside ADR-001–007 if a
second maintainer joins — workflow §13 Q9.)*

## Context

Issue #102, a design child of #93 (cutting the generated pipeline's CI cost and
latency). Even after #93's other children land, every check the pipeline runs —
`consistency`, `record`, `plan-gate`, `title-gate`, `blockers`, `cold-review`,
`plumbing-test`, and eventually the project's build — still executes on a hosted GitHub
Actions runner, billed against the repo's Actions minutes. #93's own measurement on a
real consumer (locklane) put this at roughly 15,600 Actions-minutes/month at observed
task throughput — past what GitHub includes on a private repo below Enterprise, for
checks whose real work is a few seconds each.

`CONSTITUTION.md` §1.3 already establishes that the tracker and the forge are mechanical
choices, documented in `docs/adapters/` and swappable by editing those files alone —
nothing in the constitution ties checks specifically to GitHub Actions. GitHub branch
protection's required-checks mechanism accepts a commit status posted from anywhere via
the Statuses API, not only one produced by an Actions workflow run — so the remaining
fix is to make *where* checks run a third pluggable choice, on the same footing as
`docs/adapters/TRACKER.md` and `docs/adapters/FORGE.md`.

## Decision

### D1. `docs/adapters/CHECKS.md` joins `TRACKER.md`/`FORGE.md` as a third backend map

Skills and CI never name a vendor; they invoke `checks:*` operations, and
`docs/adapters/CHECKS.md` maps each to a concrete mechanism for the active backend,
declared the same way (`active-backend: github-actions`). The `github-actions` backend
entry reproduces today's behavior exactly — `.github/workflows/ci.yml`/`review-gate.yml`
and `github-bootstrap.sh`'s required-checks setup are re-described in the new file's
terms with no behavior change, satisfying #102's own done-when.

### D2. A `local-runner` backend: clean checkout, one status per context

The alternative backend `CHECKS.md` documents (not yet implemented — see Non-goals) is a
process that watches the same PR events GitHub Actions reacts to today
(`pull_request`, `pull_request_review`), and for each, runs the same check scripts this
repo already ships (`.t-workflow/scripts/check-*.sh`, `consistency-check.sh`,
`plumbing-test.sh`, the build command) against a **clean, isolated checkout of the PR's
head commit — never the tree of the agent that authored the diff**. Isolation is the one
requirement this ADR treats as non-negotiable for any future implementation: a check
that ran inside the authoring session's own working tree could pass against
uncommitted, unreviewed state the pushed commit does not actually contain, which is
exactly the independence a hosted CI run provides today and that a swap of *where*
checks run must not quietly lose. The runner reports each check by posting one commit
status per required context via `POST /repos/{owner}/{repo}/statuses/{sha}` — the same
API surface branch protection already reads from a passing Actions job, so
`forge:pr-checks` and a human looking at the PR see no difference between backends.

### D3. Runner shape and authentication are explicitly left open

Where the runner process lives (a long-running daemon, a webhook receiver, a
`locklane`-shaped service) and how it authenticates to post statuses (a GitHub App
installation token, scoped to `statuses:write`, is the leading candidate — a fine-grained
PAT is the fallback) are not decided here. #102's own scope names this as "genuinely
open" and asks this design to propose, not build, whatever separable work follows —
consistent with `AGENTS.md`'s rule that discovered work is proposed, never opened
directly by the task that finds it. `docs/adapters/CHECKS.md`'s `local-runner` rows
describe the contract each candidate shape must satisfy, not which one is chosen.

### D4. A known gap this design does not resolve: `github-bootstrap.sh`'s "has it run" probe

`github-bootstrap.sh` decides whether a context is safe to mark required by querying
`repos/{repo}/commits/main/check-runs` — the Checks API, populated only by Actions job
runs. A `local-runner` backend posts through the Statuses API instead, which that query
never sees, even though branch protection's `required_status_checks.contexts` accepts
either kind of context by name interchangeably for blocking a merge. Left unaddressed, a
consumer adopting `local-runner` would find `github-bootstrap.sh` perpetually reports
"CI has not run on main yet" for its contexts. This is real, but it is implementation
work behind the Non-goal below, not a design gap — recorded here as a scoped fact for
whichever follow-up issue implements `local-runner` to pick up, rather than solved
in-line by widening this task's diff.

## Rationale

- **Mechanical, not constitutional.** `CONSTITUTION.md` §1.3 already places the
  tracker/forge choice outside the constitution proper; extending the same pattern to
  checks needs no amendment to that file, only a new adapter doc — the lowest-ceremony
  path consistent with how the other two adapters were introduced.
- **The isolation requirement is the one line worth being explicit and permanent about.**
  Everything else here (runner shape, auth) is genuinely undecided and fine to leave
  open; isolation is not a design detail to bikeshed later, because a `local-runner`
  built without it would silently weaken a guarantee `CONSTITUTION.md` §1.5 treats as
  load-bearing — "guardrails are never weakened" — even though nothing in that section
  names checks execution specifically today.
- **The Statuses API is the smallest change that keeps branch protection oblivious.**
  Branch protection already treats "a context posted a status" as the whole of its
  contract; building a second mechanism (a bot that manipulates check runs, e.g.) would
  buy nothing `checks:report-status` doesn't already get for free, at more implementation
  cost.
- **Naming the `github-bootstrap.sh` gap without fixing it keeps this task's diff to what
  #102 actually asked for** — a design and an ADR, not an implementation — while making
  sure it isn't rediscovered as a surprise mid-implementation.

## Alternatives considered

- **Self-hosted `runs-on:` runners, keeping GitHub Actions as the orchestrator** — the
  issue's own named lower-effort alternative. This trades Actions-minutes billing for a
  self-managed runner's compute cost, without touching triggers, job definitions, or
  `forge:pr-checks`'s read path at all. Rejected as this design's answer because it
  doesn't address the workflow-level defects #93 also names (the `edited`-trigger churn,
  the child-retarget cost, the lack of `concurrency:`/`timeout-minutes:`) — those live in
  Actions' own orchestration layer regardless of where the runner executes — and it
  provides no isolation guarantee by default (a long-lived self-hosted runner's workspace
  persists across jobs unless the operator wipes it themselves). It remains a legitimate,
  lower-effort choice for a consumer that only wants to move compute cost off GitHub's
  metered minutes without decoupling from Actions as the trigger/orchestration backbone;
  `CHECKS.md` does not preclude a consumer choosing it instead of `local-runner`, but this
  ADR does not design it as a named backend, since it changes none of the `checks:*`
  contract — it is a `github-actions` backend detail (which runner labels
  `.github/workflows/*.yml` targets), not a new backend.
- **A vendor-neutral webhook-relay usable by any CI product, not only a
  locklane-shaped runner** — rejected as premature generality: no second consumer of this
  template has asked for a specific non-Actions CI product today, and `docs/adapters/`'s
  own pattern (TRACKER.md, FORGE.md) is to document exactly the backends a real consumer
  needs, adding a new one when one actually shows up.
- **Solve the `github-bootstrap.sh` "has it run" gap (D4) in this same task** — rejected:
  it is implementation work for a backend this task explicitly does not build (Non-goals
  below); folding it in here would widen `docs/adapters/CHECKS.md`/this ADR's Allowed
  paths past what `/t-plan` scoped, for a fix nothing can exercise until `local-runner`
  itself exists.

## Consequences / revisit triggers

Accepted knowingly: `local-runner` is documented, not implemented — a consumer on a
tight Actions-minutes budget gets no relief from this task alone. Follow-up
implementation issues (the runner process itself, its auth, and the
`github-bootstrap.sh` probe fix from D4) are proposed in this task's PR, per
`AGENTS.md`'s tracker-write rule, for the human to open.

Any of these reopens this decision, as a new ADR:

1. **A consumer actually implements `local-runner`** and the runner-shape or
   authentication questions D3 left open get answered — the answer belongs in
   `docs/adapters/CHECKS.md` directly (an ordinary edit to that file, not necessarily a
   new ADR, unless the shape chosen contradicts an assumption made here, such as the
   Statuses API being sufficient).
2. **GitHub deprecates or restricts the Statuses API** in favor of Checks-API-only
   status reporting — D2's mechanism would need re-deriving, since the Checks API needs
   a GitHub App identity rather than a plain token.
3. **A consumer wants a non-`local-runner` alternative outside what `CHECKS.md`
   documents** (a third-party CI product, say) — revisit whether `checks:*`'s current
   operation set is general enough, or whether it implicitly assumes GitHub-specific
   mechanics that need loosening first.
