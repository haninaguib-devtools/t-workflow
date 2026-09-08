#!/usr/bin/env bash
# What a generated (or adopted) project's tree never receives from the template, and
# the function that removes it. Sourced, never executed directly — it defines things
# into the calling script's shell, so it has no shebang effect and no `set` of its own;
# the caller (bootstrap.sh today, installer/adopt.sh per #172 once it exists) already
# has whatever `set -euo pipefail` it needs.
#
# bash 3.2 compatible: macOS still ships it, and installer/bootstrap.sh runs there.
#
# This is a strip, not a copy: it turns an already-existing directory — a template
# clone or a copy of one — into a consumer tree *in place*, deleting the paths below.
# `installer/bootstrap.sh` calls it on the fresh copy it just made, which happens to be
# the whole of a brand-new project. #172's `installer/adopt.sh` will call it on a
# scratch clone instead, before selectively merging that clone into an existing
# repository — never the whole target — so the function only ever touches the
# directory it is given, nothing outside it, and never assumes that directory is a
# complete project on its own.

# Paths, relative to the tree's root, that a consumer never receives — deleted outright:
#   .git       — a new project (or an adopted one) is not a fork of the template's history
#   LICENSE    — the template's MIT file names the template's copyright holder; putting
#                that on someone else's project would be wrong. They choose their own.
#   installer/ — a project does not ship the thing that made it
#   site/      — the public website describes this delivery-system template, not the
#                project being generated
#   .github/workflows/installer.yml — the workflow that tests installer/, left behind it
#              would reference ./installer/test.sh, which was just deleted
#   .github/workflows/pages.yml — deploys site/ and would fail without it
TWORKFLOW_CONSUMER_EXCLUDED_PATHS=(
  ".git"
  "LICENSE"
  "installer"
  "site"
  ".github/workflows/installer.yml"
  ".github/workflows/pages.yml"
)

# strip_consumer_exclusions <dir>
#
# Turns the template tree at <dir> into a consumer tree, in place:
#   1. deletes every path in TWORKFLOW_CONSUMER_EXCLUDED_PATHS;
#   2. empties docs/tasks/ of the template's own task record directories, keeping the
#      record shape itself (TEMPLATE.md, README.md) — those describe how to write a
#      record, the records they sit beside describe the template's own history.
#
# Idempotent (removing an absent path is not an error) and confined to <dir> — it never
# reads or writes anything outside the directory it is given.
strip_consumer_exclusions() {
  local dir="${1:?strip_consumer_exclusions: directory argument required}"

  local rel
  for rel in "${TWORKFLOW_CONSUMER_EXCLUDED_PATHS[@]}"; do
    rm -rf "${dir:?}/$rel"
  done

  if [ -d "$dir/docs/tasks" ]; then
    find "$dir/docs/tasks" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +
  fi
}
