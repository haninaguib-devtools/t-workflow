# 155 — Let /t-review's subagent reviewer run under a configurable model
Issue: #155

## Asked
Today, when `/t-review` spawns an independent subagent to review a task, that subagent
always inherits whatever model happens to be running the invoking session — there is no
way for a repo to set a different default reviewer, and no way for a human to request a
specific one for a single run. This adds both: a per-repo default, stored in a new
`<!-- local -->` slot in `AGENTS.md` so it survives template syncs, and a same-invocation
override a human can type directly (e.g. `/t-review 154 use fable as the reviewer`) that
always wins and always forces a real independent subagent, so the requested model
actually gets used instead of being silently ignored on a path that never spawns one.

## Done when
- `AGENTS.md` carries a new `<!-- local -->` … `<!-- /local -->` slot naming the default
  model for `t-review`'s subagent reviewer, with a neutral placeholder such as
  `(none — reviews inherit the invoking session's model)`.
- `docs/architecture/local-slots.md` documents this as a ninth named slot, in the same
  style as the other eight, including its placeholder text.
- `.claude/skills/t-review/SKILL.md`'s isolation step (step 1) resolves the reviewer's
  model with this precedence, most specific first: a model named explicitly in the
  invocation's own argument; otherwise the default named in `AGENTS.md`'s slot, if any;
  otherwise the invoking session's own model (no override at all) — resolved by
  pointing at `AGENTS.md`'s slot generically, never hardcoding a value inline.
- Naming a model explicitly in the invocation always resolves isolation to `subagent`
  (forcing a real spawn under that model) — never `same session` or `fresh session`,
  even for a change small enough that isolation would normally be skipped.
- `./.t-workflow/scripts/consistency-check.sh` passes.

## Explicitly not
- An interactive `/t-config` skill that asks which model to use and writes it into this
  slot for you — split to #156.
- Discovering "available models" at runtime — the slot's own placeholder/comment simply
  documents the known model names for the current harness by hand, the same way
  `docs/adapters/TRACKER.md` and `FORGE.md` name concrete backends by hand.
- Any change to `/t-plan`, `/t-work`, `/t-ship`, `/t-drive`, or `/t-cancel`'s own
  isolation or model behavior — this task is scoped to `/t-review` only.

## Origin
none

## Verification
none

## Feedback
none

## Decisions made along the way
- Placed the new slot in its own top-level `## Reviewer model` section in `AGENTS.md`,
  rather than inside "## The pipeline" or "## Checks" — both of those sections already
  carry a `<!-- local -->` pair, and `consistency-check.sh`'s skills-table symmetry
  check scopes its own marker extraction to "## The pipeline" by header name; a second
  marker pair there risked that scoped extraction picking up unrelated prose. A new
  section keeps every existing scoped check untouched (agent, 2026-09-06).

## Deviations / notes
- Mid-flight re-plan: the issue's `## Plan` section was replaced (Goal/Done when/Scope/
  Non-goals unchanged) to add `docs/adapters/MODEL.md` to Allowed paths.
  Previous Allowed paths: `AGENTS.md`, `docs/architecture/local-slots.md`,
  `.claude/skills/t-review/SKILL.md`.
  New Allowed paths: those three, plus `docs/adapters/MODEL.md` (new).
  Reason: a hardcoded/enumerated model-name list, of any shape or location, was
  rejected as unable to generalize across harnesses — a harness like OMP (omp.sh) does
  model-agnostic, role-based routing across 60+ providers with no fixed set to
  enumerate. Replaced with an opaque string (unchanged: the slot and the inline
  override already accepted any string) plus a new per-harness example/resolution
  document, `docs/adapters/MODEL.md`, in the shape of the existing
  `TRACKER.md`/`FORGE.md`/`OBSERVER.md`/`PREVIEW.md` adapter docs (human, via
  re-plan, 2026-09-06).
