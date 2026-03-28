#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
JSON_OUTPUT="false"

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
		*)
			break
			;;
	esac
done

[[ $# -eq 0 ]] || die "usage: queue.sh --config <file> [--json]"

load_config "${CONFIG_PATH}"
mkdir -p "${DISPATCH_TICKET_ROOT}"

python3 - "${DISPATCH_TICKET_ROOT}" "${JSON_OUTPUT}" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
json_output = sys.argv[2] == "true"

items = []
for path in sorted(root.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True):
    try:
        data = json.loads(path.read_text())
    except Exception:
        continue
    data["ticket_file"] = str(path)
    items.append(data)

if json_output:
    print(json.dumps(items, ensure_ascii=False))
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
