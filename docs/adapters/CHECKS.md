# Checks adapter

Where the pipeline's checks actually execute. Skills and CI never name a mechanism: they
invoke the `checks:*` operations below, and this file maps each to a concrete
implementation for the **active backend**:

```
active-backend: github-actions
```

Swapping backends means editing this file, `.github/workflows/*.yml` (or their
replacement), and `.t-workflow/scripts/github-bootstrap.sh`'s required-checks setup —
no skill changes, the same guarantee `docs/adapters/TRACKER.md` and
`docs/adapters/FORGE.md` give for their own backends. See ADR-008 for the decision this
file implements, including which parts of a non-default backend remain undecided.

## Vocabulary

- **context** — the name of one required check, exactly as it appears in
  `gh pr checks`/branch protection: `consistency`, `record`, `plan-gate`, `title-gate`,
  `blockers`, `cold-review`, `plumbing-test`, plus the build job once `AGENTS.md`
  §Checks names one.
- **run** — one execution of every context against a single commit SHA, triggered by a
  PR event (`opened`, `synchronize`, `reopened`, or a submitted review for
  `cold-review`).

`docs/adapters/TRACKER.md` and `docs/adapters/FORGE.md` are independent choices from
this one — a repo can mix any tracker, any forge, and any checks backend, though only
GitHub-backed combinations are implemented today.

## Operations

### `checks:contexts` — the list of required contexts this repo enforces

Contract: this list is what `checks:required-checks-setup` marks required in branch
protection, and what a `local-runner`'s single pass over a commit must produce a status
for, one call each — no more, no fewer.

| Backend | Behavior |
|---|---|
| github-actions | The job names in `.github/workflows/ci.yml` and `review-gate.yml`: `consistency, record, plan-gate, title-gate, blockers, cold-review, plumbing-test` (plus the build job once `AGENTS.md` §Checks names one). |
| local-runner *(designed, not implemented — ADR-008)* | Same list by default; a consumer names its own in this row if its check set diverges from the template's. |

### `checks:trigger <event>` — what starts a run for a given PR event

| Backend | Behavior |
|---|---|
| github-actions | GitHub Actions' own `on: pull_request` / `on: pull_request_review` triggers in `.github/workflows/ci.yml` and `review-gate.yml` — no separate mechanism. |
| local-runner *(designed, not implemented — ADR-008 D3)* | A process subscribed to the same GitHub webhook events (`pull_request`, `pull_request_review`) reacts instead of Actions. Its own shape — long-running daemon, webhook receiver, a `locklane`-shaped service — is undecided; ADR-008 D3 leaves it to implementation. |

### `checks:run <context> <sha>` — execute one context's script against a commit

Contract: runs in a **clean, isolated checkout of `<sha>`** — never the working tree of
the agent that authored the diff. This is the one requirement ADR-008 D2 treats as
non-negotiable for any backend: the independence a hosted CI run provides today (the
committed state is what gets checked, not whatever else happens to be on disk) must
survive a backend swap unchanged, per `CONSTITUTION.md` §1.5.

| Backend | Command |
|---|---|
| github-actions | The matching job in `.github/workflows/ci.yml` / `review-gate.yml`, executed by an ephemeral GitHub-hosted runner that checks out `<sha>` fresh via `actions/checkout`. |
| local-runner *(designed, not implemented — ADR-008 D2)* | The same script this repo already ships (`.t-workflow/scripts/check-*.sh`, `consistency-check.sh`, `plumbing-test.sh`, or the build command), run by the runner process against a fresh clone or worktree of `<sha>` that it creates for this run and discards afterward. |

### `checks:report-status <sha> <context> <state> <description> [<url>]` — publish one context's result

Contract: `<state>` is one of `pending|success|failure|error`. Branch protection's
required-checks mechanism reads this identically to a GitHub Actions job's own
completion status — the two backends are indistinguishable to `forge:pr-checks` and to
a human reading the PR.

| Backend | Command |
|---|---|
| github-actions | Implicit — a workflow job's pass/fail *is* its status; GitHub posts it automatically when the job completes. No explicit call. |
| local-runner *(designed, not implemented — ADR-008 D2)* | `gh api repos/<owner>/<repo>/statuses/<sha> -f state=<state> -f context=<context> -f description="<description>" -f target_url="<url>"` (or the equivalent authenticated REST call: `POST /repos/{owner}/{repo}/statuses/{sha}`), issued by the runner process itself. How that process authenticates — a GitHub App installation token scoped to `statuses:write`, or a fine-grained PAT — is undecided (ADR-008 D3). |

### `checks:required-checks-setup` — register the required contexts in branch protection

| Backend | Command |
|---|---|
| github-actions | `.t-workflow/scripts/github-bootstrap.sh` — sets `required_status_checks.contexts` to `checks:contexts`' list, once each has been observed at least once on `main` (GitHub refuses to require a context it has never seen). |
| local-runner *(designed, not implemented — ADR-008 D3, D4)* | Same script and the same "seen at least once" precondition, **with one known gap**: `github-bootstrap.sh` currently probes via `repos/{repo}/commits/main/check-runs` (the Checks API), which never sees a context posted through `checks:report-status`'s Statuses-API call. A `local-runner` adopter needs that probe extended to also query `repos/{repo}/commits/{sha}/statuses` before this row is accurate — tracked as follow-up implementation work (ADR-008 D4), not yet done. |

## Bootstrap

Settings-as-code for the checks backend itself, alongside the tracker/forge bootstrap
each of those adapter files names:

| Backend | Where |
|---|---|
| github-actions | `.github/workflows/ci.yml`, `.github/workflows/review-gate.yml` (the checks themselves) plus `.t-workflow/scripts/github-bootstrap.sh` (marking them required). |
| local-runner *(designed, not implemented — ADR-008)* | Not yet written — part of the follow-up implementation work ADR-008 proposes rather than builds. |
