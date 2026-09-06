# 141 — Record and propagate external origins
Issue: #141 · Part of: #139

## Asked
Add a generic, optional external-origin record to a task or initiative. An origin
identifies the system and durable URL from which the work arose. It must remain
traceable through the task record, draft PR, review, and final history without making
the external source authoritative for scope or acceptance.

## Done when
- The supported origin shape is documented and machine-readable.
- t-open can record an optional external origin during normal issue creation.
- The issue remains self-sufficient even when the external URL is unavailable.
- t-work carries the origin into the durable task record and draft PR.
- Review and shipping preserve the origin without requiring the external system to be
  available.
- An initiative may have an origin while its child tasks refer to that initiative rather
  than duplicating a new hierarchy.
- Invalid or unsupported origin data fails safely and does not authorize work.
- Existing tasks without an origin behave exactly as before.

## Explicitly not
- Fetching proposal content automatically.
- Treating an external conversation as the task specification.
- Implementing provider-specific Proposarium behavior.
- Replacing native initiative and sub-issue relationships.

## Origin
none

## Decisions made along the way
- The origin shape lives in a new `docs/architecture/external-origin.md` rather than in
  `CONSTITUTION.md`: ADR-010 already added the one operative CONSTITUTION.md §1 pointer
  this decision needs (§1.6), and this task's own field-level grammar is exactly the
  kind of binding-but-mechanical convention `docs/architecture/` already holds (haninaguib,
  2026-09-06).
- The record's `## Origin` section is always present, mirroring the existing
  `## Decisions made along the way` / `## Deviations / notes` "or none" convention,
  rather than an optional heading — this keeps `check-record.sh`'s existing
  every-template-heading-must-appear rule enforcing it with no script change, at the
  cost of every task record (from here on) carrying one more line when there is no
  origin (haninaguib, 2026-09-06).
- Fed a single optional `origin` textarea field into both `.github/ISSUE_TEMPLATE/*.yml`
  forms (system/url as two lines of free text) rather than two separate `system`/`url`
  fields, matching how `non-goals` and `tasks` already carry free-text shape rather than
  one GitHub form field per line (haninaguib, 2026-09-06).
- Verified "origin can never authorize work" and "origin is never fetched" as agent
  checks (`grep -RniE '\borigin\b' .t-workflow/scripts/*.sh` finds no gate reading it;
  `grep -RniE 'curl|wget|http\.get|fetch\(' .claude/skills/t-open/SKILL.md
  .claude/skills/t-work/SKILL.md docs/architecture/external-origin.md` finds nothing)
  rather than leaving ADR-010 §D3/§D7 as prose-only claims (haninaguib, 2026-09-06).

## Deviations / notes
- none
