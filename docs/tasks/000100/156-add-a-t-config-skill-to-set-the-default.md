# 156 — Add a /t-config skill to set the default reviewer model without hand-editing AGENTS.md
Issue: #156

## Asked
Once #155 gave `/t-review` a per-repo default reviewer model stored in a slot inside
`AGENTS.md`, a human still has to remember that the setting exists, where it lives, and
its exact marker syntax to change it. This adds a `/t-config` skill that asks which
model should be the default reviewer (or to clear the override back to none) and writes
the answer into that same slot itself — no new config file, just a guided editor for a
slot that already exists.

## Done when
- `/t-config`, run with no arguments, locates `AGENTS.md`'s reviewer-model slot, prompts
  the human to type a model name freely (surfacing `docs/adapters/MODEL.md`'s example
  names for the current harness as a hint, never a fixed menu — see #155's non-goals:
  no enumerated or validated list exists to pick from) or clear the override, and writes
  the answer into the slot — leaving the rest of `AGENTS.md` untouched.
- `AGENTS.md`'s pipeline table gets a row for `/t-config`.
- `./.t-workflow/scripts/consistency-check.sh` passes.

## Explicitly not
- Any setting beyond the reviewer-model slot — generalizing `/t-config` to more
  settings is deferred until a second one actually exists, so it isn't built for a
  hypothetical need.

## Origin
none

## Verification
none

## Feedback
none

## Decisions made along the way
- none

## Deviations / notes
- none
