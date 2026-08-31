# ADR-008: `/t-ship` watches CI to conclusion after marking the PR ready

**Status:** Accepted · 2026-08-30
**Deciders:** project owner *(solo phase; queued for review alongside ADR-001–007 if a
second maintainer joins — workflow §13 Q9.)*

This ADR narrows [ADR-007](007-solo-drive-defers-on-pending-ci.md): its Decision — a
single, one-time look at CI, with `/t-drive`'s Solo mode deferring before invoking
`/t-ship` when that look finds CI still pending — applied because CI started at
PR-open, so by the time a solo drive finished its work and reached that check, CI had
usually had minutes to settle. It amends nothing else: ADR-004's and ADR-006's other
decisions stand untouched, and ADR-007's core argument against an arbitrary,
must-be-defended polling timeout is not being relitigated — it is being kept, and
applied one stage further in, where it actually fits.

## Context

Issue #98. `.github/workflows/ci.yml` now skips its jobs while the triggering PR is a
draft and starts them only on `ready_for_review` — the change that cuts the pipeline's
CI cost for a task's whole work-in-progress window. That moves the moment CI starts
from PR-open (`/t-work`'s first push) to whenever the PR is later marked ready — which
only `/t-ship`'s own Procedure does. Two existing pieces of skill text assumed the old
timing and now say something false:

- `/t-ship` precondition 3 read `forge:pr-checks <pr>` and called the result "green" or
  "failing" *before* Procedure step 1 marked the PR ready. Under the new timing, that
  read always finds CI not yet started (its jobs skipped while draft, per #98) — reading
  that as "green" would show the human confirming the merge evidence that means
  "nothing ran," never "passed," which is exactly the gate `CONSTITUTION.md` §1.5
  forbids treating as satisfied.
- `/t-drive`'s Solo mode step 6 read the same PR's checks *before* invoking `/t-ship` at
  all, to decide whether to defer (ADR-007). Under the new timing this check, too, is
  reached before the PR has ever been marked ready — so it would find CI not started,
  every single time, not just often. A check that always defers is not "a single look
  that sometimes catches genuinely pending CI" (ADR-007's design); it is a guaranteed
  double-invocation ritual on every protected ship — precisely ADR-007's own first
  revisit trigger ("a single look almost always finds it pending"), now guaranteed
  rather than occasional.

## Decision

`/t-ship`'s Procedure gains a step immediately after marking the PR ready (step 1) and
before the confirmation gate (step 3): when precondition 3 found CI configured, watch it
— `gh pr checks <pr> --watch` or equivalent polling to conclusion, no timeout — until
every check has concluded, green or red. Concluded red stops the run there (PR put back
into draft, failure reported), the same refusal a failing precondition would have
produced. Concluded green, or no CI configured, carries that result into the
confirmation gate as its CI evidence. Precondition 3 itself no longer answers "is CI
green" — only "is CI configured at all," since that fact alone is knowable before the PR
is marked ready and the green/red fact is not.

This wait needs no timeout to pick or defend, unlike the polling alternatives ADR-007
rejected: `/t-ship`'s Procedure runs inside a single, currently-executing invocation of
that stage — a human's own session, or (chained by `/t-drive`'s Solo mode, ADR-006) the
driven session currently executing it — and either way there is exactly one place that
invocation comes to rest: the confirmation gate. A wait bounded by CI's own conclusion,
immediately before the one stop that already exists, adds no new decision point; it only
changes how long reaching that existing stop takes. `/t-drive`'s Solo mode step 6
(ADR-007's mechanism) is retired for this reason — it decided whether to defer *before*
invoking `/t-ship`, and now has nothing left to decide: CI cannot have settled before the
PR is marked ready regardless of how long the run's own work took, so the wait belongs
entirely inside `/t-ship`, uniformly for a human-invoked ship and a driven one. Solo
mode's "the run stops once, at `/t-ship`'s gate" (ADR-006 D3) is unchanged — reaching
that gate now costs one internal wait it did not used to, not a second stop.

## Rationale

- **ADR-007's objection was to an arbitrary, must-be-justified timeout, not to
  waiting.** Its Alternatives section rejected a bounded retry because "CI can take
  minutes, so the equivalent... would be a real wait with a real duration to justify."
  Watching to conclusion picks no duration at all — it ends when CI ends, the same
  non-arbitrary bound `/t-ship` precondition 4's mergeability retry already uses on a
  shorter scale.
- **The premise that motivated ADR-007's Solo-mode pre-check no longer holds.** That
  pre-check existed to catch the case where elapsed work time had *not yet* let CI
  settle by the time a solo drive reached it. Once CI cannot start before the PR is
  marked ready, "has it settled yet" is never true at that pre-check's moment, for any
  amount of elapsed work time — the check stopped measuring anything and become a
  guaranteed deferral, not an occasional one.
- **One wait, one place, for both callers.** Moving the wait into `/t-ship` itself,
  rather than re-deriving a second pre-check for the driven case, means a human running
  `/t-ship` directly and a driven run chaining into it experience the identical
  mechanism — no asymmetry to maintain, no second copy of "how to read CI status" to
  keep in sync with the first.
- **The alternative of queuing the merge instead of waiting was rejected.** GitHub's
  native `gh pr merge --squash --auto` would let `/t-ship` avoid waiting entirely by
  queuing the merge to complete once checks pass — but that means the human confirms a
  merge whose CI outcome is still unknown at confirmation time, and a CI failure
  *after* confirmation produces a "confirmed but never landed" state with no one
  watching for it. Watching to conclusion first keeps the confirmation gate's evidence
  honest: what the human confirms is what is about to happen, not a bet on what might.

## Alternatives considered

- **Keep ADR-007's Solo-mode pre-check, deferring every time it finds CI merely
  started** — rejected: guarantees a second `/t-drive`/`/t-ship` round-trip on every
  protected ship, the exact regression ADR-007's own revisit trigger 1 names; the check
  now measures nothing since CI can never have settled at that point.
- **A bounded-retry poll inside `/t-ship`, mirroring precondition 4's mergeability
  retry (a few seconds, a few tries)** — rejected: precondition 4's retry is sized for
  an already-fast, already-converging asynchronous answer; CI is not, so the equivalent
  here is ADR-007's rejected "real wait with a real duration to justify," one layer
  further in.
- **`gh pr merge --squash --auto`** — rejected per Rationale above: trades an honest,
  watched wait for an unwatched bet on a CI outcome the human never actually confirms.
- **Leave `/t-ship` and `/t-drive` as ADR-007 left them, treating this as #98's problem
  to work around some other way** — rejected: the mis-timed precondition read is a
  direct, mechanical consequence of #98's own change; leaving it would ship a merge gate
  that can show "green" for CI that never ran, which `CONSTITUTION.md` §1.5 forbids
  outright.

## Consequences / revisit triggers

Accepted knowingly: `/t-ship`'s Procedure now includes a wait of unpredictable length
(however long CI takes) between marking a PR ready and reaching the confirmation gate,
for every protected task, human-invoked or driven. `/t-drive`'s Solo mode no longer has
its own CI pre-check; the wait it used to sometimes avoid by finding CI already settled
now always happens, once, inside `/t-ship`.

Any of these reopens this decision, as a new ADR:

1. **The watch routinely runs long enough that it materially degrades the interactive
   `/t-ship` experience** (a human waiting minutes mid-session with nothing to do) —
   revisit toward showing interim progress, or toward `gh pr merge --auto` after all,
   with its confirmed-but-unlanded risk accepted explicitly rather than avoided.
2. **A driven session's watch is observed to exceed whatever wall-clock budget its
   runner enforces**, turning an unpredictable CI wait into a hard failure rather than a
   completed stop — revisit toward a bounded wait with a real duration to justify after
   all, the exact tradeoff this ADR currently avoids needing.
3. **CI is later split into a fast gate and a slow gate** (`docs/adr/` — a future ADR),
   changing what "concluded" means for the merge decision — this decision's "watch every
   check to conclusion" may need to become "watch only the required ones."
