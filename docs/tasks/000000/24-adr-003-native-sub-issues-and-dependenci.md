# 24 — ADR-003: native sub-issues and dependencies replace body markers
Issue: #24 · Part of: #22

## Asked
Write and ratify ADR-003: replace the machine-read body markers (`Part of: #n`,
`Blocked-by: #n`, in both their inline and issue-form-heading shapes) and the tracking
issue's hand-ticked checklist with GitHub-native relations — sub-issue parent links,
issue dependencies (blockedBy/blocking), and subIssuesSummary for initiative progress.
Decide what stays: `Split from: #n` remains body text (no native equivalent); the
two-working-levels rule (initiative → task) remains although sub-issues allow deeper
nesting; a cancelled blocker remains abandoned-not-satisfied (stateReason check); the
`initiative` label remains the cheap listing key. Name the resilience trade-off:
relations move out of issue bodies, so workflow §10's periodic export must include
sub-issue and dependency relations. Existing repos convert with a one-off script run
against the tracker; no migration code ships in the template.

## Done when
- `docs/adr/003-*.md` exists on `main`, Status: Accepted, with context, rationale,
  alternatives, and revisit triggers (CONSTITUTION.md §2.1).
- `./scripts/consistency-check.sh` exits 0.

## Explicitly not
- No skill, adapter, or issue-template edits here — the adoption task (#29) implements
  this ADR.
- No conversion of existing issues here; that is a tracker-side act, not a tree change.
- No supersession of ADR-001 or edits to ADR-002 — both stay append-only/untouched.

## Decisions made along the way
- none

## Deviations / notes
- none
