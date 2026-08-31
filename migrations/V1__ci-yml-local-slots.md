# V1 — ci.yml gains local slots

**Introduced:** v0.0.10 (best guess — the next tag cut after #118 merges; confirm and
correct this line once a maintainer actually cuts it, since this file has shipped in no
tag yet and is not "edited after shipping" until it does)

## What broke

`.github/workflows/ci.yml` previously carried no `<!-- local -->` slots
(`docs/architecture/local-slots.md`), so every consumer that customized it — at
minimum the `checks` job's `timeout-minutes`, often trailing build/manifest-check
steps — did so directly in the template-owned text, with nothing marking that content
as theirs. Starting at this tag, `ci.yml` carries two slots: the `timeout-minutes`
line, and an extension point at the end of `steps:` (#118).

An ordinary sync (`.claude/skills/t-update/SKILL.md` step 7) decides "copy the target
file whole" versus "splice, keeping the region between markers" by checking whether
the file's **current** (pre-sync) content already carries a `<!-- local -->` marker. A
consumer syncing across this tag has no such marker in their current `ci.yml` — it
predates the slot existing at all — so the ordinary rule reads it as an unmarked file
and copies the target's version in directly, silently dropping the consumer's timeout
override and any trailing steps. That is exactly the loss this migration exists to
prevent: a plain file sync is not enough here because the consumer's own state (their
customization, sitting outside any marker) needs to be *relocated* into the new
markers, not merely diffed against.

## Instructions for the upgrading agent

Run this **before** step 7's ordinary per-file copy/splice touches
`.github/workflows/ci.yml`, or rely on reading history rather than the working tree —
either is safe, since nothing is committed until step 9 (`git show HEAD:<path>` returns
the pre-sync content throughout step 7 regardless of what the working copy currently
holds).

1. Read the consumer's pre-sync file: `git show HEAD:.github/workflows/ci.yml`.
   If this errors (the file didn't exist pre-sync — a very old consumer, or a
   first-adoption sync with nothing to migrate), skip this migration's remaining steps
   entirely; the ordinary sync in step 7 already does the right thing for a file that
   never existed.
2. Read that same tag range's **old** template `ci.yml` — the version at the tag
   named in the current manifest's `tag` field, fetched into the scratch clone from
   step 2 (`git -C <scratch-clone> fetch --depth 1 origin tag <old-tag>`, then
   `git -C <scratch-clone> show <old-tag>:.github/workflows/ci.yml`).
3. Diff the pre-sync consumer file (step 1) against the old template file (step 2). If
   the diff is empty, the consumer never customized `ci.yml` at all — skip the rest of
   this migration; the ordinary sync's neutral placeholders in the new slots are
   already correct.
4. From a non-empty diff, extract:
   - the consumer's `timeout-minutes:` value on the `checks` job, if the diff shows one
     (a changed value on that exact line under `jobs: checks:`);
   - any step(s) present in the consumer's file after the old template's final step but
     absent from the old template entirely (its own trailing build/manifest-check
     steps). A step the consumer inserted in the *middle* of the template's own steps,
     rather than appended at the end, is not this migration's job to relocate — flag it
     in the report instead of guessing where it belongs.
5. Let step 7's ordinary sync write the new target-tag `ci.yml` (with its two slots,
   holding the template's neutral placeholders: `timeout-minutes: 10` and an empty
   trailing region).
6. Re-open `.github/workflows/ci.yml` and, only for the pieces step 4 actually found:
   - replace `timeout-minutes: 10` between the `# <!-- local -->` / `# <!-- /local -->`
     pair around it with `timeout-minutes: <the extracted value>`;
   - insert the extracted trailing step(s), verbatim, between the
     `# <!-- local -->` / `# <!-- /local -->` pair at the end of `steps:`, indented to
     match the surrounding steps (6 spaces, the same level as the other `- name: …`
     entries).
7. Report, in the update's closing report, exactly what was relocated (the timeout
   value, and the name of each relocated step) so a human can confirm nothing was
   silently dropped — and separately report anything step 4 flagged as not
   auto-relocatable.

## Done-when

- `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"` exits 0
  — the file is still valid YAML after relocation.
- `.t-workflow/scripts/check-manifest.sh --hash-file .github/workflows/ci.yml` produces
  the same normalized hash as `.t-workflow/scripts/check-manifest.sh --hash-file` on a
  copy of the file with both slots' content stripped back to empty — i.e. every
  relocated line landed *inside* a slot, not outside it (an outside landing would
  register as drift at the very next sync, the same failure mode this migration exists
  to prevent).
- The consumer's pre-sync `timeout-minutes` value (if step 4 found one) appears,
  unchanged, inside the new `timeout-minutes` slot.
- Every trailing step step 4 found appears, unchanged, inside the new trailing slot, in
  its original order.
