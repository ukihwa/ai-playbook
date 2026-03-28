#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
JSON_OUTPUT="false"
CLASSIFICATION_FILTER=""
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
		--classification)
			CLASSIFICATION_FILTER="$2"
			shift 2
			;;
		--latest)
			LATEST_LIMIT="$2"
			shift 2
			;;
		*)
			die "usage: intake-history.sh --config <file> [--json] [--classification <value>] [--latest <n>]"
			;;
	esac
done

load_config "${CONFIG_PATH}"
mkdir -p "${INTAKE_AUDIT_ROOT}"

python3 - "${INTAKE_AUDIT_ROOT}" "${JSON_OUTPUT}" "${CLASSIFICATION_FILTER}" "${LATEST_LIMIT}" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
json_output = sys.argv[2] == "true"
classification_filter = sys.argv[3]
latest_limit = int(sys.argv[4])

items = []
for path in sorted(root.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True):
    try:
        data = json.loads(path.read_text())
    except Exception:
        continue
    if classification_filter and data.get("classification") != classification_filter:
        continue
    data["audit_file"] = str(path)
    items.append(data)

items = items[:latest_limit]

if json_output:
    print(json.dumps(items, ensure_ascii=False))
    raise SystemExit(0)

print("== intake history ==")
print(f"root: {root}")
if not items:
    print("(empty)")
    raise SystemExit(0)

for item in items:
    print(f"- [{item.get('classification', 'unknown')}] reason={item.get('reason', '')}")
    print(f"  created_at: {item.get('created_at', '')}")
    print(f"  request: {item.get('request', '')}")
    if item.get("request_file"):
        print(f"  request_file: {item.get('request_file')}")
PY
