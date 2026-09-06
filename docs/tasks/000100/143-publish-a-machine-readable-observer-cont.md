# 143 — Publish a machine-readable observer contract
Issue: #143 · Part of: #139

## Asked
Give a system such as Proposarium a stable, read-only way to watch t-workflow's
progress — without it ever having to guess at meaning by reading Goal/Done-when prose,
and without it ever becoming a second place where scope, review, or merge decisions
live. The contract exposes identifiers and derived lifecycle state; issue bodies,
plans, reviews, checks, and GitHub's own native relationships stay the one place any
of that is actually decided.

## Done when
- An observer adapter document defines supported events, identifiers, revisions, and
  state transitions.
- Stable machine-readable markers are available where GitHub event payloads alone
  cannot reliably correlate the initiative, task, PR, origin, and commit.
- Human-facing issue and PR content remains readable without interpreting the
  markers.
- Markers contain identifiers and derived state only; they do not duplicate binding
  scope, acceptance criteria, or review decisions.
- Consumers can detect superseded commits and stale evidence.
- The contract documents delivery guarantees, retries, duplicate events, ordering, and
  temporary observer outages.
- A convenience form such as `t-open --from <origin-url>` is provided if it can be
  added without creating a second origin path.
- The adapter remains forge-neutral in concept while documenting the current GitHub
  representation.

## Explicitly not
- Implementing an observer service.
- Sending commands from an observer into t-workflow.
- Making Proposarium required.
- Copying complete issue conversations into machine-readable markers.

## Origin
none

## Verification
none — this task declares no `verification:` entry of its own.

## Feedback
none — no feedback pass has run against this task itself.

## Decisions made along the way
- **`docs/architecture/collaboration-state.md` is left untouched, despite the plan
  listing it as an Allowed path** (haninaguib, 2026-09-06): the plan anticipated adding
  a one-line pointer there to "resolve" its own Revisit-triggers bullet naming #143.
  Rereading the two already-merged siblings that faced the identical situation —
  `docs/architecture/external-origin.md`'s Revisit-triggers bullet still names #146 and
  #143 in the future tense, unedited, after both landed; `docs/architecture/
  feedback-pass.md`'s still names #146 and #147 the same way — shows the established
  convention for this initiative is that a "#N needs to X" revisit-trigger bullet is
  satisfied by #N's own design, never by rewriting the document that anticipated it.
  Editing `collaboration-state.md` here would have broken that precedent for no
  benefit: `docs/adapters/OBSERVER.md` §D4 already cites its precedence table by name
  rather than restating it, which is the thing the bullet was actually asking for.
- **No PR-body marker, and no change to `/t-work`, `/t-review`, `/t-status`, or
  `/t-drive`** (haninaguib, via the driving session, 2026-09-06): the one correlation
  gap native GitHub fields cannot close on their own — which initiative a task belongs
  to, and what origin it carries — is closed entirely from the *issue* side, since a
  PR's own already-mandated `Closes #<id>` phrase plus its `headRefName` already
  resolve to that issue. Duplicating the marker onto the PR body would have been a
  second, driftable copy of the same fact, and would have required touching `/t-work`
  — explicitly flagged by the driving session as work three just-merged siblings
  (#144/#145/#147) already own. `/t-open` is therefore the marker's only writer.
- **The marker is versioned (`t-workflow:v1`) and validated by a new, ungated
  `check-observer-marker.sh`, mirroring `check-preview-evidence.sh`'s own posture**
  (haninaguib, 2026-09-06): a shape-only validator, wired into no gate, since reading
  or emitting the marker is convenience for an external party, never required by
  `/t-ship`/`/t-review`/CI (`docs/adapters/PREVIEW.md`'s own precedent, cited directly
  in `OBSERVER.md`).
- **A malformed marker is reported as a defect, not folded into "absent"** (haninaguib,
  2026-09-06): unlike webhook-sourced evidence arriving from outside t-workflow
  (ADR-010 §D7's fail-toward-absent posture), `/t-open` is this marker's only writer
  today, so a marker that is present but does not parse is our own bug, and
  `check-observer-marker.sh` reports it as `present: true, valid: false` rather than
  silently reading it the same as no marker at all.

## Deviations / notes
- none
