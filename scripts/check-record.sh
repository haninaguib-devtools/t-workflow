#!/usr/bin/env bash
# Verifies a task record's identity lines and template shape against the task id
# derived from its branch — the mechanical form of the record-honesty rule (goal item
# 4 of #30). ci.yml's `record` job locates the file; this checks what is inside it.
# Section headings are read from the template itself, never hardcoded, so this cannot
# drift from docs/tasks/TEMPLATE.md.
#
# Usage: scripts/check-record.sh <id> <record-file> [template-file]
# Exit 0 = the record is real; 1 = a check failed (reasons on stdout); 2 = bad usage.
set -uo pipefail

id="${1:-}"
file="${2:-}"
template="${3:-docs/tasks/TEMPLATE.md}"

if [ -z "$id" ] || [ -z "$file" ]; then
  echo "usage: check-record.sh <id> <record-file> [template-file]" >&2
  exit 2
fi
if [ ! -f "$file" ]; then
  echo "FAIL: record file '$file' does not exist"
  exit 1
fi
if [ ! -f "$template" ]; then
  echo "usage: template '$template' does not exist — cannot verify sections" >&2
  exit 2
fi

fail=0

if ! grep -qE "^# ${id} — .+" "$file"; then
  echo "FAIL: heading does not match '# ${id} — <Title>'"
  fail=1
fi

if ! grep -qE "Issue: #${id}([^0-9]|\$)" "$file"; then
  echo "FAIL: no 'Issue: #${id}' line"
  fail=1
fi

while IFS= read -r heading; do
  if ! grep -qF "$heading" "$file"; then
    echo "FAIL: missing template section '$heading'"
    fail=1
  fi
done < <(grep -E '^## ' "$template")

[ "$fail" -eq 0 ] && echo "OK: record matches task $id and carries every template section"
exit "$fail"
