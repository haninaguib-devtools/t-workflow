# 186 — Move CONSTITUTION.md's status note into a local slot so a consumer's project-state wording survives a sync
Issue: #186

## Asked
A consumer that ratifies its stack has to rewrite the sentence at the top of
`CONSTITUTION.md` that says its stack is "not yet decided" — and today that rewrite is
treated as damage: the manifest check flags it as drift, and a template sync either
refuses to run or silently puts the Phase 0 wording back. The sentence describes the
consumer's project, not the template, so it belongs to the consumer. Give it its own
`<!-- local -->` slot, with the template's current Phase 0 sentence as the
placeholder, so a consumer's own wording survives every sync the same way its §3
bullets and §4 rules already do; update the slot inventory; ship a migration that moves
an already-rewritten sentence into the new slot; and decide what to do about the one
other sentence the same dry run flagged (the `ci.yml` paragraph closing `AGENTS.md`
§Checks, which also goes stale once a consumer has added check 1).

## Done when
- `CONSTITUTION.md`'s status note sits inside a `<!-- local -->` / `<!-- /local -->`
  pair, with the existing Phase 0 sentence as the placeholder; nothing else in the file
  moves.
- `docs/architecture/local-slots.md` names the new slot in its count and its
  placeholder list; `installer/adopt.sh` still writes every `CONSTITUTION.md` slot to
  the right place (it writes none — it copies the template's file whole and refuses on
  an existing one — so no ordinal changes).
- `migrations/V6__*.md` exists, following `docs/architecture/migrations.md`: reads the
  pre-sync note via `git show HEAD:CONSTITUTION.md`, relocates a customized one into
  the new slot, skips when the sentence still matches the old template's, and its
  Done-when verifies the text landed inside the slot.
- `.t-workflow/scripts/check-manifest.sh --hash-file CONSTITUTION.md` is unchanged by
  editing the slot's content.
- `./.t-workflow/scripts/consistency-check.sh` and `.t-workflow/scripts/plumbing-test.sh`
  pass.
- The `AGENTS.md` §Checks closing-sentence question is decided and recorded.

## Explicitly not
- Changing what the placeholder says for the template itself — the Phase 0 wording
  stays correct for this repo.
- Any consumer-side fix: `t-preview` restores its own wording by re-running `/t-update`
  once a tag carrying this change exists (v0.1.3, cut right after this merges).
- Slotting any other template paragraph. The general rule this task adds to
  `docs/architecture/local-slots.md` (consumer-state prose is slotted or made generic)
  is the guard against the next one; auditing every owned file for further instances is
  not done here.

## Origin
system: t-preview/t-preview first-adoption `/t-update` dry run (aborted) / url: https://github.com/t-preview/t-preview/pull/28

## Verification
none

## Feedback
none

## Decisions made along the way
- The `AGENTS.md` §Checks closing paragraph is **reworded, not slotted** (the
  generic-pointer idiom in `local-slots.md`): it no longer says check 1 is absent
  "today" and tells the reader to "add it once the stack exists"; it now says check 1
  runs in `ci.yml` whenever item 1 names a command, as the guarded step in the trailing
  slot that `installer/adopt.sh --build-command` writes. That sentence is true for a
  consumer with a build, one without, and the template itself, so it needs no slot.
  (agent, 2026-09-08)
- The status-note slot is found by the heading below it (`## 1. Delivery`), never by
  its ordinal — migration V6, the new plumbing-test case, and `local-slots.md` all say
  so. `installer/adopt.sh` addresses only `AGENTS.md`, `.gitignore` and `ci.yml` pairs
  by ordinal and never writes `CONSTITUTION.md` slots, so it is untouched. (agent,
  2026-09-08)
- `local-slots.md` gains the rule behind this task, so the class does not recur one
  paragraph at a time: template prose that states something about the consumer's own
  state is either slotted (with the template's wording as placeholder) or worded to
  stay true for every consumer, chosen in the task that writes the sentence, and an
  unmarked consumer-state sentence is a review finding. (agent, 2026-09-08)
- V6's `Introduced:` line says `v0.1.3` outright rather than "best guess": this
  session cuts that tag immediately after the merge, on the human's standing
  instruction to close #185 and #186 end to end. (haninaguib, 2026-09-08)

## Deviations / notes
- Ride-along, listed here: `migrations/README.md` and `docs/architecture/migrations.md`
  both still said "No migration files exist yet" with V1–V5 (now V6) in the directory —
  the staleness #183's closing report proposed as its own issue. Both are documents
  about migrations, this task adds one, and the fix is one sentence each, so it rides
  here rather than as a seventh issue.
- The human directed this task to run without confirmation stops (plan, review, ship
  and tag), on the record of their own message in this session; every gate CI enforces
  is still satisfied — plan section on the issue, record in the PR, cold review by a
  fresh subagent, checks run at the head commit.
- check 1: `AGENTS.md` §Checks item 1 names no command in this repository, so there is
  nothing to run or skip; this diff is not documentation-only in any case
  (`plumbing-test.sh` is in it).
