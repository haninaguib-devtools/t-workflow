# V4 — `ci.yml`'s push-trigger trunk name gains a local slot

**Introduced:** v0.0.18 (best guess — the next tag cut after #170 merges; confirm and
correct this line once a maintainer actually cuts it, since this file has shipped in no
tag yet and is not "edited after shipping" until it does)

## What broke

Before this tag, `.github/workflows/ci.yml`'s `push:` trigger hardcoded
`branches: [main]` with no `<!-- local -->` slot (`docs/architecture/local-slots.md`)
around it. A consumer whose trunk is not called `main` — the workflow's own skills and
scripts already resolve the real trunk name at run time via
`.t-workflow/scripts/trunk-ref.sh` (`AGENTS.md` §Conventions), but a workflow trigger is
static YAML with nothing to resolve at run time — had no sanctioned place to put its own
branch name, and hand-edited the `branches:` line directly in the template-owned file to
get CI running on push to its actual trunk. Starting at this tag, that line sits inside
its own marked region, with the template's own value (`main`) inside the markers.

An ordinary sync (`.claude/skills/t-update/SKILL.md` step 7) decides "copy the target
file whole" versus "splice, keeping the region between markers" by checking whether the
file's **current** (pre-sync) content already carries a `<!-- local -->` marker
somewhere. `ci.yml` already carries two other slots (`timeout-minutes`, the trailing
`steps:` extension point — `migrations/V1__ci-yml-local-slots.md`), so the file *as a
whole* is not unmarked, and the ordinary per-file rule already treats the whole file as
"splice around markers" rather than "copy target's version wholesale." But that ordinary
splice only preserves what already sits *inside* an existing marker pair; a consumer's
non-`main` branch name sits **outside** any marker today, on the same
`branches: [main]`-shaped line as the target's own new slot. A plain splice would
therefore overwrite that line with the target's new `# <!-- local -->` /
`branches: [main]` / `# <!-- /local -->` region, silently reverting the consumer's trunk
name back to `main` on push — the trigger stops firing on their real trunk, and nothing
about that failure is loud: `check-manifest.sh` sees a well-formed slot either way, and
CI simply stops running on push until someone notices. That is exactly the loss this
migration exists to prevent: the consumer's own state (their branch name, sitting
outside any marker on this specific line) needs to be *relocated* into the new marker,
not merely diffed against or left to an ordinary splice.

## Instructions for the upgrading agent

Run this **before** step 7's ordinary per-file copy/splice touches
`.github/workflows/ci.yml`, or rely on reading history rather than the working tree —
either is safe, since nothing is committed until step 9 (`git show HEAD:<path>` returns
the pre-sync content throughout step 7 regardless of what the working copy currently
holds).

1. Read the consumer's pre-sync file: `git show HEAD:.github/workflows/ci.yml`. If this
   errors (the file didn't exist pre-sync — a very old consumer, or a first-adoption
   sync with nothing to migrate), skip this migration's remaining steps entirely; the
   ordinary sync in step 7 already does the right thing for a file that never existed.
2. Within that pre-sync text, find the `on:` block's `push:` trigger and read its
   `branches:` value verbatim (it is a single-item list today, `branches: [<name>]`, but
   read whatever is actually there rather than assuming the exact shape — a consumer may
   have reformatted it onto multiple lines or added a second branch).
3. If that value is exactly `[main]` (or `main` in any equivalent single-item form the
   consumer's file happens to use), the consumer never customized this line — skip the
   rest of this migration; the ordinary sync's neutral placeholder in the new slot
   (`branches: [main]`) is already correct and there is nothing to relocate.
4. Otherwise, the extracted value **is** the consumer's real trunk branch name (or set of
   branches) — record it before continuing; step 6 below relocates it after the ordinary
   sync writes the target's own template line first.
5. Let step 7's ordinary sync write the new target-tag `ci.yml` (with its new
   `push:`-trigger slot, holding the template's own neutral placeholder,
   `branches: [main]`).
6. Re-open `.github/workflows/ci.yml` and, only when step 4 extracted a value, replace
   `branches: [main]` between the `# <!-- local -->` / `# <!-- /local -->` pair around
   the `push:` trigger with `branches: <the extracted value>`, keeping the same
   indentation (4 spaces, one level under `push:`) and the same list-or-scalar shape the
   consumer's own pre-sync line used.
7. Report, in the update's closing report, the exact branch value relocated (or, when
   step 3 found nothing to relocate, say plainly that the consumer's trunk was already
   `main` and the placeholder needed no change) so a human can confirm nothing was
   silently dropped or silently reverted.

## Done-when

- `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"` exits 0
  — the file is still valid YAML after relocation.
- `.t-workflow/scripts/check-manifest.sh --hash-file .github/workflows/ci.yml` produces
  the same normalized hash as `.t-workflow/scripts/check-manifest.sh --hash-file` run
  against a copy of the file with all three of its slots' content stripped back to
  empty — i.e. the relocated branch name landed *inside* the new slot, not outside it
  (an outside landing would register as drift at the very next sync, the same failure
  mode this migration exists to prevent).
- The consumer's pre-sync `branches:` value (if step 4 found one) appears, unchanged,
  inside the new slot, and `git log` on the resulting commit shows `ci.yml`'s `push:`
  trigger still watches the consumer's real trunk, not `main`.
- `.github/workflows/ci.yml`'s `on: push:` trigger fires on that consumer's own trunk —
  confirmable on the consumer's own forge after the next push there, since no local
  fixture can simulate a real push event.
