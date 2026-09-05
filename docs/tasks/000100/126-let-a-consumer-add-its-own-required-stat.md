# 126 — Let a consumer add its own required status checks without github-bootstrap.sh wiping them
Issue: #126

## Asked
A repository generated from this template can name its own CI job as a check a PR must
pass before merging, and neither a template sync nor a re-run of
`.t-workflow/scripts/github-bootstrap.sh` removes it. Today the script hardcodes the
required-status-check list (`checks`, `cold-review`) and re-asserts exactly that list
every run, so a context a consumer set by hand is silently wiped the next time — which
left locklane unable to make its real-macOS lifecycle job a required check.

## Done when
- `github-bootstrap.sh` asserts the union of the template's fixed contexts and a
  consumer-supplied list read from one documented place; with no consumer additions the
  behaviour is unchanged (exactly `checks` and `cold-review`).
- The "only once a real run exists on the trunk" guard is preserved and applied per
  consumer context, so a freshly added consumer context does not block merges before
  its first run.
- `docs/architecture/local-slots.md` documents the place; a sync carries the consumer's
  list forward unchanged and `check-manifest.sh` never flags it as drift.
- `/t-ship` Procedure steps 3 and 5 use the same union, so shipping a PR that adds or
  renames a consumer context needs no hand-run PATCH.
- `plumbing-test.sh` covers: no consumer list → the two defaults; a list → the union;
  a consumer context with no trunk run yet → left out until it has one.
- A migration tells a consumer that hand-set a context how to move it into the new place.

## Explicitly not
- Changing which template checks are required (`checks`, `cold-review` stay).
- Per-path required checks — GitHub has none; a consumer job that gates by path skips
  itself at job level so a skipped run passes.
- Touching `installer/`, `README.md`, `.github/workflows/*`, `docs/adapters/*`,
  `CONSTITUTION.md`, `AGENTS.md`, `check-manifest.sh`, or `template-owned-paths.sh`.
- Adding a `.t-workflow/required-checks.local` to this repository itself — it is the
  template, not a consumer.

## Decisions made along the way
- **A consumer-owned file, not a slot inside the script** (agent, plan on #126,
  2026-09-04): `.t-workflow/required-checks.local`, one context per line, `#` comments
  and blank lines ignored, absent = no additions. It sits under `.t-workflow/` but not
  `.t-workflow/scripts/`, so it matches no protected pattern, is never template-owned,
  never hashed into the manifest, and never touched by a sync — the "carried forward
  unchanged" property holds by construction with no change to `check-manifest.sh` or
  `/t-update`. A `# <!-- local -->` slot inside `github-bootstrap.sh` was rejected: it
  puts consumer edits inside a template-owned executable and gives `/t-ship` nothing to
  read but the script's own text.
- **One implementation of the union** (agent, same plan): a new pure script
  `.t-workflow/scripts/required-checks.sh` — `--list` prints the union in order,
  `--asserted <observed-names-file|->` prints the template pair plus every consumer
  name that appears among the observed check-run names. `github-bootstrap.sh` and
  `/t-ship` both call it; neither re-derives the list, and `plumbing-test.sh` can test
  it with pure fixtures because it never calls the forge.
- **The template pair stays gated on `checks` alone**, exactly as today; only consumer
  contexts get the per-name guard. Asserting `cold-review` whenever `checks` has run is
  existing behaviour and the Non-goals keep it.
- **Never merge in whatever is currently live**: the asserted list is declarative
  (fixed pair + file). Folding in the live setting would make a context impossible to
  remove. The migration is what moves a hand-set context into the file.

- **The trunk's check-run listing is now paginated** (`gh api --paginate`; agent,
  2026-09-04): the endpoint returns 30 check-runs per page by default, and a consumer
  whose trunk commit carries more than that could have `checks` on a later page and
  fall into the "CI has not run yet" branch by accident. Same behaviour on this repo,
  where one page holds everything.

## Deviations / notes
- The plan's Allowed paths named the record as
  `docs/tasks/000100/126-consumer-required-checks.md`; the pipeline's own slug rule
  (`/t-work` Phase 1 step 4, from the issue title) yields
  `126-let-a-consumer-add-its-own-required-stat.md`, and the record follows the rule.
  A filename derivation inside the same allowed directory, not a scope change (agent,
  2026-09-04, in the same driven session that wrote the plan).
- `migrations/README.md` still says "No migration files exist yet" although V1 shipped
  with #118. Out of scope here (`migrations/README.md` is not an allowed path) —
  reported for a separate fix.
