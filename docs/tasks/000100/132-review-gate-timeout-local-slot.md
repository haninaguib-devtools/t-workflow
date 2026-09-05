# 132 — review-gate.yml's timeout-minutes has no local-slot marker

Issue: #132

## Asked
`.github/workflows/review-gate.yml`'s `cold-review` job hardcodes `timeout-minutes: 10`
with no `<!-- local -->` slot markers around it, even though `.github/workflows/ci.yml`'s
identical value already carries markers (#118, `docs/architecture/local-slots.md`).
Because the value is unmarked here, a consumer that later raises it has that edit
sitting outside every marker, so `/t-update`'s normalized-hash comparison treats it as
template drift on the next sync and silently splices it back to the template's
placeholder — the same failure #118 fixed in `ci.yml`, just left open in this sibling
workflow file.

## Done when
- `docs/architecture/local-slots.md` documents `review-gate.yml`'s `timeout-minutes` as
  a new local slot, same style as the ones it already lists.
- `.github/workflows/review-gate.yml`'s `timeout-minutes: 10` line sits between
  `# <!-- local -->` / `# <!-- /local -->` markers, matching `ci.yml`'s existing marker
  style, and the file remains valid YAML.
- `.t-workflow/scripts/check-manifest.sh --hash-file .github/workflows/review-gate.yml`
  produces the same normalized hash whether or not the value inside the new slot is
  edited — confirmed rather than assumed.

## Explicitly not
- A trailing steps-extension slot on `review-gate.yml`'s `cold-review` job — it is
  fixed, single-purpose machinery, not a place consumers append their own steps.
- Retrofitting any consumer's already-synced `review-gate.yml` by hand.
- A migration file: no `.template-manifest.json` exists in this repo (it is the
  template, not a consumer), and no consumer is known to have customized this
  particular value, unlike the documented `ci.yml` cases in
  `migrations/V1__ci-yml-local-slots.md` — decided during planning (`/t-plan 132`).

## Decisions made along the way
- none

## Deviations / notes
- none
