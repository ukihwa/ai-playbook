#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
JSON_OUTPUT="false"
LATEST_LIMIT="10"
INCLUDE_PROPOSED="false"

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
		--latest)
			LATEST_LIMIT="$2"
			shift 2
			;;
		--include-proposed)
			INCLUDE_PROPOSED="true"
			shift
			;;
		*)
			die "usage: daily-report.sh --config <file> [--json] [--latest <n>] [--include-proposed]"
			;;
	esac
done

load_config "${CONFIG_PATH}"
mkdir -p "${DISPATCH_TICKET_ROOT}"

python3 - "${DISPATCH_TICKET_ROOT}" "${JSON_OUTPUT}" "${LATEST_LIMIT}" "${INCLUDE_PROPOSED}" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
json_output = sys.argv[2] == "true"
latest_limit = int(sys.argv[3])
include_proposed = sys.argv[4] == "true"

allowed = {"applied-task", "applied-review", "done-awaiting-review", "done", "blocked"}
if include_proposed:
    allowed.add("proposed")

status_label = {
    "proposed": "대기",
    "applied-task": "진행중",
    "applied-review": "검토중",
    "done-awaiting-review": "검토대기",
    "done": "완료",
    "blocked": "진행중",
    "canceled": "취소",
}

items = []
for path in sorted(root.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True):
    try:
        data = json.loads(path.read_text())
    except Exception:
        continue
    status = data.get("status", "unknown")
    if status not in allowed:
        continue
    data["ticket_file"] = str(path)
    items.append(data)

items = items[:latest_limit]

payload = []
for item in items:
    target = item.get("target", "?")
    goal = item.get("goal") or f"{target}/{item.get('slug', '?')}"
    status = item.get("status", "unknown")
    payload.append(
        {
            "target": target,
            "slug": item.get("slug", "?"),
            "goal": goal,
            "status": status,
            "status_label": status_label.get(status, status),
            "ticket_file": item.get("ticket_file", ""),
        }
    )

if json_output:
    print(json.dumps(payload, ensure_ascii=False))
    raise SystemExit(0)

print("== daily report draft ==")
if not payload:
    print("(empty)")
    raise SystemExit(0)

for item in payload:
    print(f"- {item['goal']} / {item['status_label']}")
PY
