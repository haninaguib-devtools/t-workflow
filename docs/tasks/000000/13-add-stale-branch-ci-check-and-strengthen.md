# 13 — Add stale-branch CI check, and strengthen t-ship/t-fix/t-cancel branch-deletion wording
Issue: #13

## Asked
`/t-ship`, `/t-fix`, and `/t-cancel` all rely on `forge:pr-merge`/`forge:pr-close` to
delete a task's head branch on the forge as part of merging or closing. That relies
entirely on the exact command used including the delete-branch flag — if any invocation
omits it (as happened downstream in haninaguib-devtools/locklane, a pure execution slip),
the branch silently lingers with nothing surfacing the miss. This task adds a scheduled
CI backstop that reports stale branches without deleting them, and strengthens the
wording in the three branch-deleting skills at the exact point the merge/close command is
composed, so the literal `docs/adapters/FORGE.md` row is re-read rather than
reconstructed from memory.

## Done when
- The template ships a scheduled GitHub Actions workflow (e.g. hourly) that lists merged
  and closed PRs, checks whether their head branch (matching `wip/*` or `fix/*`) still
  exists on `origin`, and fails/reports when one does (excluding a short grace period for
  freshly-merged PRs).
- The check only reports/fails — it never deletes branches itself.
- Documented as part of the template's generated CI, alongside the existing consistency
  and record checks.
- The `t-ship`, `t-fix`, and `t-cancel` skill templates are reworded so the branch-deletion
  step instructs re-reading `docs/adapters/FORGE.md`'s relevant row immediately before
  composing the command, and verifying the resulting command string includes the active
  backend's branch-deletion flag before running it.

## Explicitly not
- No change to the `forge:pr-merge`/`forge:pr-close` mappings themselves in
  `docs/adapters/FORGE.md` — those are already correct.
- No change to `installer/` — investigated at plan time and found unnecessary (see
  Decisions below).

## Decisions made along the way
- `installer/` left out of Allowed paths (hani, 2026-08-25, at `/t-plan`): inspecting
  `installer/bootstrap.sh` shows it does a wholesale `cp -R` of the cloned template into
  every generated project, stripping only a named list of files (`.git`, `LICENSE`,
  `installer/`, `site/`, `.github/workflows/installer.yml`,
  `.github/workflows/pages.yml`). A new workflow or script is inherited automatically.
  `installer/test.sh` already asserts generically that every generated workflow calls no
  missing script, which covers the new workflow for free.

## Deviations / notes
- Fixed after the cold review (hani, 2026-08-25): `scripts/stale-branches-check.sh`'s
  per-branch existence check (`if gh api "repos/$repo/branches/$branch" ...; then`)
  treated *any* non-zero exit from `gh api` — a confirmed 404 (branch gone) but also a
  bad/expired token, rate limit, or network failure — as "not stale", so a check that
  exists specifically to catch silent failures could itself fail silently and still
  print "no stale branches found" with exit 0. Reproduced directly (a request with a bad
  token returns `HTTP 401`, indistinguishable by exit code alone from the `HTTP 404` a
  genuinely-deleted branch returns). Fixed by capturing `gh api`'s stderr and only
  treating a message containing `HTTP 404` as "confirmed deleted"; every other failure
  now reports `UNKNOWN` and makes the whole script exit 1 rather than reporting a clean
  pass. Same fix for the page-limit case: hitting the `--limit` used to print a warning
  but still let the script report "no stale branches found"; it now exits 1 immediately,
  since ADR-001 §D6 treats a scan sitting at its page limit as incomplete, never as a
  clean total. Verified: reproduced both failure modes directly (a bad `GH_TOKEN` against
  a real branch, and `limit=1` against this repo's real PR history) and confirmed each
  now exits 1 with the right message; re-ran the normal case and the zero-grace-period
  case against this repo's real history, both still exit 0 with "no stale branches
  found".
