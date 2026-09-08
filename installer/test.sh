#!/usr/bin/env bash
# Tests the installer by running it for real and asserting the project it produces.
#
# It clones the repository this file lives in, so it tests COMMITTED state — commit
# before running it locally, or you are testing the previous version of your change. In
# CI that is exactly right: the runner checks out the merge commit.
#
# Usage: installer/test.sh          (from anywhere; paths are resolved from this file)
# Exit 0 = every assertion passed.
set -uo pipefail

here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/.." && pwd)

pass=0
fail=0
ok()   { pass=$((pass + 1)); printf '  ok   %s\n' "$*"; }
bad()  { fail=$((fail + 1)); printf '  FAIL %s\n' "$*"; }
check() { # check <description> <command...>
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then ok "$desc"; else bad "$desc"; fi
}

work=$(mktemp -d "${TMPDIR:-/tmp}/t-workflow-test.XXXXXX") || exit 2
trap 'rm -rf "$work"' EXIT HUP INT TERM

# The generated project gets a commit, which needs an identity. A contributor's machine
# has one; a fresh CI runner does not. Setting it only for this test's environment leaves
# the caller's git configuration untouched.
export GIT_AUTHOR_NAME="${GIT_AUTHOR_NAME:-t-workflow installer test}"
export GIT_AUTHOR_EMAIL="${GIT_AUTHOR_EMAIL:-installer-test@example.invalid}"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

echo "Testing installer against $root"
echo

# Clone from a throwaway bare repository whose `main` is this working tree's HEAD,
# rather than from $root directly. `git clone` needs the source to have a resolvable
# branch, and a CI runner checks out a detached HEAD — pushing `HEAD:refs/heads/main`
# gives the installer a real branch to fetch whatever state the caller is testing.
srcrepo="$work/source.git"
git init --quiet --bare "$srcrepo" || exit 2
# `git init --bare` points HEAD at init.defaultBranch, which is still `master` on an
# older git — including the Linux CI runner's. A clone that does not name a branch then
# tries to check out a ref that does not exist and silently produces an empty working
# tree. Naming the branch here makes the test source identical everywhere.
git -C "$srcrepo" symbolic-ref HEAD refs/heads/main || exit 2
git -C "$root" push --quiet "$srcrepo" "HEAD:refs/heads/main" || {
  echo "could not stage the test source from $root — is HEAD committed?" >&2
  exit 2
}

# --- 1. --help works without touching the network ---------------------------
echo "--help"
help_out=$(bash "$root/installer/install.sh" --help 2>&1); help_rc=$?
[ "$help_rc" -eq 0 ] && ok "exits 0" || bad "exits 0 (got $help_rc)"
for flag in --name --dir --source --ref --help; do
  case "$help_out" in *"$flag"*) ok "documents $flag" ;; *) bad "documents $flag" ;; esac
done
# The remote flags are gone, not merely undocumented: their appearance anywhere in
# --help would mean the remote-creation path is growing back.
for flag in --no-remote --remote --private --public; do
  case "$help_out" in *"$flag"*) bad "does not mention $flag" ;; *) ok "does not mention $flag" ;; esac
done
echo

# --- 2. a full non-interactive run ------------------------------------------
echo "install --name demo"
# stdin is closed on purpose: a prompt that read stdin instead of /dev/tty would show up
# here as a hang or an empty answer rather than passing quietly.
run_out=$(bash "$root/installer/install.sh" \
            --name demo --dir "$work" \
            --source "$srcrepo" </dev/null 2>&1); run_rc=$?
if [ "$run_rc" -ne 0 ]; then
  bad "exits 0 (got $run_rc)"
  printf '%s\n' "$run_out" | sed 's/^/    /'
  echo
  echo "$pass passed, $((fail + 1)) failed"
  exit 1
fi
ok "exits 0 with no prompts"

demo="$work/demo"
check "creates the project directory"          test -d "$demo"
echo

# --- 3. what the generated project must not carry ----------------------------
echo "stripped"
check "no installer/ directory"                test ! -e "$demo/installer"
check "no LICENSE"                             test ! -e "$demo/LICENSE"
check "no template website"                    test ! -e "$demo/site"
check "no Pages workflow"                      test ! -e "$demo/.github/workflows/pages.yml"
check "no leftover task records"               test -z "$(find "$demo/docs/tasks" -mindepth 1 -maxdepth 1 -type d)"
check "docs/tasks keeps TEMPLATE.md"           test -f "$demo/docs/tasks/TEMPLATE.md"
check "docs/tasks keeps README.md"             test -f "$demo/docs/tasks/README.md"
echo

# --- 4. symlinks survived the copy ------------------------------------------
# A copy that follows symlinks produces files that look right and then drift apart from
# the originals forever. This is the assertion that catches it.
echo "symlinks"
for link in CLAUDE.md GEMINI.md .agents/skills .github/copilot-instructions.md; do
  check "$link is still a symlink"             test -L "$demo/$link"
