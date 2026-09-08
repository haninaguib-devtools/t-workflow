# 171 — Share the consumer exclusion set between bootstrap.sh and the adoption script
Issue: #171 · Part of: #168

## Asked
`installer/bootstrap.sh` decides inline what a generated project never receives from
the template: the template's `.git`, `LICENSE`, `installer/`, `site/`, the installer
and pages workflows, and the template's own task records under `docs/tasks/`. The
adoption script (initiative #168, #172) must apply exactly the same list to a scratch
clone before merging it into an existing repository, and two copies of that list would
drift. Move it into one file both scripts source — a small library under `installer/`
— with a function that turns a template clone into the consumer tree, and make
`bootstrap.sh` call it. Pure refactor: the generated project is byte-identical before
and after.

## Done when
- One file under `installer/` holds the exclusion set and the strip function;
  `bootstrap.sh` sources it and contains no inline copy of the list.
- A generated project's tree (`find … | sort`, plus a content diff) is identical
  between the commit before this task and after, demonstrated in the record.
- `./installer/test.sh` passes; `./.t-workflow/scripts/consistency-check.sh` exits 0.
- A cold review (`/t-review`) reports `readiness: ready` — `installer/` is a protected
  surface (`CONSTITUTION.md` §3).

## Explicitly not
- Unifying with `.t-workflow/scripts/template-owned-paths.sh`'s exclusion list, which
  serves a different purpose (which paths a manifest tracks) and lives in every
  consumer — see Deviations below for the overlap.
- Any behaviour change to `install.sh` or `bootstrap.sh`.

## Origin
none

## Verification
none — the plan's `### Validation` names one `human_checks:` item (whether the
extracted function's signature and location will actually serve #172's use without a
second refactor), not a structured `verification:` list; per
`docs/architecture/verification.md` §Relationship to `human_checks`, that stays an
ordinary `human_checks` judgment, restated by `/t-review` in its own `## Pending human
checks` section rather than tracked here.

## Feedback
none

## Decisions made along the way
- Named the new file `installer/consumer-tree.sh` and its function
  `strip_consumer_exclusions(dir)`, operating in place on whatever directory it is
  given rather than assuming that directory is the whole target — the plan's own risk
  note flagged this as the thing to get right for #172 (`adopt.sh` strips a scratch
  clone, then selectively merges it into an existing repo; it never overwrites a whole
  target the way `bootstrap.sh`'s `cp -R` does). `bootstrap.sh` calls it once, after its
  own `cp -R "$src" "$target"`, on `$target` (agent, 2026-09-08).
- Carried over every rationale comment from `bootstrap.sh`'s inline `rm -rf` block
  (why `.git`, `LICENSE`, `installer/`, `site/`, and the two workflow files are
  excluded) into `installer/consumer-tree.sh`'s header, rather than dropping them —
  they explain *why* each path is excluded, which stays true for `adopt.sh` too, not
  only for `bootstrap.sh` (agent, 2026-09-08).
- Sourced `installer/consumer-tree.sh` from `$src` (`. "$src/installer/consumer-tree.sh"`)
  rather than resolving `bootstrap.sh`'s own directory via `$0`/`BASH_SOURCE`: `$src` is
  already the known, validated clone root (`TWORKFLOW_SRC`, checked for `.git` two lines
  above), so sourcing from it is simpler than an indirection that would land on the same
  path anyway, and mirrors how the script already resolves its other input file
  (`$src/installer/templates/README.md`). Moved the source line to *after* the
  `-d "$src/.git"` / target-exists checks, so a bad `$src` still fails with the
  existing "is not a git clone" message rather than a raw "No such file" from a source
  that never gets that far (agent, 2026-09-08).
- Noted, per Explicitly-not above: `.t-workflow/scripts/template-owned-paths.sh` keeps
  its own separate exclusion list (used to decide what a manifest tracks, not what a
  generated project ever receives) — the two lists overlap in places (both exclude
  `installer/`, e.g.) but serve different questions, so they are not merged here
  (agent, 2026-09-08).

## Deviations / notes
- Verified the refactor produces a byte-identical generated project by running
  `installer/bootstrap.sh` twice against the same source commit — this task's own
  final commit on this branch, so the provenance `ref` line is identical in both runs
  — once with the pre-refactor `bootstrap.sh` (the parent commit's version, with no
  `installer/consumer-tree.sh`) substituted in uncommitted, once with the actual
  post-refactor `bootstrap.sh` + `installer/consumer-tree.sh` — with `GIT_AUTHOR_DATE`/
  `GIT_COMMITTER_DATE`/identity fixed so even the generated project's own first commit
  is reproducible. `find <target> | sort` matched exactly; `diff -rq -x index` over the
  two generated trees (everything except `.git/index`, git's own filesystem stat cache,
  which differs between any two independent checkouts regardless of content) reported
  no differences; and the generated projects' own `HEAD` **commit hashes matched
  exactly** between the two runs — since git objects are content-addressed, an
  identical commit hash is the strongest form of this proof: identical tree, identical
  commit message (including the identical `ref`), identical author/committer identity
  and date. Re-ran this after every amend to this record, most recently at this PR's
  head commit (see `## Checks run` on the PR for the exact script and result). This
  holds the source commit fixed rather than comparing against the literal prior commit
  on `origin/wip/168-integration`, which would also differ by the provenance `ref` line
  for a reason unrelated to this refactor (a different source commit necessarily hashes
  differently) — holding it fixed isolates exactly the effect of the script change
  (agent, 2026-09-08).
