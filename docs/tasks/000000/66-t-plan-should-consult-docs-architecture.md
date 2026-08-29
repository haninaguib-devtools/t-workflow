# 66 — /t-plan should consult docs/architecture/local-slots.md before targeting a template-owned file, not reason from file prose
Issue: #66

## Asked
On a pinned template consumer (any repo with `.template-manifest.json`), `/t-plan` currently
decides *where* to add content to a template-owned file (`AGENTS.md`, `CONSTITUTION.md`) by
reasoning about which section conceptually fits, instead of checking which regions are
actually per-repo-editable. Only the paths `docs/architecture/local-slots.md` names as local
slots are safe to edit — everything else in those files is hashed into the manifest and
fails CI's `manifest` job after the fact. This was caught downstream by CI on task #319 in
the `locklane` consumer repo, not by the plan step itself or by cold review, forcing a
re-plan, a fix commit, and a second review cycle mid-drive.

The same incident exposed a second, related gap: `check-manifest.sh`, `check-record.sh`,
and `check-plan-gate.sh` are cheap local checks (the first two need no GitHub API call at
all; the third needs one `gh issue view`), yet `/t-work` Phase 3 does not run any of them
before pushing — so the same class of drift only surfaces once CI runs, on the PR.

## Done when
- `/t-plan`'s procedure explicitly checks for `.template-manifest.json` and, when present,
  resolves any target inside a template-owned file against
  `docs/architecture/local-slots.md`'s named slots before writing Allowed paths — never by
  reasoning from the file's own prose.
- A plan that would land content outside a named local slot is rejected at plan time with
  the correct slot named instead, rather than surfacing only when CI's manifest check runs
  post-PR.
- `/t-work` Phase 3's local check step also runs `check-manifest.sh` and `check-record.sh`
  (both already zero-API pure local scripts) and `check-plan-gate.sh` (one `gh issue view`
  call) before commit/push, on any repo with `.template-manifest.json` — so a manifest or
  record drift fails locally instead of round-tripping through CI.

## Explicitly not
- Changing the manifest/local-slot mechanism itself.
- Teaching cold review to catch this — the fix belongs at plan time and at pre-push,
  before scope is fixed and before the PR opens.

## Decisions made along the way
- none

## Deviations / notes
- Scope grew mid-plan, before any implementation started: the issue's first `## Plan`
  section (written by `/t-plan`, this session) allowed only
  `.claude/skills/t-plan/SKILL.md`. The human then expanded the issue's Goal and
  Done-when to add the `/t-work` Phase 3 requirement above, removed that first `## Plan`
  section directly on the issue (leaving a Scope note asking for a re-plan), and asked
  for `/t-plan 66` again. The replacement `## Plan` section — the one this task
  implements against — allows `.claude/skills/t-plan/SKILL.md` *and*
  `.claude/skills/t-work/SKILL.md`. No file had been touched under the narrower scope,
  so there is no code-level deviation to reconcile, only this record of why the bound
  changed (haninaguib, 2026-08-29, both `/t-plan` runs this session).
