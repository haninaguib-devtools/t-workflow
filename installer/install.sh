#!/usr/bin/env bash
# t-workflow installer — the fetched entry point.
#
#   curl -fsSL https://raw.githubusercontent.com/haninaguib-devtools/t-workflow/main/installer/install.sh | bash
#
# This file is the public URL, so its path is a long-lived contract: it may grow options,
# but it does not move. It owns everything that talks to the person running it — argument
# parsing, --help, and the prompts — then clones the template and hands the resolved
# answers to installer/bootstrap.sh, which produces the project. The split exists because
# what `curl` fetches must be one self-contained file, while everything after the clone
# can be as many files as it likes.
#
# Prompts read from /dev/tty, never stdin: piping this script into bash gives bash the
# stdin, so a plain `read` would get the rest of the script (or nothing) instead of the
# person's answer.
#
# bash 3.2 compatible: macOS still ships it. No ${var,,}, no associative arrays, no
# mapfile, no `git init -b`.
set -euo pipefail

readonly DEFAULT_SOURCE="https://github.com/haninaguib-devtools/t-workflow.git"
readonly DEFAULT_REF="main"

die()  { printf 'installer: %s\n' "$*" >&2; exit 1; }
note() { printf '%s\n' "$*" >&2; }

usage() {
  cat <<'EOF'
Create a new project from the t-workflow delivery template.

Usage:
  install.sh [options]

Options:
  --name <name>          Project name. Becomes the directory name and, with a remote,
                         the repository name. Prompted for when omitted.
  --dir <path>           Parent directory to create the project in. Default: .
  --no-remote            Do not create a remote repository. Local project only.
  --remote               Create the remote repository without asking.
  --private              Create the remote repository private. Default.
  --public               Create the remote repository public.
  --source <url|path>    Where to clone the template from.
                         Default: the public t-workflow repository.
  --ref <ref>            Branch or tag to clone. Default: main. Not a raw commit id:
                         git clone cannot fetch one, and the installer refuses rather
                         than quietly installing something else.
  -h, --help             Print this and exit.

With --name and either --remote or --no-remote, the installer asks nothing and is safe
to run unattended. Without a terminal (no /dev/tty) those flags are required, because
there is nowhere to ask.

Passing flags through a pipe needs `bash -s --`, because otherwise bash reads them as
its own options and refuses:

  curl -fsSL <url> | bash -s -- --name my-project --no-remote

The generated project ships with NO LICENSE file: it is not this template's place to
choose one for you. Two things the installer cannot know are left for you to fill in —
CONSTITUTION.md section 4 (stack constraints) and AGENTS.md section Checks (your
build/test command). It prints both on exit.
EOF
}

# --- arguments --------------------------------------------------------------
name=""
parent="."
source_repo="$DEFAULT_SOURCE"
ref="$DEFAULT_REF"
remote="ask"          # ask | yes | no
visibility="private"

need_value() { [ "$2" -ge 2 ] || die "$1 needs a value (see --help)"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --name)    need_value --name $#;    name="$2";        shift 2 ;;
    --name=*)                           name="${1#*=}";   shift ;;
    --dir)     need_value --dir $#;     parent="$2";      shift 2 ;;
    --dir=*)                            parent="${1#*=}"; shift ;;
    --source)  need_value --source $#;  source_repo="$2"; shift 2 ;;
    --source=*)                         source_repo="${1#*=}"; shift ;;
    --ref)     need_value --ref $#;     ref="$2";         shift 2 ;;
    --ref=*)                            ref="${1#*=}";    shift ;;
    --no-remote) remote="no";  shift ;;
    --remote)    remote="yes"; shift ;;
    --private)   visibility="private"; shift ;;
    --public)    visibility="public";  shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; die "unknown option: $1" ;;
  esac
done

# --- prompting --------------------------------------------------------------
# A missing /dev/tty is the normal case in CI, a container, or any pipeline. Refusing
# with the flags named is the only correct answer: blocking on a read from a device that
# will never answer hangs the job until it times out.
# Opening it is the only honest test. `[ -r /dev/tty ]` is a stat-based access check and
# passes on a CI runner where /dev/tty exists but has no controlling terminal behind it —
# the open then fails with ENXIO, after the script has already decided it may prompt.
have_tty() { { true >/dev/tty; } 2>/dev/null; }

ask() { # ask <prompt> <default> <varname>
  local prompt="$1" default="$2" __var="$3" reply=""
  have_tty || die "no terminal available for prompts. Pass --name and --remote/--no-remote (see --help)."
  if [ -n "$default" ]; then
    printf '%s [%s]: ' "$prompt" "$default" >/dev/tty
  else
    printf '%s: ' "$prompt" >/dev/tty
  fi
  IFS= read -r reply </dev/tty || reply=""
  [ -n "$reply" ] || reply="$default"
  printf -v "$__var" '%s' "$reply"
}

