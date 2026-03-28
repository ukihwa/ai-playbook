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
			die "usage: intake-report.sh --config <file> [--json]"
			;;
	esac
done

load_config "${CONFIG_PATH}"
mkdir -p "${INTAKE_AUDIT_ROOT}"

python3 - "${INTAKE_AUDIT_ROOT}" "${JSON_OUTPUT}" <<'PY'
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
    items.append(data)

classification_counts = Counter(item.get("classification", "unknown") for item in items)
reason_counts = Counter(item.get("reason", "unknown") for item in items)
recent = items[:5]

payload = {
    "root": str(root),
    "total": len(items),
    "classification_counts": dict(classification_counts),
    "reason_counts": dict(reason_counts),
    "recent": recent,
}

if json_output:
    print(json.dumps(payload, ensure_ascii=False))
    raise SystemExit(0)

print("== intake report ==")
print(f"root: {root}")
print(f"total: {len(items)}")
print("classification_counts:")
if classification_counts:
    for key, value in sorted(classification_counts.items()):
        print(f"  - {key}: {value}")
else:
    print("  - (empty)")

print("reason_counts:")
if reason_counts:
    for key, value in sorted(reason_counts.items()):
        print(f"  - {key}: {value}")
else:
    print("  - (empty)")

print("recent:")
if recent:
    for item in recent:
        print(f"  - [{item.get('classification', 'unknown')}] {item.get('reason', '')}: {item.get('request', '')}")
else:
    print("  - (empty)")
PY
