---
name: t-drive
description: Not yet implemented. Walks an initiative's children to completion on an integration branch, chaining plan/work/review per child and stopping once for a single human-confirmed PR to `main` (ADR-004: docs/adr/004-autonomous-initiative-driving.md). Implementation is tracked in issue #41, blocked by #40. Use only to tell the human /t-drive does not run yet.
---

# Drive an initiative (not yet implemented)

`/t-drive`'s design is ratified in ADR-004 (`docs/adr/004-autonomous-initiative-driving.md`),
but the skill itself is not built. Its implementation is issue #41, blocked by #40 (the
ADR task). This file exists only so `AGENTS.md`'s pipeline table and
`scripts/consistency-check.sh`'s stage-table ↔ skill-directory symmetry check both hold
between #40 merging and #41 landing — it is a placeholder, not a working skill.

If invoked, say plainly that `/t-drive` is not implemented yet, point at ADR-004 and
issue #41, and stop. Do not attempt any part of the driven-initiative behavior ADR-004
describes — planning, implementing, reviewing, or merging on behalf of an initiative's
children.