done
echo

# --- 5. a fresh history, not the template's ---------------------------------
echo "git"
count=$(git -C "$demo" rev-list --count HEAD 2>/dev/null || echo x)
[ "$count" = "1" ] && ok "exactly one commit" || bad "exactly one commit (got $count)"
check "not a shallow clone"                    test ! -e "$demo/.git/shallow"
check "no origin remote"                       test -z "$(git -C "$demo" remote 2>/dev/null)"
branch=$(git -C "$demo" symbolic-ref --short HEAD 2>/dev/null || echo none)
[ "$branch" = "main" ] && ok "trunk is main" || bad "trunk is main (got $branch)"
check "working tree is clean"                  test -z "$(git -C "$demo" status --porcelain)"
echo

# --- 6. the README ----------------------------------------------------------
echo "README"
check "provenance line, matched by shape" \
  grep -qE '^Generated from t-workflow @ [0-9a-f]{7,}' "$demo/README.md"
check "carries the project name"               grep -q '^# demo$' "$demo/README.md"
check "no unsubstituted placeholders"          bash -c '! grep -q "{{" "$1"' _ "$demo/README.md"
check "differs from the template's own README" bash -c '! cmp -s "$1" "$2"' _ "$demo/README.md" "$root/README.md"
# --source pointed at a local directory here, so there is no origin URL to name. The
# provenance line must degrade to the hash alone rather than stamping a temporary path
# into the project's README as its origin.
check "no local source path in the provenance line" \
  bash -c '! grep -q "Generated from t-workflow @ .* — /" "$1"' _ "$demo/README.md"
echo

# --- 7. the generated project is internally consistent -----------------------
echo "consistency"
if ( cd "$demo" && ./.t-workflow/scripts/consistency-check.sh ) >/dev/null 2>&1; then
  ok ".t-workflow/scripts/consistency-check.sh passes inside the generated project"
else
  bad ".t-workflow/scripts/consistency-check.sh passes inside the generated project"
  ( cd "$demo" && ./.t-workflow/scripts/consistency-check.sh ) 2>&1 | sed 's/^/    /'
fi
check "installer/ is protected in the generated project" \
  bash "$demo/.t-workflow/scripts/protected-paths.sh" installer/anything.sh

