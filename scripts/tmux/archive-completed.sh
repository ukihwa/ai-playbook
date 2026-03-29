#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
LATEST_LIMIT=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		--config)
			CONFIG_PATH="$2"
			shift 2
			;;
		--latest)
			LATEST_LIMIT="$2"
			shift 2
			;;
		*)
			die "usage: archive-completed.sh --config <file> [--latest <n>]"
			;;
	esac
done

load_config "${CONFIG_PATH}"
mkdir -p "${DISPATCH_TICKET_ROOT}" "${DISPATCH_ARCHIVE_ROOT}"

python3 - "${DISPATCH_TICKET_ROOT}" "${DISPATCH_ARCHIVE_ROOT}" "${LATEST_LIMIT}" <<'PY'
import json
import shutil
import sys
from pathlib import Path

root = Path(sys.argv[1])
archive = Path(sys.argv[2])
latest_limit = int(sys.argv[3]) if sys.argv[3] else None
terminal_statuses = {"done", "blocked", "canceled", "rejected"}

items = []
for path in sorted(root.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True):
    try:
        data = json.loads(path.read_text())
    except Exception:
        continue
    if data.get("status") in terminal_statuses:
        items.append(path)

if latest_limit is not None:
    items = items[:latest_limit]

for path in items:
    dest = archive / path.name
    shutil.move(str(path), str(dest))
    print(dest)
PY
