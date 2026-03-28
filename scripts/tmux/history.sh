#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
JSON_OUTPUT="false"
STATUS_FILTER="done,blocked,canceled"
LATEST_LIMIT="10"

while [[ $# -gt 0 ]]; do
	case "$1" in
		--config)
			CONFIG_PATH="$2"
			shift 2
			;;
		--json)
			JSON_OUTPUT="true"
			shift
			;;
		--status)
			STATUS_FILTER="$2"
			shift 2
			;;
		--latest)
			LATEST_LIMIT="$2"
			shift 2
			;;
		*)
			die "usage: history.sh --config <file> [--json] [--status <csv>] [--latest <n>]"
			;;
	esac
done

load_config "${CONFIG_PATH}"
mkdir -p "${DISPATCH_TICKET_ROOT}"

python3 - "${DISPATCH_TICKET_ROOT}" "${JSON_OUTPUT}" "${STATUS_FILTER}" "${LATEST_LIMIT}" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
json_output = sys.argv[2] == "true"
status_filter = {item.strip() for item in sys.argv[3].split(",") if item.strip()}
latest_limit = int(sys.argv[4])

items = []
for path in sorted(root.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True):
    try:
        data = json.loads(path.read_text())
    except Exception:
        continue
    status = data.get("status", "unknown")
    if status_filter and status not in status_filter:
        continue
    data["ticket_file"] = str(path)
    items.append(data)

items = items[:latest_limit]

if json_output:
    print(json.dumps(items, ensure_ascii=False))
    raise SystemExit(0)

print("== dispatch history ==")
print(f"root: {root}")
print(f"statuses: {','.join(sorted(status_filter)) or '(all)'}")
if not items:
    print("(empty)")
    raise SystemExit(0)

for item in items:
    status = item.get("status", "unknown")
    target = item.get("target", "?")
    slug = item.get("slug", "?")
    updated = item.get("updated_at", "")
    print(f"- [{status}] {target}/{slug}")
    if updated:
        print(f"  updated_at: {updated}")
    goal = item.get("goal")
    if goal:
        print(f"  goal: {goal}")
    notes = item.get("notes", [])
    if notes:
        latest = notes[-1]
        print(f"  note: {latest.get('note', '')}")
PY