# The generated project inherits every workflow file in this repository. A workflow that
# calls a script the strip list just deleted goes red on the new owner's first pull
# request, for a reason they did not cause. Rather than naming the known offender, this
# asserts the general rule: every script a generated workflow runs must exist.
missing=""
for wf in "$demo"/.github/workflows/*.yml; do
  [ -f "$wf" ] || continue
  while IFS= read -r script; do
    [ -e "$demo/$script" ] || missing="$missing $(basename "$wf"):$script"
  # Both spellings a workflow may use: `run:` as a key under a named step, and the
  # inline `- run:` list item. Matching only the first would leave the guard passing on
  # exactly the bug it exists to catch, written the other way.
  done < <(sed -n -E 's#^[[:space:]]*(-[[:space:]]+)?run:[[:space:]]*\./([^[:space:]]*).*#\2#p' "$wf")
done
if [ -z "$missing" ]; then
  ok "generated workflows call no missing script"
else
  bad "generated workflows call no missing script (missing:$missing)"
fi
check "the installer's own workflow is not inherited" \
  test ! -e "$demo/.github/workflows/installer.yml"
check "the generated project keeps ci.yml"     test -f "$demo/.github/workflows/ci.yml"
echo

# --- 7b. the provenance branch every real user takes -------------------------
# install.sh was given a local --source above, so bootstrap.sh only ever took the
# "no origin URL" path. The branch that substitutes a real URL is the one that runs for
# anyone installing from the public one-liner, and nothing was exercising it. Driving
# bootstrap.sh directly is what lets it be tested without reaching the network.
echo "provenance from a URL source"
if ! clone_err=$(git clone --quiet --depth 1 --branch main "file://$srcrepo" "$work/clone" 2>&1); then
  bad "clones the test source over file://"
  printf '%s\n' "$clone_err" | sed 's/^/    /'
fi
if TWORKFLOW_SRC="$work/clone" \
   TWORKFLOW_NAME=urltest \
   TWORKFLOW_TARGET="$work/urltest" \
   TWORKFLOW_SOURCE_URL="https://github.com/example/t-workflow.git" \
   bash "$root/installer/bootstrap.sh" >/dev/null 2>&1; then
  ok "installs from a URL source"
  check "provenance names the URL, with .git trimmed" \
    grep -qE '^Generated from t-workflow @ [0-9a-f]{7,} — https://github\.com/example/t-workflow$' \
    "$work/urltest/README.md"
else
  bad "installs from a URL source"
  TWORKFLOW_SRC="$work/clone" TWORKFLOW_NAME=urltest2 TWORKFLOW_TARGET="$work/urltest2" \
  TWORKFLOW_SOURCE_URL="https://github.com/example/t-workflow.git" \
  bash "$root/installer/bootstrap.sh" 2>&1 | sed 's/^/    /' | tail -5
fi
echo

# --- 7c. the consumer's own checks, with every local slot filled ------------------------
# Everything above ran the generated project's checks with every <!-- local --> slot
# still holding the template's placeholder — the one state a consumer never stays in.
# Every script the template ships into a consumer's required `checks` job first met a
# filled slot on the consumer's machine, at sync time, after a tag (#118, #120, #122,
# #126, #130, #185, #186). This section is that consumer: a copy of the generated
# project with every slot docs/architecture/local-slots.md names filled with real
# content, and the consumer's whole check set run inside it. A slot is filled by the
# template text around it (a heading, a YAML key), never by its ordinal — the same rule
# every reader in the pipeline follows. Adding a slot to the inventory means adding its
# fill here in the same task (local-slots.md says so).
echo "every slot filled"
filled="$work/demo-filled"
cp -a "$demo" "$filled"

# fill_slot <file> <anchor-regex> <content-file> — replaces the content of the first
# `<!-- local -->` … `<!-- /local -->` pair (bare, or `#`-prefixed at any indentation)
# after the first line matching <anchor-regex>. Fails when no such pair follows the
# anchor — a slot the inventory names but the file does not carry is a finding, not a
# silent no-op. Writes through `cat` so the file keeps its mode (protected-paths.sh is
# executable).
fill_slot() {
  local file="$1" anchor="$2" content="$3" tmp
  tmp=$(mktemp "$work/fill.XXXXXX") || return 1
  awk -v anchor="$anchor" -v content="$content" '
    $0 ~ anchor && !armed { armed = 1 }
    armed && !done && /^[[:space:]]*#?[[:space:]]*<!-- local -->[[:space:]]*$/ {
      print; while ((getline line < content) > 0) print line; close(content)
      skip = 1; done = 1; next
    }
    skip && /^[[:space:]]*#?[[:space:]]*<!-- \/local -->[[:space:]]*$/ { skip = 0 }
    !skip { print }
    END { if (!done) exit 1 }
  ' "$file" > "$tmp" || { rm -f "$tmp"; return 1; }
  cat "$tmp" > "$file" && rm -f "$tmp"
}
fill() { # fill <label> <file-relative-to-filled> <anchor-regex> <content...>
  local label="$1" file="$2" anchor="$3"; shift 3
  local c; c=$(mktemp "$work/content.XXXXXX")
  printf '%s\n' "$@" > "$c"
  if fill_slot "$filled/$file" "$anchor" "$c"; then ok "fills $label"; else bad "fills $label (no slot after /$anchor/ in $file)"; fi
  rm -f "$c"
}

fill "CONSTITUTION.md's status note"      CONSTITUTION.md '^# CONSTITUTION.md$' \
  '**Status note:** the stack is decided (§4); the delivery system is past Phase 0.'
fill "CONSTITUTION.md §3's protected-path bullet" CONSTITUTION.md '^## 3. Protected surfaces' \
  '- `db/migrations/` (the fixture'"'"'s own schema migrations)'
fill "protected-paths.sh's pattern"       .t-workflow/scripts/protected-paths.sh '^patterns=' \
  "  'db/migrations/*'"
fill "CONSTITUTION.md §4's stack rule"    CONSTITUTION.md '^## 4. Stack' \
  '- The application is a Python service under `src/`; no other language is added without a decision in `docs/adr/`.'
fill "AGENTS.md's local-skill row"        AGENTS.md '^## The pipeline' \
  '| Skill | Stage |' '|---|---|' '| `/l-deploy` | Deploys the fixture app to its staging host. |'
mkdir -p "$filled/.claude/skills/l-deploy"
printf -- '---\nname: l-deploy\ndescription: Deploys the fixture app to its staging host.\n---\n\nFixture-local skill.\n' > "$filled/.claude/skills/l-deploy/SKILL.md"
fill "AGENTS.md's reviewer model"         AGENTS.md '^## Reviewer model' \
  'Default reviewer model: claude-sonnet-5'
fill "AGENTS.md §Checks item 1"           AGENTS.md '^## Checks$' \
  '1. `make test` — the fixture'"'"'s build/test command.'
fill "AGENTS.md's documentation-only glob" AGENTS.md '^### Documentation-only paths' \
  '- `site/**` — the fixture'"'"'s static site'
fill "AGENTS.md's project notes"          AGENTS.md '^## Project notes' \
  'Fixture team notes: FILLED-NOTES-MARKER.'
fill "ci.yml's trunk line"                .github/workflows/ci.yml '^  push:' \
  '    branches: [main, release/*]'
fill "ci.yml's timeout"                   .github/workflows/ci.yml '^    runs-on:' \
  '    timeout-minutes: 20'
fill "ci.yml's trailing build step"       .github/workflows/ci.yml 'writes that exact shape' \
  '      - name: Project checks' \
  '        if: "!cancelled() && steps.docs-only.outputs.docs_only != '"'"'true'"'"'"' \
  '        run: make test'
fill "review-gate.yml's timeout"          .github/workflows/review-gate.yml '^    runs-on:' \
  '    timeout-minutes: 20'
fill ".gitignore's entries"               .gitignore '^# OS$' \
  'fixture-build-cache/'
printf 'fixture-build\n' > "$filled/.t-workflow/required-checks.local"
ok "writes .t-workflow/required-checks.local"
mkdir -p "$filled/site" && printf '<html></html>\n' > "$filled/site/index.html"
git -C "$filled" add -A && git -C "$filled" commit --quiet -m "fill every local slot" || bad "commits the filled consumer"

# Every fill landed inside a slot and nowhere else: the manifest hash ignores slot
# content, so each filled file must hash exactly as the untouched generated one.
for f in CONSTITUTION.md AGENTS.md .github/workflows/ci.yml .github/workflows/review-gate.yml \
         .gitignore .t-workflow/scripts/protected-paths.sh; do
  if [ "$(bash "$filled/.t-workflow/scripts/check-manifest.sh" --hash-file "$filled/$f")" = \
       "$(bash "$demo/.t-workflow/scripts/check-manifest.sh" --hash-file "$demo/$f")" ]; then
    ok "$f: the filled file hashes the same as the generated one (no drift)"
  else
    bad "$f: the filled file hashes the same as the generated one (a fill landed outside its slot)"
  fi
done

# The consumer's check set, exactly as its own CI runs it.
run_in_filled() { # run_in_filled <description> <command...> — the command runs from the filled tree; output shown on failure
  local desc="$1"; shift
  local out
  if out=$(cd "$filled" && "$@" 2>&1); then ok "$desc"; else bad "$desc"; printf '%s\n' "$out" | grep -E 'FAIL|passed|err' | sed 's/^/    /'; fi
}
run_in_filled "plumbing-test.sh passes with every slot filled"      ./.t-workflow/scripts/plumbing-test.sh
run_in_filled "consistency-check.sh passes with every slot filled"  ./.t-workflow/scripts/consistency-check.sh
check "docs-only.sh --list includes the slot's glob" \
  bash -c 'cd "$1" && ./.t-workflow/scripts/docs-only.sh --list | grep -qxF "site/**"' _ "$filled"
check "docs-only.sh judges site/index.html as documentation" \
  bash -c 'cd "$1" && ./.t-workflow/scripts/docs-only.sh site/index.html' _ "$filled"
check "required-checks.sh --list includes the local context" \
  bash -c 'cd "$1" && ./.t-workflow/scripts/required-checks.sh --list | grep -qxF fixture-build' _ "$filled"
check "protected-paths.sh protects the slot's pattern" \
  bash "$filled/.t-workflow/scripts/protected-paths.sh" db/migrations/V1__init.sql
check "the local skill row resolves" \
  test -f "$filled/.claude/skills/l-deploy/SKILL.md"
check "ci.yml still parses as YAML" \
  python3 -c 'import sys, yaml; yaml.safe_load(open(sys.argv[1]))' "$filled/.github/workflows/ci.yml"
check "review-gate.yml still parses as YAML" \
  python3 -c 'import sys, yaml; yaml.safe_load(open(sys.argv[1]))' "$filled/.github/workflows/review-gate.yml"
echo

# --- 8. the closing message says the two things it must ----------------------
echo "closing message"
case "$run_out" in *"No LICENSE file was created"*) ok "states that no LICENSE was created" ;;
                   *) bad "states that no LICENSE was created" ;; esac
case "$run_out" in *CONSTITUTION.md*) ok "names CONSTITUTION.md as a thing to fill in" ;;
                   *) bad "names CONSTITUTION.md as a thing to fill in" ;; esac
case "$run_out" in *AGENTS.md*) ok "names AGENTS.md as a thing to fill in" ;;
                   *) bad "names AGENTS.md as a thing to fill in" ;; esac
echo

# --- 9. refusing an existing directory --------------------------------------
echo "refusals"
if bash "$root/installer/install.sh" --name demo --dir "$work" \
        --source "$srcrepo" </dev/null >/dev/null 2>&1; then
  bad "refuses to overwrite an existing directory"
else
  ok "refuses to overwrite an existing directory"
fi
if bash "$root/installer/install.sh" --name "../escape" --dir "$work" \
        --source "$srcrepo" </dev/null >/dev/null 2>&1; then
  bad "rejects a path-traversing project name"
else
  ok "rejects a path-traversing project name"
fi
# Without a controlling terminal there is nowhere to prompt, so a missing --name must
# fail fast rather than block on a device that will never answer. Only assertable where
# there genuinely is no terminal — which is the case in CI, and not at a developer's
# shell.
if { true >/dev/tty; } 2>/dev/null; then
  echo "  skip a terminal is attached, so the no-tty refusal is not assertable here"
else
  runner=""
  command -v timeout >/dev/null 2>&1 && runner="timeout 30"
  if $runner bash "$root/installer/install.sh" \
          --source "$srcrepo" </dev/null >/dev/null 2>&1; then
    bad "refuses to prompt when there is no terminal"
  else
    ok "refuses to prompt when there is no terminal"
  fi
fi
echo

# ==============================================================================
# installer/adopt.sh (#172) — retrofitting t-workflow into an existing repository.
#
# Test safety: every gh call adopt.sh makes goes through the fake `gh` below, on a
# PATH that shadows the real one for these invocations only. The fake never shells
# out to the real gh and never touches the network — a mutating call (`issue
# create`/`issue edit`) is impossible to route to the real haninaguib-devtools/t-workflow
# by construction, not merely by convention. `$fake_gh_log` records every `issue
# create` the fake actually received, so "the refusal/dry-run paths never create an
# issue" is an assertion here, not a claim taken on faith.
#
# Release-tag reality: adopt.sh's default --ref is the template's latest real tag,
# which at the time this was written (v0.1.1) predates this very change — a real run
# against the public default would not see it. Every fixture below instead builds
# "the template at --ref" from this checkout's own committed HEAD (same srcrepo the
# tests above already stage, plus one tag on it), never from the public tag — see
# the task record for why.
echo "installer/adopt.sh"

fakebin="$work/fakebin"
mkdir -p "$fakebin"
cat > "$fakebin/gh" <<'FAKEGH'
#!/usr/bin/env bash
set -u
case "${1:-}" in
  auth)
    [ "${2:-}" = status ] && exit 0
    ;;
  repo)
    if [ "${2:-}" = view ]; then
      printf '%s\n' "${FAKE_GH_TRUNK:-main}"
      exit 0
    fi
    ;;
  issue)
    case "${2:-}" in
      create)
        [ -n "${FAKE_GH_LOG:-}" ] && printf '%s\n' "${FAKE_GH_ISSUE_NUM:-9001}" >> "$FAKE_GH_LOG"
        printf 'https://github.com/example/adopted-fixture/issues/%s\n' "${FAKE_GH_ISSUE_NUM:-9001}"
        exit 0 ;;
      view)
        printf '%s\n' "${FAKE_GH_ISSUE_BODY:-}"
        exit 0 ;;
      edit)
        exit 0 ;;
    esac
    ;;
esac
echo "fake-gh: unhandled invocation: $*" >&2
exit 1
FAKEGH
chmod +x "$fakebin/gh"

# One template source for every adopt.sh fixture below: this checkout's own committed
# HEAD, tagged rather than assumed to already be the public "latest tag" (see above).
adopt_tag="adopt-fixture-tag"
git -C "$root" push --quiet "$srcrepo" "HEAD:refs/tags/$adopt_tag" || {
  echo "could not tag the test source for adopt.sh's fixtures" >&2
  exit 2
}

# make_consumer_fixture <dir> <trunk> — an existing repository with its own remote,
# a real app file, and a clean, fully-pushed trunk: exactly the state adopt.sh's own
# preconditions require before it will touch anything.
make_consumer_fixture() {
  local dir="$1" trunk="$2" origin="$1.origin.git"
  git init --quiet --bare "$origin" || return 1
  git -C "$origin" symbolic-ref HEAD "refs/heads/$trunk" || return 1
  git init --quiet -b "$trunk" "$dir" || return 1
  git -C "$dir" config user.email "$GIT_AUTHOR_EMAIL"
  git -C "$dir" config user.name "$GIT_AUTHOR_NAME"
  mkdir -p "$dir/src"
  printf '# fixture consumer repo\n' > "$dir/README.md"
  printf "print('hello from the fixture app')\n" > "$dir/src/app.py"
  git -C "$dir" add -A
  git -C "$dir" commit --quiet -m "seed the fixture repo"
  git -C "$dir" remote add origin "$origin"
  git -C "$dir" push --quiet -u origin "$trunk"
}

# push_fixture <dir> <trunk> — commits whatever is staged/changed and pushes, leaving
# the fixture in the clean, up-to-date state adopt.sh's preconditions require.
push_fixture() {
  local dir="$1" trunk="$2" msg="${3:-fixture setup}"
  git -C "$dir" add -A
  git -C "$dir" commit --quiet -m "$msg"
  git -C "$dir" push --quiet origin "$trunk"
}

adopt_fixtures="$work/adopt-fixtures"
mkdir -p "$adopt_fixtures"

# --- 11. happy path: real CLAUDE.md, own .gitignore, own ci.yml, a non-colliding ADR ---
echo "happy path"
happy="$adopt_fixtures/happy"
make_consumer_fixture "$happy" main
# CONSTITUTION.md §3 cites "README.md §Bootstrapping" three times, and
# consistency-check.sh's named-section check (its own §2b) resolves every such
# citation against the file actually present — including in an adopted repository,
# where adopt.sh deliberately never touches README.md (docs/architecture/adoption.md
# §2: "README.md ... never touched, in either direction"). A real team's own
# pre-existing README essentially never carries a heading named that, so this specific
# CONSTITUTION.md cross-reference fails consistency-check.sh in every real adoption
# until it does — a pre-existing gap in the adoption design this task's record flags
# as its own follow-up, not something installer/ can fix (CONSTITUTION.md is outside
# this task's scope and is protected in its own right). This fixture's README carries
# the heading only so the mechanics under test — the merge/add/refuse plan itself —
# aren't obscured by that separate, already-flagged defect.
printf '# fixture consumer repo\n\n## Bootstrapping\n\nHow this fixture repo itself gets set up locally (present only to satisfy\nCONSTITUTION.md'"'"'s README.md §Bootstrapping cross-reference — see the note above).\n' > "$happy/README.md"
printf 'These are the fixture team'"'"'s own pre-t-workflow instructions.\nUnique marker: CLAUDE-MD-FIXTURE-MARKER\n' > "$happy/CLAUDE.md"
printf 'fixture-build-cache/\nUnique marker: GITIGNORE-FIXTURE-MARKER\n' > "$happy/.gitignore"
mkdir -p "$happy/.github/workflows"
printf 'name: legacy-ci\nUnique marker: CI-YML-FIXTURE-MARKER\non: [push]\njobs:\n  build:\n    runs-on: ubuntu-latest\n    steps:\n      - run: echo hi\n' > "$happy/.github/workflows/ci.yml"
mkdir -p "$happy/docs/adr"
printf '# 100 — A fixture-local decision\n\nNon-colliding: numbered 100+, per docs/architecture/local-slots.md.\n' > "$happy/docs/adr/100-a-fixture-local-decision.md"
push_fixture "$happy" main "add pre-adoption content"

happy_log="$work/happy-gh.log"; rm -f "$happy_log"
happy_out=$(cd "$happy" && \
  PATH="$fakebin:$PATH" FAKE_GH_TRUNK=main FAKE_GH_LOG="$happy_log" FAKE_GH_ISSUE_NUM=501 \
  bash "$root/installer/adopt.sh" --ref "$adopt_tag" --source "$srcrepo" \
       --template example/adopted-fixture --build-command 'make fixture-test' 2>&1); happy_rc=$?
if [ "$happy_rc" -eq 0 ]; then
  ok "exits 0"
else
  bad "exits 0 (got $happy_rc)"
  printf '%s\n' "$happy_out" | sed 's/^/    /'
fi

check "created exactly one adoption issue (the fake gh log)" \
  bash -c '[ "$(wc -l < "$1")" = 1 ]' _ "$happy_log"
check "checked out the adoption branch" \
  bash -c 'cd "$1" && [ "$(git symbolic-ref --short HEAD)" = wip/501-adopt-t-workflow ]' _ "$happy"
check "the branch was never pushed" \
  bash -c '[ -z "$(git -C "$1" ls-remote origin "refs/heads/wip/*")" ]' _ "$happy"
check "the working tree is clean (everything committed)" \
  bash -c '[ -z "$(git -C "$1" status --porcelain)" ]' _ "$happy"

check "manifest validates" \
  bash -c 'cd "$1" && ./.t-workflow/scripts/check-manifest.sh' _ "$happy"
check "consistency-check.sh passes" \
  bash -c 'cd "$1" && ./.t-workflow/scripts/consistency-check.sh' _ "$happy"
check "the record exists in the right bucket" \
  test -f "$happy/docs/tasks/000500/501-adopt-t-workflow.md"
check "the record is a real record for task 501" \
  bash -c 'cd "$1" && ./.t-workflow/scripts/check-record.sh 501 docs/tasks/000500/501-adopt-t-workflow.md' _ "$happy"

echo "  no consumer content lost"
check "CLAUDE.md's content survives, folded into AGENTS.md" \
  grep -q "CLAUDE-MD-FIXTURE-MARKER" "$happy/AGENTS.md"
check "CLAUDE.md itself became the template's alias symlink" \
  test -L "$happy/CLAUDE.md"
check ".gitignore keeps the consumer's own entry" \
  grep -q "GITIGNORE-FIXTURE-MARKER" "$happy/.gitignore"
check ".gitignore also keeps the template's own entries" \
  grep -q '\.DS_Store' "$happy/.gitignore"
check "the consumer's ci.yml was renamed, not deleted" \
  grep -q "CI-YML-FIXTURE-MARKER" "$happy/.github/workflows/ci-legacy.yml"
check "ci.yml is now the template's own" \
  grep -q "consistency-check.sh" "$happy/.github/workflows/ci.yml"
check "the consumer's own ADR is untouched" \
  test -f "$happy/docs/adr/100-a-fixture-local-decision.md"

# AGENTS.md's marker pairs are addressed by ordinal in adopt.sh (splice_local_slot),
# so each piece of consumer content must land in the slot whose heading names it —
# #183 added a fourth pair under ## Checks and moved project notes to the fifth.
echo "  each AGENTS.md slot holds its own kind of content"
agents_section() { # agents_section <file> <heading-regex> <stop-regex> — the section's text up to the next line matching <stop-regex>
  awk -v h="$2" -v stop="$3" '$0 ~ h { f = 1; next } $0 ~ stop { f = 0 } f' "$1"
}
export -f agents_section   # the checks below call it from `bash -c` subshells
h2='^## '      # stop at the next h2 — harvested notes carry their own "### From <file>" h3 headings
h2h3='^##'     # stop at the next h2 or h3
export h2 h2h3  # read inside the same `bash -c` subshells
check "the build command landed in §Checks item 1" \
  bash -c 'agents_section "$1" "^## Checks$" "$h2h3" | grep -q "1\. \`make fixture-test\`"' _ "$happy/AGENTS.md"
check "the harvested CLAUDE.md landed under §Project notes" \
  bash -c 'agents_section "$1" "^## Project notes$" "$h2" | grep -q CLAUDE-MD-FIXTURE-MARKER' _ "$happy/AGENTS.md"
check "the documentation-only slot still holds the template placeholder" \
  bash -c 'agents_section "$1" "^### Documentation-only paths$" "$h2h3" | grep -q "reserved: this project.s own documentation-only paths"' _ "$happy/AGENTS.md"
check "the documentation-only slot holds no harvested notes" \
  bash -c '! agents_section "$1" "^### Documentation-only paths$" "$h2h3" | grep -q CLAUDE-MD-FIXTURE-MARKER' _ "$happy/AGENTS.md"
check "docs-only.sh --list in the adopted repo prints the defaults" \
  bash -c 'cd "$1" && [ "$(./.t-workflow/scripts/docs-only.sh --list)" = "$(printf "*.md\ndocs/**")" ]' _ "$happy"
check "the Project checks step carries the documentation-only guard" \
  bash -c 'grep -A1 "name: Project checks" "$1" | grep -q "steps.docs-only.outputs.docs_only != '"'"'true'"'"'"' _ "$happy/.github/workflows/ci.yml"
check "the Project checks step runs the build command" \
  grep -q "run: make fixture-test" "$happy/.github/workflows/ci.yml"
check "ci.yml still parses as YAML" \
  python3 -c 'import sys, yaml; yaml.safe_load(open(sys.argv[1]))' "$happy/.github/workflows/ci.yml"
check "the fixture app file is untouched" \
  test -f "$happy/src/app.py"
check "README.md was never touched" \
  grep -q "fixture consumer repo" "$happy/README.md"
check "installer/ itself was not copied into the consumer" \
  test ! -e "$happy/installer"
# adopt.sh filled this consumer's slots for real (build command, project notes, the
# consumer's own .gitignore entries, a legacy ci.yml renamed) — so the template's own
# test script must pass here too, the same as in section 7c's hand-filled consumer.
if out=$(cd "$happy" && ./.t-workflow/scripts/plumbing-test.sh 2>&1); then
  ok "plumbing-test.sh passes inside the adopted consumer"
else
  bad "plumbing-test.sh passes inside the adopted consumer"; printf '%s\n' "$out" | grep -E 'FAIL|passed' | sed 's/^/    /'
fi
echo

# --- 12. refusals: each writes nothing and never reaches the tracker ------------------
echo "refusals"

assert_refused() { # assert_refused <name> <fixture-dir> <trunk>
  local name="$1" dir="$2" trunk="$3" log="$2.gh.log" out rc
  rm -f "$log"
  out=$(cd "$dir" && \
    PATH="$fakebin:$PATH" FAKE_GH_TRUNK="$trunk" FAKE_GH_LOG="$log" FAKE_GH_ISSUE_NUM=999999 \
    bash "$root/installer/adopt.sh" --ref "$adopt_tag" --source "$srcrepo" \
         --template example/adopted-fixture 2>&1); rc=$?
  if [ "$rc" -ne 0 ]; then ok "$name: refuses"; else bad "$name: refuses (exited 0)"; fi
  check "$name: still on the trunk" \
    bash -c 'cd "$1" && [ "$(git symbolic-ref --short HEAD)" = "$2" ]' _ "$dir" "$trunk"
  check "$name: working tree unchanged" \
    bash -c '[ -z "$(git -C "$1" status --porcelain)" ]' _ "$dir"
  check "$name: never reached the tracker" test ! -s "$log"
  case "$out" in
    *"nothing was written"*|*Refusing*) ok "$name: message names the refusal" ;;
    *) bad "$name: message names the refusal" ;;
  esac
}

t_star="$adopt_fixtures/t-star"
make_consumer_fixture "$t_star" main
mkdir -p "$t_star/.claude/skills/t-work"
printf '# a consumer skill that happens to share a reserved name\n' > "$t_star/.claude/skills/t-work/SKILL.md"
push_fixture "$t_star" main "add a colliding t-work skill"
assert_refused "a t-* skill directory collides" "$t_star" main

adr_collide="$adopt_fixtures/adr-collide"
make_consumer_fixture "$adr_collide" main
mkdir -p "$adr_collide/docs/adr"
printf '# 003 — Something this team decided on its own\n' > "$adr_collide/docs/adr/003-something-this-team-decided.md"
push_fixture "$adr_collide" main "add a colliding local ADR number"
assert_refused "a colliding ADR number" "$adr_collide" main

const_collide="$adopt_fixtures/constitution-collide"
make_consumer_fixture "$const_collide" main
printf '# Not the template'"'"'s constitution\n' > "$const_collide/CONSTITUTION.md"
push_fixture "$const_collide" main "add an unrelated CONSTITUTION.md"
assert_refused "an existing CONSTITUTION.md" "$const_collide" main
echo

# --- 13. --dry-run writes nothing and never reaches the tracker -----------------------
echo "dry-run"
dry="$adopt_fixtures/dry-run"
make_consumer_fixture "$dry" main
dry_log="$dry.gh.log"; rm -f "$dry_log"
dry_out=$(cd "$dry" && \
  PATH="$fakebin:$PATH" FAKE_GH_TRUNK=main FAKE_GH_LOG="$dry_log" FAKE_GH_ISSUE_NUM=999998 \
  bash "$root/installer/adopt.sh" --ref "$adopt_tag" --source "$srcrepo" \
       --template example/adopted-fixture --dry-run 2>&1); dry_rc=$?
[ "$dry_rc" -eq 0 ] && ok "exits 0" || bad "exits 0 (got $dry_rc)"
case "$dry_out" in *"nothing was written"*) ok "says nothing was written" ;; *) bad "says nothing was written" ;; esac
check "still on the trunk" \
  bash -c 'cd "$1" && [ "$(git symbolic-ref --short HEAD)" = main ]' _ "$dry"
check "no manifest was written" test ! -e "$dry/.template-manifest.json"
check "working tree unchanged" \
  bash -c '[ -z "$(git -C "$1" status --porcelain)" ]' _ "$dry"
check "never reached the tracker" test ! -s "$dry_log"
echo

# --- 14. a non-main trunk lands in ci.yml's slot ---------------------------------------
echo "non-main trunk"
nonmain="$adopt_fixtures/nonmain"
make_consumer_fixture "$nonmain" trunk
nonmain_log="$nonmain.gh.log"; rm -f "$nonmain_log"
nonmain_out=$(cd "$nonmain" && \
  PATH="$fakebin:$PATH" FAKE_GH_TRUNK=trunk FAKE_GH_LOG="$nonmain_log" FAKE_GH_ISSUE_NUM=601 \
  bash "$root/installer/adopt.sh" --ref "$adopt_tag" --source "$srcrepo" \
       --template example/adopted-fixture 2>&1); nonmain_rc=$?
if [ "$nonmain_rc" -eq 0 ]; then
  ok "exits 0"
  check "ci.yml's push trigger names the real trunk" \
    grep -q 'branches: \[trunk\]' "$nonmain/.github/workflows/ci.yml"
  check "ci.yml no longer says main" \
    bash -c '! grep -q "branches: \[main\]" "$1"' _ "$nonmain/.github/workflows/ci.yml"
else
  bad "exits 0 (got $nonmain_rc)"
  printf '%s\n' "$nonmain_out" | sed 's/^/    /'
fi
echo

# --- 15. --help documents every flag ----------------------------------------------------
echo "adopt.sh --help"
adopt_help=$(bash "$root/installer/adopt.sh" --help 2>&1); adopt_help_rc=$?
[ "$adopt_help_rc" -eq 0 ] && ok "exits 0" || bad "exits 0 (got $adopt_help_rc)"
for flag in --ref --source --template --build-command --dry-run --help; do
  case "$adopt_help" in *"$flag"*) ok "documents $flag" ;; *) bad "documents $flag" ;; esac
done
echo

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
