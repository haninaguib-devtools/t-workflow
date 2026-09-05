# V2 — A consumer's own required status checks move into `.t-workflow/required-checks.local`

**Introduced:** v0.0.11 (best guess — the next tag cut after #126 merges; confirm and
correct this line once a maintainer actually cuts it, since this file has shipped in no
tag yet and is not "edited after shipping" until it does)

## What broke

Before this tag, `.t-workflow/scripts/github-bootstrap.sh` hardcoded the trunk's
required-status-check list as exactly `checks` and `cold-review` and re-asserted it on
every run, so a consumer that wanted its own CI job required (locklane's real-macOS
lifecycle job, locklane#705) could only set the context by hand on the forge — and
every re-run of the script silently removed it again. Starting at this tag, the list is
the union of the template's fixed pair and `.t-workflow/required-checks.local`, a
consumer-owned file (`docs/architecture/local-slots.md` § The required-checks file),
computed by `.t-workflow/scripts/required-checks.sh`.

A plain file sync is not enough on its own because the consumer's state here is not in
any file: it is the live branch-protection setting on the forge. After the sync, the
next `github-bootstrap.sh` run would still wipe a hand-set context, because the new
file does not yet exist to name it. The context has to be *relocated* from the forge
into the file.

## Instructions for the upgrading agent

Run this after the ordinary sync in `t-update` step 7 has landed the new
`required-checks.sh` (nothing here depends on pre-sync file content, so order relative
to the per-file copy/splice does not otherwise matter).

1. Read the live required contexts on the trunk:
   `gh api "repos/<owner>/<repo>/branches/$(.t-workflow/scripts/trunk-ref.sh)/protection/required_status_checks" --jq '.contexts[]'`.
   If this errors (no branch protection — a private repo on a free plan, or a consumer
   that never ran the bootstrap), there is nothing hand-set to relocate: skip the rest
   of this migration.
2. Drop `checks` and `cold-review` from that list — those are the template's own and
   `required-checks.sh` supplies them. If nothing remains, the consumer never set a
   context by hand: skip the rest of this migration and leave no file behind.
3. Write each remaining context, one per line, into `.t-workflow/required-checks.local`
   (creating the file; if the consumer already has one, append only the names it lacks).
   Add a one-line `#` comment naming this migration so a later reader knows where the
   entries came from.
4. Report, in the update's closing report, exactly which contexts were relocated, so a
   human can confirm none was a stale leftover that should be removed instead —
   removing one is now a one-line edit to the file followed by a `github-bootstrap.sh`
   re-run (or a `/t-ship` of the PR that removes it, which flips the live setting
   itself).

## Done-when

- `.t-workflow/scripts/required-checks.sh --list` prints every context step 1 read from
  the forge — the live list is a subset of the computed union, so the next
  `github-bootstrap.sh` run re-asserts rather than removes each hand-set context.
- `.t-workflow/scripts/template-owned-paths.sh --list | grep -c required-checks.local`
  prints `0` — the file is the consumer's own: never template-owned, so never hashed
  into the manifest `t-update` step 8 writes next, and never reported as drift by
  `check-manifest.sh` afterwards. (Do not run `check-manifest.sh` itself here: a
  migration's Done-when is checked in step 7, before step 8 rewrites the manifest, so
  at that moment every synced file legitimately reads as drift.)
