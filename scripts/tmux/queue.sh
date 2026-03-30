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
INCLUDE_ARCHIVED="false"

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
		--include-archived)
			INCLUDE_ARCHIVED="true"
			shift
			;;
		*)
			break
			;;
	esac
done

[[ $# -eq 0 ]] || die "usage: queue.sh --config <file> [--json] [--status <value>] [--target <value>] [--latest <n>] [--count] [--include-archived]"

load_config "${CONFIG_PATH}"
mkdir -p "${DISPATCH_TICKET_ROOT}" "${DISPATCH_ARCHIVE_ROOT}"

python3 - "${DISPATCH_TICKET_ROOT}" "${DISPATCH_ARCHIVE_ROOT}" "${JSON_OUTPUT}" "${STATUS_FILTER}" "${TARGET_FILTER}" "${LATEST_LIMIT}" "${COUNT_ONLY}" "${INCLUDE_ARCHIVED}" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
archive_root = Path(sys.argv[2])
json_output = sys.argv[3] == "true"
status_filter = sys.argv[4]
target_filter = sys.argv[5]
latest_limit = int(sys.argv[6]) if sys.argv[6] else None
count_only = sys.argv[7] == "true"
include_archived = sys.argv[8] == "true"
active_statuses = {
    "proposed",
    "needs-triage",
    "approved",
    "approved-task",
    "approved-review",
    "applied-task",
    "applied-review",
}

items = []
roots = [root]
if include_archived and archive_root.exists():
    roots.append(archive_root)

for current_root in roots:
    for path in sorted(current_root.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True):
        try:
            data = json.loads(path.read_text())
        except Exception:
            continue
        data["ticket_file"] = str(path)
        if status_filter:
            if data.get("status") != status_filter:
                continue
        elif data.get("status") not in active_statuses:
            continue
        if target_filter and data.get("target") != target_filter:
            continue
        items.append(data)

items.sort(key=lambda item: Path(item["ticket_file"]).stat().st_mtime, reverse=True)

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
    notes = item.get("notes", [])
    if notes:
        latest = notes[-1]
        print(f"  note: {latest.get('note', '')}")
        note_text = (latest.get("note", "") or "").lower()
        if "bootstrap failed" in note_text:
            print("  bootstrap_issue: worker failed to start automatically")
PY
