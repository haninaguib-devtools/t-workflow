# 170 — Make ci.yml's push-trigger trunk name a local slot
Issue: #170 · Part of: #168

## Asked
A repository whose trunk is not called `main` cannot adopt t-workflow cleanly, because
`.github/workflows/ci.yml` still hardcodes `main` on its `push:` trigger
(`branches: [main]`) and there was no local slot for that line: editing it by hand was
drift outside a slot, which `check-manifest.sh` would fail, and `trunk-ref.sh` cannot
help since a workflow trigger is static YAML. This task makes that line a local slot
(`docs/architecture/local-slots.md` convention, `# <!-- local -->` markers as the
file's other two slots use) so the adoption script (initiative #168, #172) and a
consumer on `master` or `trunk` can set it inside the markers, and a template sync
carries it forward. It ships a migration for an existing consumer that has that line
hand-edited today, and corrects the stale sentence in both READMEs claiming `main` is
written literally in the skills and scripts.

## Done when
- `ci.yml`'s `push:` trigger's `branches:` line sits inside its own marked local
  region, with a comment naming it as a slot and what a consumer puts there; the
  template's value inside the markers stays `main`.
- `docs/architecture/local-slots.md` names the new slot (now three in `ci.yml`), its
  count is updated, and the placeholder is listed.
- `migrations/V4__ci-trunk-branch-slot.md` exists in `docs/architecture/migrations.md`'s
  shape with a runnable Done-when, and captures the pre-sync value per `/t-update`
  step 7's rule for a file moving content into markers.
- `README.md` §Notes and `installer/templates/README.md` §Notes no longer say the
  trunk name is hardcoded.
- `./.t-workflow/scripts/check-manifest.sh --hash-file .github/workflows/ci.yml` is
  unchanged when the branch name inside the slot is changed, demonstrated in the
  record.
- `./installer/test.sh` passes; `./.t-workflow/scripts/consistency-check.sh` exits 0.
- A cold review (`/t-review`) reports `readiness: ready` — `.github/`,
  `docs/architecture/`, `README.md`, and `installer/` are protected surfaces
  (`CONSTITUTION.md` §3).

## Explicitly not
- Touching `review-gate.yml` (it has no push trigger).
- Any change to `trunk-ref.sh` or `github-bootstrap.sh`, which already resolve the
  trunk at run time.

## Origin
none

## Verification
none — the plan carries only `human_checks:`, not a structured `verification:` list.

## Feedback
none

## Decisions made along the way
- Wrapped `push:`'s `branches:` line in the same `# <!-- local -->` / `# <!-- /local
  -->` comment-marker form the file's other two slots already use, with an explanatory
  comment block above the marker (matching the `timeout-minutes` slot's own style)
  rather than repeating the explanation inside it (agent, 2026-09-08).
- Wrote `docs/architecture/local-slots.md`'s opening count as **ten** — this branch was
  cut from `wip/168-integration` before #169's own project-notes-slot addition had
  landed there, so the base visible in this worktree is the pre-#169 "Nine places." Per
  the driving session's explicit instruction, treated this task's own edit as
  nine-plus-this-one=ten rather than guessing at #169's eventual text, and left any
  mismatch between the two siblings' edits for `/t-review`/the aggregate PR to catch
  (agent, 2026-09-08).
- Modeled `migrations/V4__ci-trunk-branch-slot.md` closely on `migrations/V1__ci-yml-
  local-slots.md` (the closest precedent — a slot newly added to `ci.yml` with an
  existing consumer's un-marked customization on that exact line) rather than V2/V3's
  shape, since V1's is the one migration that already solves "relocate an unmarked
  value on the very line a new marker now wraps" (agent, 2026-09-08).
- Reworded both READMEs' §Notes without ever using the substring "hardcod" (used
  "written in literally" instead), because the plan's own validation command is a
  literal `grep -i 'hardcod' README.md installer/templates/README.md` expected to
  return no match — not merely no match on the old sentence specifically (agent,
  2026-09-08).

## Deviations / notes
- The predicted collision materialized: sibling task #169 merged its own
  `docs/architecture/local-slots.md` edit (the `AGENTS.md` §Project notes slot,
  "Nine places" → "Ten") into `wip/168-integration` after this branch was cut,
  and the independent review's own low finding, before this happened. GitHub then
  reported PR #177 as `mergeStateStatus: DIRTY` / `mergeable: CONFLICTING` against
  `wip/168-integration`. Resolved by fetching `origin` and merging (not rebasing —
  this branch was already pushed and reviewed) `origin/wip/168-integration` into
  `wip/170-make-ci-yml-s-push-trigger-trunk-name-a` (merge commit `392aaf0`). The
  only real conflict was `docs/architecture/local-slots.md`'s opening paragraph and
  placeholder list, where both siblings had independently written "Nine"→"Ten" for
  their own one new slot. Resolved by reading `origin/wip/168-integration`'s own
  post-#169 content first, then adding this task's ci.yml trunk-name slot on top of
  it rather than reintroducing #169's slot a second time — both new slots (the
  `AGENTS.md` §Project notes slot and `ci.yml`'s `push:`-trigger trunk-name slot)
  are now listed, and the count correctly reads **eleven**, not ten. `AGENTS.md`
  and the new `docs/tasks/000100/169-add-a-project-notes-local-slot-to-agents.md`
  record came along automatically as part of the merge — neither was hand-edited by
  this task. Re-ran `./installer/test.sh` (46 passed, 0 failed) and
  `./.t-workflow/scripts/consistency-check.sh` (passed) after the resolution; both
  still pass. Re-verified `.github/workflows/ci.yml`'s manifest hash is unchanged
  by the merge (`35c3c8c29f9b8cd85085f9d3ddb9923fb04542a94ba8fe282079bb9e0c66ff50`,
  same as before — #169 never touched `ci.yml`) (agent, 2026-09-08).

## Checks demonstrated
- `./.t-workflow/scripts/check-manifest.sh --hash-file .github/workflows/ci.yml` before
  changing the branch name inside the new slot:
  `35c3c8c29f9b8cd85085f9d3ddb9923fb04542a94ba8fe282079bb9e0c66ff50`
- Changed the slot's value to `branches: [trunk]` and re-ran the same command: same
  hash, `35c3c8c29f9b8cd85085f9d3ddb9923fb04542a94ba8fe282079bb9e0c66ff50` — confirms
  the marked region strips correctly before hashing, so a consumer's own branch name
  never registers as drift against the manifest. Restored the template's own `main`
  value afterward.
