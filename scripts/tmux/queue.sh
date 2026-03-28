#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
JSON_OUTPUT="false"
STATUS_FILTER=""
TARGET_FILTER=""
LATEST_LIMIT=""
COUNT_ONLY="false"

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
		--target)
			TARGET_FILTER="$2"
			shift 2
			;;
		--latest)
			LATEST_LIMIT="$2"
			shift 2
			;;
		--count)
			COUNT_ONLY="true"
			shift
			;;
		*)
			break
			;;
	esac
done

[[ $# -eq 0 ]] || die "usage: queue.sh --config <file> [--json] [--status <value>] [--target <value>] [--latest <n>] [--count]"

load_config "${CONFIG_PATH}"
mkdir -p "${DISPATCH_TICKET_ROOT}"

python3 - "${DISPATCH_TICKET_ROOT}" "${JSON_OUTPUT}" "${STATUS_FILTER}" "${TARGET_FILTER}" "${LATEST_LIMIT}" "${COUNT_ONLY}" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
json_output = sys.argv[2] == "true"
status_filter = sys.argv[3]
target_filter = sys.argv[4]
latest_limit = int(sys.argv[5]) if sys.argv[5] else None
count_only = sys.argv[6] == "true"

items = []
for path in sorted(root.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True):
    try:
        data = json.loads(path.read_text())
    except Exception:
        continue
    data["ticket_file"] = str(path)
    if status_filter and data.get("status") != status_filter:
        continue
    if target_filter and data.get("target") != target_filter:
        continue
    items.append(data)

if latest_limit is not None:
    items = items[:latest_limit]

if json_output:
    print(json.dumps(items, ensure_ascii=False))
    raise SystemExit(0)

if count_only:
    print(len(items))
    raise SystemExit(0)

print("== dispatch queue ==")
print(f"root: {root}")
if not items:
    print("(empty)")
    raise SystemExit(0)

for item in items:
    status = item.get("status", "unknown")
    target = item.get("target", "?")
    slug = item.get("slug", "?")
    confidence = item.get("confidence", "?")
    review_only = item.get("review_only", False)
    print(f"- [{status}] {target}/{slug} | confidence={confidence} | review_only={review_only}")
    print(f"  ticket: {item.get('ticket_file', '')}")
    goal = item.get("goal")
    if goal:
        print(f"  goal: {goal}")
PY
