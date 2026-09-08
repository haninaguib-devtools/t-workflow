# V5 — Check 1 is skipped on documentation-only diffs; `AGENTS.md` §Checks gains a slot

**Introduced:** v0.1.2 (best guess — the next tag cut after #183 merges; confirm and
correct this line once a maintainer actually cuts it, since this file has shipped in no
tag yet and is not "edited after shipping" until it does)

## What broke

Before this tag, every task ran the consumer's build/test command (`AGENTS.md` §Checks
item 1) on every diff. Starting at this tag (ADR-012), check 1 runs only when
`.t-workflow/scripts/docs-only.sh` says the task's diff is *not* documentation-only —
`*.md` anywhere and `docs/**` by default, plus whatever globs the consumer lists in a
new `<!-- local -->` slot under `AGENTS.md` §Checks' `### Documentation-only paths`
sub-heading. `.github/workflows/ci.yml` gains a template-owned step, `id: docs-only`,
that publishes the same verdict as `steps.docs-only.outputs.docs_only`.

An ordinary sync (`.claude/skills/t-update/SKILL.md` step 7) brings the consumer every
template-owned part of this: the script, the rule text, the new slot (holding the
template's neutral placeholder), the CI step, and the skill changes. Two things it
cannot do, because they live inside the consumer's own slots:

1. **The consumer's own build/test step in `ci.yml`'s trailing slot is unguarded.** The
   template's new `docs-only` step publishes a verdict nobody reads until the consumer's
   step carries `if: "!cancelled() && steps.docs-only.outputs.docs_only != 'true'"`.
   Without it CI keeps building on documentation-only PRs — nothing breaks, but the
   saving the release exists for never arrives, and CI and the local rule now disagree.
2. **The consumer's extra documentation paths are not in the new slot.** A consumer
   whose documentation also lives outside `*.md`/`docs/**` (a static site under
   `site/**`, say) needs those globs in the slot, or the script judges such a diff as
   not documentation-only and runs the build.

There is also a positional hazard: `AGENTS.md` now carries five marker pairs, and the
new one sits **fourth** — between §Checks item 1 (third) and §Project notes (fifth). A
splice that aligns regions by counting pairs would land the consumer's project notes in
the documentation-only slot and leave §Project notes with the placeholder. The ordinary
sync is instructed to match regions by their surrounding template text, but this
migration checks the outcome rather than assuming it.

## Instructions for the upgrading agent

Run this **after** step 7's ordinary per-file copy/splice has written the target-tag
`AGENTS.md` and `.github/workflows/ci.yml`; nothing here reads pre-sync state that the
sync would have destroyed.

1. **Confirm `AGENTS.md`'s slots hold their own kind of content.** Read the five
   `<!-- local -->` … `<!-- /local -->` regions in file order and check: the first
   holds skill-table rows or the skill-row placeholder; the second the reviewer-model
   line; the third (under `## Checks`, before `### Documentation-only paths`) the
   consumer's build/test command or the `(none yet — no stack exists.)` placeholder;
   the fourth (under `### Documentation-only paths`) the template's
   `(reserved: this project's own documentation-only paths — …)` placeholder — this is
   a brand-new slot, so the consumer can have written nothing into it yet; the fifth
   (under `## Project notes`) the consumer's own session-start notes or that section's
   placeholder. Any region holding another region's content means the splice aligned
   by position: move each region's content back to where its heading says it belongs
   (`git show HEAD:AGENTS.md` still has the pre-sync text to compare against), then
   continue.
2. **Guard the consumer's build/test step(s) in `ci.yml`.** Inside the trailing
   `# <!-- local -->` … `# <!-- /local -->` region of the `checks` job's `steps:`,
   find every step that runs the command `AGENTS.md` §Checks item 1 names (a
   `Project checks` step, if `installer/adopt.sh` wrote it; otherwise whatever the
   consumer named it). For each, set its `if:` to exactly
   `if: "!cancelled() && steps.docs-only.outputs.docs_only != 'true'"` — replacing an
   existing `if: "!cancelled()"`, or adding the line when the step had none. Leave every
   other step in that region (the CI-lock manifest check, anything else the consumer
   added) exactly as it is — only the build/test step reads the verdict. If item 1 still
   reads `(none yet — no stack exists.)` there is no such step: say so and skip this
   step.
3. **Fill the documentation-only slot, when the consumer has extra documentation
   paths.** Ask, or read from the consumer's own repository what it already treats as
   documentation outside `*.md`/`docs/**` (a `site/`, `docs-src/`, `handbook/` tree
   that no build reads). For each such path, replace the placeholder in the fourth slot
   with one bullet per glob in backticks, e.g. `` - `site/**` ``. A consumer with no
   such paths keeps the placeholder — the defaults alone are in force, which is the
   template's own state too.
4. **Report**, in the update's closing report: that the five `AGENTS.md` slots were
   found aligned (or what was moved back), which `ci.yml` step(s) were guarded (or that
   there was none to guard), and which globs, if any, were added to the
   documentation-only slot — so a human can confirm nothing was silently dropped, and
   knows the consumer's next documentation-only task will skip the build.

## Done-when

- `bash .t-workflow/scripts/docs-only.sh --list` exits 0 and prints `*.md`, `docs/**`,
  and every glob step 3 added, one per line, nothing else.
- `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"` exits 0,
  and `grep -c "steps.docs-only.outputs.docs_only != 'true'" .github/workflows/ci.yml`
  is at least 2 (the template's own comment plus each guarded step) when item 1 names a
  command, or exactly 1 when it does not.
- `.t-workflow/scripts/check-manifest.sh --hash-file AGENTS.md` and
  `.t-workflow/scripts/check-manifest.sh --hash-file .github/workflows/ci.yml` each
  produce the same normalized hash as the same command run against a copy of the file
  with every slot's content stripped back to empty — every edit above landed *inside* a
  slot, so the next sync reports no drift.
- The consumer's own content sits in the slot its heading names: the build command
  under `## Checks` item 1, the project notes under `## Project notes`, only globs (or
  the placeholder) under `### Documentation-only paths` — step 1's alignment check,
  re-read after everything else ran.
- `./.t-workflow/scripts/consistency-check.sh` passes.
