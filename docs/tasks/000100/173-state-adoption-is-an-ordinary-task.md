# 173 — State that adoption is an ordinary task in the constitution, README, AGENTS.md, and an ADR
Issue: #173 · Part of: #168

## Asked
Say, in the places a person and an agent read, that an existing repository adopts
t-workflow through an ordinary protected task — never through the genesis-style
exception. Before this task: `CONSTITUTION.md` §3's genesis paragraph reads as if the
only way in is before a repository's first commit; `README.md` has no adoption section;
`AGENTS.md`'s "never edit the tree outside that task's own `/t-work` session" convention
never says that `installer/adopt.sh`, run on the adoption task's own branch, is that
task's work stage, the way `/t-update`'s own sync procedure already is for a sync.

## Done when
- `CONSTITUTION.md` §3's genesis paragraph gains the sentence and nothing else in the
  file changes.
- `README.md` has the adoption section, consistent with `installer/adopt.sh --help`.
- `AGENTS.md` §Conventions' first bullet names the adoption script as the adoption
  task's work stage.
- `docs/adr/011-*.md` exists in the ADR shape (context, decision, rationale,
  alternatives, consequences, revisit triggers), and `CONSTITUTION.md` or `AGENTS.md`
  carries its one-line rule with a pointer, per `CONSTITUTION.md` §2.3.
- `./.t-workflow/scripts/consistency-check.sh` exits 0.
- A cold review (`/t-review`) reports `readiness: ready` — every file here is a
  protected surface (`CONSTITUTION.md` §3).

## Explicitly not
- `installer/templates/README.md` — a generated project has already had its genesis
  and never adopts.
- Any change to the genesis exception's own wording or end-point.

## Origin
none

## Verification
none

## Decisions made along the way
- Ran as a `/t-drive`-orchestrated child of initiative #168: branched from
  `wip/168-integration` (which already carries #166/#169/#170/#171/#172), and the
  draft PR targets `wip/168-integration` rather than the trunk, per `/t-drive` Phase 2
  steps 3–4 (agent, 2026-09-08).
- Blocker gate (#166, #172) satisfied by their driven merges into
  `wip/168-integration` with `readiness: ready` reviews (PR #175, PR #179) — verified
  with `check-blocker-gate.sh --siblings 168` before starting (agent, 2026-09-08).
- Confirmed `docs/adr/011-*.md` is still the next free ADR number (highest existing is
  010) before writing it (agent, 2026-09-08).
- The one sentence added to `CONSTITUTION.md` §3's genesis paragraph doubles as
  §2.3's required one-line rule for ADR-011 (ends with the `(ADR-011)` pointer),
  mirroring how ADR-010's own one-line rule was folded into §1 rather than added as a
  second, separate sentence (agent, 2026-09-08).
- `AGENTS.md` §Conventions' first bullet gains one clause (not a new sentence or
  bullet), inserted into the existing "Never edit the tree outside that task's own
  `/t-work` session" sentence, naming `installer/adopt.sh` run on the adoption task's
  own branch as that task's work stage, the same way `/t-update`'s own sync procedure
  already counts as its task's work stage without being `/t-work` itself (agent,
  2026-09-08).
- Verified the `README.md` §Adopting an existing repository section's command and
  flags against the actual, now-merged `installer/adopt.sh --help` output (not #172's
  original issue body) — matches exactly: `--ref`, `--source`, `--template`,
  `--build-command`, `--dry-run`, `-h`/`--help` (agent, 2026-09-08).

## Deviations / notes
- **Fix pass (agent, 2026-09-08), addressing `/t-review`'s one blocker finding on
  PR #180.** The first commit's `CONSTITUTION.md` sentence and the matching
  `docs/adr/011-*.md` Consequences bullet cited `` `README.md` §Adopting an existing
  repository `` as a named-section reference. Both files are template-owned and ship
  into every generated and adopted project; `consistency-check.sh`'s named-section
  check (§2b) resolves that citation against the *destination* project's own
  `README.md` — which is `installer/templates/README.md` for a generated project and
  a consumer's own untouched file for an adopted one, neither of which carries an
  "Adopting an existing repository" heading (out of this task's own Non-goals to add
  to the former; adoption never touches the latter). `installer/test.sh` confirmed
  this concretely: 2 of 96 assertions failed (both `consistency-check.sh` runs, one
  inside the generated-project fixture, one inside the adopted fixture), matching the
  red `installer` CI job the reviewer found on PR #180. Fixed by rewording both
  citations to drop the `§`-prefixed named-section pattern — `` `installer/adopt.sh`,
  `README.md`'s own adoption instructions `` in `CONSTITUTION.md`, and a plain quoted
  phrase (no `§`) in the ADR — which keeps the same pointer without asserting a
  section heading that only exists in this template repository's own `README.md`.
  Re-ran `./.t-workflow/scripts/consistency-check.sh` (PASS) and `bash
  installer/test.sh` (96 passed, 0 failed) after the fix.
- **The flagged `README.md` §Bootstrapping gap is not resolved by this task, and
  cannot be resolved naturally within its scope.** #172's own record and its
  independent reviewer both flagged that `CONSTITUTION.md` cites `README.md
  §Bootstrapping`, and `consistency-check.sh`'s named-section check (§2b) resolves
  that citation against headings in *this repository's own* `README.md` — but
  `installer/adopt.sh` never touches a consumer's `README.md` (`docs/architecture/adoption.md`
  §2: "`README.md`, the consumer's `LICENSE` — Never touched, in either direction").
  So a real consumer's own pre-existing `README.md`, copied nowhere by adoption, almost
  never carries a `## Bootstrapping`/`### Bootstrapping` heading, and
  `consistency-check.sh` genuinely fails on a real adopted repository until one is
  added by hand. This task's own new `README.md` section
  (§Adopting an existing repository) is added to *this template's* `README.md`, which
  is never copied into a consumer's tree either — so it does not touch, and cannot
  incidentally fix, the gap. Flagged a third time (originally #172's record, confirmed
  independently by #172's cold reviewer, now here) — worth its own follow-up issue,
  proposed to the human rather than opened here (`AGENTS.md` §Conventions' tracker-write
  rule): something like "Give an adopted consumer's own `README.md` a `## Bootstrapping`
  (or renamed) heading `consistency-check.sh` can resolve, or relax the check for an
  adopted repository specifically." Not opened by this task.
- Scratchpad files this session wrote at
  `/tmp/claude-1000/.../scratchpad/blockers.json` and `siblings.json` (used only to
  run `check-blocker-gate.sh` before branching) were later overwritten on disk by a
  concurrent sibling `/t-drive` child agent sharing the same scratchpad directory —
  noted here only because the gate had already run and passed before that happened;
  no re-run was needed and none of this task's actual scope files were affected
  (agent, 2026-09-08).
