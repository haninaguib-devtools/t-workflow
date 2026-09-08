# V6 — `CONSTITUTION.md`'s status note gains a local slot

**Introduced:** v0.1.3

## What broke

Before this tag, the **Status note** paragraph at the top of `CONSTITUTION.md` (above
`## 1. Delivery`: "the project is at Phase 0 — only the delivery system exists. Its
stack and domain rules are **not yet decided** …") was template-owned text outside any
`<!-- local -->` slot (`docs/architecture/local-slots.md`), although what it states is
the *consumer's* project state, not the template's. Every consumer that ratifies its
stack has to rewrite it — the moment §4 stops being a placeholder, "not yet decided" is
false — and the only place to do so was unmarked template text. That edit registered as
drift: `check-manifest.sh` flagged it, and `/t-update` either refused (a pinned
consumer) or, on a first adoption, overwrote it with the Phase 0 wording (issue #186's
own account: `t-preview/t-preview` aborted a `/t-update` dry run rather than lose the
sentence its task #22 had written). Starting at this tag the paragraph sits inside its
own slot, with the Phase 0 sentence as the template's placeholder.

An ordinary sync (`.claude/skills/t-update/SKILL.md` step 7) already splices
`CONSTITUTION.md` by its markers, because §3 and §4 carry slots — but the splice keeps
the *current* content of each marked region, and the consumer's status note is not
inside a marked region yet: the sync writes the target's file with the placeholder in
the new slot and the consumer's own sentence is gone. This migration relocates it.

## Instructions for the upgrading agent

Read the pre-sync file from history (`git show HEAD:CONSTITUTION.md`), never from the
working tree — by the time migrations run, step 7 has already written the target-tag
file. Nothing is committed until step 9, so `HEAD` is still the pre-sync content.

1. Read the consumer's pre-sync `CONSTITUTION.md` (`git show HEAD:CONSTITUTION.md`). If
   it errors (the file did not exist pre-sync — a first-adoption sync with nothing to
   migrate), skip this migration entirely; the ordinary sync's placeholder is correct.
2. Extract the consumer's status-note text: everything between the file's opening
   paragraph (the one beginning "The invariants of this project") and the
   `## 1. Delivery` heading, with the blank lines around it trimmed. That is the text
   the new slot holds — normally one paragraph beginning `**Status note:**`, but
   whatever the consumer wrote there, label or not. If there is nothing between the
   two, the consumer removed the paragraph altogether — treat the extracted text as
   empty.
3. Compare it with the placeholder the sync just wrote into the new slot (the Phase 0
   sentence, the region between the markers above `## 1. Delivery` in the freshly
   synced file). If they are byte-identical, the consumer never rewrote it — say so
   in the report and stop; nothing needs moving. No manifest tag or old template
   version is needed for this comparison, so it is followable on a first adoption
   (no manifest yet — the case that produced this migration) as well as on a pinned
   consumer's sync.
4. Otherwise, re-open the freshly synced `CONSTITUTION.md` and replace the content of
   the slot above `## 1. Delivery` — the region between the first `<!-- local -->` /
   `<!-- /local -->` pair that appears before that heading, found by the heading, never
   by counting the file's pairs — with the consumer's paragraph from step 2, verbatim.
   An empty extraction (step 2) leaves the two markers with nothing between them.
5. Report, in the update's closing report, the paragraph that was relocated (or that
   the consumer's matched the old template's and nothing was moved), so a human can
   confirm nothing was silently dropped.

## Done-when

- `.t-workflow/scripts/check-manifest.sh --hash-file CONSTITUTION.md` produces the same
  normalized hash as the same command run against a copy of the file with the
  status-note slot's content stripped back to empty — i.e. the relocated paragraph
  landed *inside* the slot, not outside it (an outside landing would register as drift
  at the very next sync, the failure this migration exists to end).
- The text step 2 extracted appears, unchanged, between the markers of the slot above
  `## 1. Delivery`:
  `awk '/^## / { exit } /^<!-- local -->$/ { f=1; next } /^<!-- \/local -->$/ { f=0 } f' CONSTITUTION.md`
  prints exactly that paragraph (or nothing, when the consumer had removed it).
- `./.t-workflow/scripts/consistency-check.sh` passes.
