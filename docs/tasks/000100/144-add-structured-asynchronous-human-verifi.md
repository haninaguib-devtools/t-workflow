# 144 — Add structured asynchronous human verification
Issue: #144 · Part of: #139

## Asked
Represent human verification as a real workflow period that may span several sessions
or days. A task must be able to wait for a contributor, maintainer, domain expert, or
another named role to exercise a preview and provide evidence before it becomes
eligible for `/t-ship`.

## Done when
- Human verification entries can state who or which role must verify, what must be
  checked, whether it is required, and what evidence is expected.
- The workflow distinguishes pending verification, successful verification, rejected
  verification, and explicitly accepted residual risk.
- Verification evidence records the tested revision or commit.
- A new commit invalidates verification when the changed work could affect it.
- `/t-ship` blocks on unresolved required verification.
- Acknowledging a risk is explicit and is not represented as a successful check.
- The durable task record preserves the verification outcome and evidence.
- Existing tasks with ordinary human checks remain supported or have a documented
  migration path.

## Explicitly not
- Requiring external verification for every task.
- Allowing an external service to merge.
- Replacing independent agent review.
- Defining how a project deploys a preview — sibling #146's job.

## Verification
none — this task defines the schema itself; it declares no `verification:` entry of
its own.

## Decisions made along the way
- **No new ADR** (haninaguib, via the driving session, 2026-09-06): the issue's own
  Scope line omits `docs/adr/`, and ADR-010 (merged into this integration branch as
  #140) already licenses this task to invent D4's "concrete mechanism" for accepting
  residual risk. Adding a new blocking gate is a tightening (`docs/workflow.md`
  §11.2/§11.3), not a loosening, so it needs no ADR-grade rationale on its own; if
  review finds ADR-010's boundary unworkable for this mechanism, the correct fallback
  is reopening ADR-010, not inventing a second ADR here.
- **Four states, named exactly as Done-when's own words**: `pending`, `verified`,
  `rejected`, `risk-accepted` (`docs/architecture/verification.md`). `risk-accepted` is
  a resolution, not a pass, and is never worded as `verified` anywhere it is
  surfaced — the record, `check-verification-gate.sh`'s own messages, and `/t-ship`'s
  confirmation-gate evidence line all keep the two visibly distinct.
- **Invalidation via an optional `scope:` glob per entry, defaulting to whole-task**:
  an entry with no `scope:` is stale whenever the recorded revision differs from the
  new head, matching ADR-010 §D7's fail-toward-absent posture; an entry with `scope:`
  is stale only if the diff since its revision touches one of those globs. The
  semantic "could this affect it?" judgment is `/t-work`'s (it has the diff and can
  reason about it, the same place scope-drift and deviation judgments already live);
  `/t-ship`'s own gate independently re-derives `stale` as a mechanical backstop rather
  than trusting the record's `state` field blindly — mirroring how
  `check-review-gate.sh` already backstops a review's own `isolation:` line against the
  head commit's real timestamp instead of taking the line's word for it.
- **`check-verification-gate.sh` takes a small JSON shape, not the raw markdown
  record** (haninaguib, 2026-09-06): matches `check-blocker-gate.sh`/
  `check-review-gate.sh`'s existing pattern — the calling skill (here, `/t-ship`)
  extracts structured fields from a live source (there, the tracker/forge; here, the
  task record) into JSON, and the script stays pure and fixture-testable with no
  markdown parsing of its own.
- **No change to `check-record.sh` or `.github/workflows/ci.yml`**: `check-record.sh`
  already derives required record sections from `TEMPLATE.md`'s own `## ` headings, so
  the new `## Verification` heading is enforced there for free; `plumbing-test.sh` and
  `consistency-check.sh` already run generically in CI without per-script wiring, so
  the new gate script needed no CI changes either.
- **`human_checks:` is untouched** — the migration path Done-when's last bullet asks
  for is that a plan/record with no `verification:`/`## Verification` content behaves
  exactly as before, which is what "optional, additive" already gives for free; no
  separate procedure was written because none was needed.

## Deviations / notes
- Noted at plan time (`/t-plan 144`'s report): sibling #141 ("Record and propagate
  external origins") is independent of this task (both blocked only by #140) but its
  own Scope also names "task records" and "workflow documentation," so it is likely to
  touch `docs/tasks/TEMPLATE.md` and `docs/workflow.md` too. Not a refusal — flagged so
  whichever of us merges into `wip/139-integration` second rebases past the other's
  edit to those two files.
