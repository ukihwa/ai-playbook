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
			die "usage: report.sh --config <file> [--json]"
			;;
	esac
done

load_config "${CONFIG_PATH}"
mkdir -p "${DISPATCH_TICKET_ROOT}"

python3 - "${DISPATCH_TICKET_ROOT}" "${JSON_OUTPUT}" <<'PY'
import json
import sys
from collections import Counter
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

status_counts = Counter(item.get("status", "unknown") for item in items)
target_counts = Counter(item.get("target", "unknown") for item in items)
recent = items[:5]

payload = {
    "root": str(root),
    "total": len(items),
    "status_counts": dict(status_counts),
    "target_counts": dict(target_counts),
    "recent": recent,
}

if json_output:
    print(json.dumps(payload, ensure_ascii=False))
    raise SystemExit(0)

print("== dispatch report ==")
print(f"root: {root}")
print(f"total: {len(items)}")
print("status_counts:")
if status_counts:
    for status, count in sorted(status_counts.items()):
        print(f"  - {status}: {count}")
else:
    print("  - (empty)")

print("target_counts:")
if target_counts:
    for target, count in sorted(target_counts.items()):
        print(f"  - {target}: {count}")
else:
    print("  - (empty)")

print("recent:")
if recent:
    for item in recent:
        print(f"  - [{item.get('status', 'unknown')}] {item.get('target', '?')}/{item.get('slug', '?')}")
else:
    print("  - (empty)")

triage_needed = [item for item in items if item.get("status") == "needs-triage"]
print("triage_needed:")
if triage_needed:
    for item in triage_needed[:5]:
        print(f"  - {item.get('target', '?')}/{item.get('slug', '?')}")
else:
    print("  - (empty)")
PY