ask_yes_no() { # ask_yes_no <prompt> <default y|n> <varname>
  local prompt="$1" default="$2" __var="$3" reply=""
  have_tty || die "no terminal available for prompts. Pass --name and --remote/--no-remote (see --help)."
  local hint="y/N"; [ "$default" = "y" ] && hint="Y/n"
  while :; do
    printf '%s [%s]: ' "$prompt" "$hint" >/dev/tty
    IFS= read -r reply </dev/tty || reply=""
    [ -n "$reply" ] || reply="$default"
    case "$(printf '%s' "$reply" | tr '[:upper:]' '[:lower:]')" in
      y|yes) printf -v "$__var" '%s' yes; return 0 ;;
      n|no)  printf -v "$__var" '%s' no;  return 0 ;;
    esac
    printf 'Please answer y or n.\n' >/dev/tty
  done
}

# A project name is both a directory name and a repository name, so it is held to the
# stricter of the two. Rejecting early matters: the alternative is discovering it after
# the clone, or worse, creating a directory nothing else will accept.
valid_name() {
  case "$1" in
    ""|.|..) return 1 ;;
    *[!A-Za-z0-9._-]*) return 1 ;;
    [!A-Za-z0-9]*) return 1 ;;
  esac
  [ "${#1}" -le 100 ]
}

if [ -z "$name" ]; then
  note "t-workflow installer"
  note ""
  while :; do
    ask "Project name" "" name
    valid_name "$name" && break
    note "  Not a usable name. Use letters, digits, dot, dash or underscore; start with a letter or digit."
  done
fi
valid_name "$name" || die "not a usable project name: '$name'"

[ -d "$parent" ] || die "parent directory does not exist: $parent"
# Normalize before building the target: the installer prints this path back to the
# person as a `cd` command, and "/tmp//name" or "./name" reads as a bug in the tool.
parent=$(cd "$parent" && pwd) || die "cannot read parent directory: $parent"
target="$parent/$name"
[ -e "$target" ] && die "'$target' already exists. Choose another name, or another --dir."

if [ "$remote" = "ask" ]; then
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    ask_yes_no "Create the GitHub repository '$name' now?" y remote
    if [ "$remote" = "yes" ]; then
      public_answer=""
      ask_yes_no "Make it public?" n public_answer
      if [ "$public_answer" = "yes" ]; then visibility="public"; else visibility="private"; fi
    fi
  else
    note "GitHub CLI not found or not logged in — creating a local project only."
    note "  Finish by hand later: gh auth login, gh repo create, then .t-workflow/scripts/github-bootstrap.sh"
    remote="no"
  fi
fi

# --- clone ------------------------------------------------------------------
command -v git >/dev/null 2>&1 || die "git is required and was not found on PATH."

tmp=$(mktemp -d "${TMPDIR:-/tmp}/t-workflow-install.XXXXXX") || die "could not create a temporary directory."
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT HUP INT TERM

# A local path is cloned through file:// so --depth is honoured rather than warned about;
# a URL is cloned as given.
clone_from="$source_repo"
if [ -d "$source_repo" ]; then
  abs=$(cd "$source_repo" && pwd) || die "cannot read --source directory: $source_repo"
  clone_from="file://$abs"
fi

note "Fetching the template ($ref)..."
# No fallback to the default branch on failure. Provenance is the whole reason the
# generated README records a commit, and silently installing main after being asked for
# something else records a version nobody asked for — worse than refusing, because it
# looks like it worked.
clone_err=$(mktemp "${TMPDIR:-/tmp}/t-workflow-clone.XXXXXX")
if ! git clone --quiet --depth 1 --branch "$ref" "$clone_from" "$tmp/src" 2>"$clone_err"; then
  msg=$(sed 's/^/    /' "$clone_err")
  rm -f "$clone_err"
  die "could not clone $source_repo at '$ref'. git said:
$msg
  --ref takes a branch or a tag. A raw commit id will not work here."
fi
rm -f "$clone_err"

[ -f "$tmp/src/installer/bootstrap.sh" ] \
  || die "the clone has no installer/bootstrap.sh — is $source_repo a t-workflow template?"

TWORKFLOW_SRC="$tmp/src" \
TWORKFLOW_NAME="$name" \
TWORKFLOW_TARGET="$target" \
TWORKFLOW_REMOTE="$remote" \
TWORKFLOW_VISIBILITY="$visibility" \
TWORKFLOW_SOURCE_URL="$source_repo" \
  bash "$tmp/src/installer/bootstrap.sh"
