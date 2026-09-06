# V3 — `CONSTITUTION.md` §3 and `protected-paths.sh` gain local slots

**Introduced:** v0.0.16 (best guess — the next tag cut after #134 merges; confirm and
correct this line once a maintainer actually cuts it, since this file has shipped in no
tag yet and is not "edited after shipping" until it does)

## What broke

Before this tag, neither `CONSTITUTION.md` §3's protected-path bullet list nor its
executable twin `.t-workflow/scripts/protected-paths.sh`'s `patterns` array carried a
`<!-- local -->` slot (`docs/architecture/local-slots.md`), so a consumer that wanted to
protect its own application-specific path (a migration directory, a domain config
directory) had no sanctioned place to put it and wrote it as plain unmarked text
directly into both template-owned files (issue #134's own motivating account:
`thyme-clinic/thyme` had done exactly this for its Flyway migration files). Starting at
this tag, both files carry one slot each — `CONSTITUTION.md` §3's own bullet list, and
`protected-paths.sh`'s `patterns` array (in the `#`-prefixed line-comment marker form, a
bash array being unable to parse a bare `<!-- local -->` line).

An ordinary sync (`.claude/skills/t-update/SKILL.md` step 7) decides "copy the target
file whole" versus "splice, keeping the region between markers" by checking whether the
file's **current** (pre-sync) content already carries a `<!-- local -->` marker. A
consumer syncing across this tag with an existing unmarked bullet/pattern has no marker
in either file yet — the slot predates the sync — so the ordinary rule reads both files
as unmarked and copies the target's version in directly, silently dropping the
consumer's own protected-path bullet and pattern. That is exactly the loss this
migration exists to prevent: a plain file sync is not enough here because the
consumer's own state (their unmarked addition) needs to be *relocated* into the new
slots, not merely diffed against.

## Instructions for the upgrading agent

Run this **before** step 7's ordinary per-file copy/splice touches `CONSTITUTION.md` or
`.t-workflow/scripts/protected-paths.sh`, or rely on reading history rather than the
working tree — either is safe, since nothing is committed until step 9 (`git show
HEAD:<path>` returns the pre-sync content throughout step 7 regardless of what the
working copy currently holds).

1. Read the consumer's pre-sync files: `git show HEAD:CONSTITUTION.md` and
   `git show HEAD:.t-workflow/scripts/protected-paths.sh`. If either errors (the file
   didn't exist pre-sync — a very old consumer, or a first-adoption sync with nothing to
   migrate), skip this migration's remaining steps for that file entirely; the ordinary
   sync in step 7 already does the right thing for a file that never existed.
2. Read that same tag range's **old** template versions of both files — the versions at
   the tag named in the current manifest's `tag` field, fetched into the scratch clone
   from step 2 (`git -C <scratch-clone> fetch --depth 1 origin tag <old-tag>`, then
   `git -C <scratch-clone> show <old-tag>:CONSTITUTION.md` and `...
   :.t-workflow/scripts/protected-paths.sh`).
3. Diff each pre-sync consumer file (step 1) against its old template counterpart (step
   2). If a diff is empty, the consumer never customized that file at all — skip the
   rest of this migration for it; the ordinary sync's neutral placeholder in the new
   slot is already correct.
4. From a non-empty `CONSTITUTION.md` diff, extract every added or changed line inside
   `## 3. Protected surfaces` that is a bullet (`- ...`) or one of its indented
   continuation lines, and is not already present in the old template's own §3 bullets.
   A bullet the consumer inserted in the *middle* of the template's own list, rather
   than appended near the end, is not this migration's job to relocate — flag it in the
   report instead of guessing where it belongs.
5. From a non-empty `protected-paths.sh` diff, extract every added or changed line
   inside the `patterns=( ... )` array that is not already present in the old
   template's own array entries, in the same way.
6. Let step 7's ordinary sync write the new target-tag `CONSTITUTION.md` and
   `protected-paths.sh` (each with its own new, empty slot holding the template's
   neutral placeholder comment).
7. Re-open both files and, only for the pieces steps 4/5 actually found:
   - insert the extracted `CONSTITUTION.md` bullet(s), verbatim, between the `<!-- local
     -->` / `<!-- /local -->` pair inside `## 3. Protected surfaces`, replacing the
     placeholder sentence there;
   - insert the extracted `protected-paths.sh` pattern(s), verbatim, between the
     `# <!-- local -->` / `# <!-- /local -->` pair inside the `patterns=( ... )` array,
     replacing the placeholder comment there, each as its own quoted array element.
8. Report, in the update's closing report, exactly what was relocated (each bullet and
   each pattern) so a human can confirm nothing was silently dropped — and separately
   report anything steps 4/5 flagged as not auto-relocatable.

## Done-when

- `bash .t-workflow/scripts/protected-paths.sh --list` still runs without a syntax error
  after relocation (a malformed inserted pattern would break the array).
- `.t-workflow/scripts/check-manifest.sh --hash-file CONSTITUTION.md` and
  `.t-workflow/scripts/check-manifest.sh --hash-file .t-workflow/scripts/protected-paths.sh`
  each produce the same normalized hash as the same command run against a copy of the
  file with its new slot's content stripped back to empty — i.e. every relocated line
  landed *inside* the slot, not outside it (an outside landing would register as drift
  at the very next sync, the same failure mode this migration exists to prevent).
- `./.t-workflow/scripts/consistency-check.sh` passes — every relocated bullet has its
  relocated pattern and vice versa (check 9's own "both ways" symmetry), the same bar an
  ordinary task's diff is held to.
- Every bullet step 4 found appears, unchanged, inside the new `CONSTITUTION.md` slot,
  and every pattern step 5 found appears, unchanged, inside the new
  `protected-paths.sh` slot.
