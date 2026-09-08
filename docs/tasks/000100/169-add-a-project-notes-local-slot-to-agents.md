# 169 — Add a project-notes local slot to AGENTS.md
Issue: #169 · Part of: #168

## Asked
A project that already has an agent almost always has a real `CLAUDE.md` (or
`AGENTS.md`, `GEMINI.md`, `.github/copilot-instructions.md`) carrying its own
session-start instructions. The template makes those aliases symlinks to `AGENTS.md`,
which is template-owned, and today `AGENTS.md` has no marked region where a consumer's
own instructions can live and survive a `/t-update` sync — so the adoption script
(initiative #168) has nowhere lossless to move that content. Add one: a `## Project
notes` section at the end of `AGENTS.md`, wrapped in `<!-- local -->` … `<!-- /local -->`
markers and holding a neutral `(reserved: …)` placeholder in this repo, registered in
`docs/architecture/local-slots.md` as a named slot alongside the existing ones.

## Done when
- `AGENTS.md` ends with a `## Project notes` section whose body is exactly one marked
  local region containing a neutral placeholder; the section text above the markers
  says in one sentence what belongs there (a consumer's own session-start
  instructions, kept verbatim by template syncs).
- `docs/architecture/local-slots.md` names the new slot, its count of per-repo places
  is updated, and the placeholder is listed with the others.
- Replacing the placeholder text inside the slot leaves
  `./.t-workflow/scripts/check-manifest.sh --hash-file AGENTS.md` unchanged (proves the
  region strips), demonstrated in the record.
- `./installer/test.sh` passes (the generated project carries the slot unchanged).
- `./.t-workflow/scripts/consistency-check.sh` exits 0.
- A cold review (`/t-review`) reports `readiness: ready` — `AGENTS.md` and
  `docs/architecture/` are protected surfaces (`CONSTITUTION.md` §3), so a plan and
  independent review are both required.

## Explicitly not
- Moving any consumer content into the slot — that is the adoption script's job
  (#172).
- Changing the alias mechanism (`CLAUDE.md` and friends stay symlinks).
- Any other new slot (#170 registers a separate one, sequenced after this task).

## Origin
Inherited from initiative #168 — see its own Origin.

## Verification
none — the plan's `### Validation` names one `human_checks:` item (whether the
one-sentence description is clear and correctly scoped), not a structured
`verification:` list.

## Feedback
none

## Decisions made along the way
- Branched from `wip/168-integration` (not the trunk) and will open the draft PR
  against it, per `/t-drive`'s driven-child convention for initiative #168 — the
  invoking session directed this run at that base (agent, 2026-09-08).
- Blocker #166 judged satisfied under the driven-initiative reading of the blocker
  gate (ADR-009): it is a sibling child of #168, merged into `wip/168-integration`
  with a `readiness: ready` cold review, even though issue #166 itself stays open
  until the aggregate PR reaches the trunk. Verified via
  `.t-workflow/scripts/check-blocker-gate.sh blockers.json --siblings 168
  siblings.json`, which exited 0 (agent, 2026-09-08).
- Read `docs/architecture/adoption.md` (merged by #166) before implementing: its §2
  collision table names this slot as the destination for a real `CLAUDE.md`/
  `AGENTS.md`/`GEMINI.md`/`.github/copilot-instructions.md` moved verbatim, "under a
  heading naming which file it came from" — the placeholder text below stays neutral
  prose consistent with that future use, without pre-building the heading convention
  itself, which is #172's job (agent, 2026-09-08).

## Deviations / notes
- **Manifest-hash demonstration (Done-when requirement).** With the section in place,
  `./.t-workflow/scripts/check-manifest.sh --hash-file AGENTS.md` returned
  `0dfa38d2b0c313c93c2d488be37b7e8af062e4b93049157012ea0a0c626f2301`. The placeholder
  text inside the `<!-- local -->` … `<!-- /local -->` markers was then replaced with
  unrelated content (a `## Moved from CLAUDE.md` heading and a few sentences of
  consumer-specific prose, standing in for what `adopt.sh` (#172) would later move in
  verbatim) and the hash was recomputed: same value,
  `0dfa38d2b0c313c93c2d488be37b7e8af062e4b93049157012ea0a0c626f2301` — proving the
  region strips before hashing. The placeholder was restored to the neutral text listed
  under Done when immediately afterward, and the hash was checked a third time to
  confirm the restoration round-tripped cleanly: same value again (agent, 2026-09-08).
