#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
STATUS_VALUE=""
TICKET_INPUT=""
NOTE_VALUE=""

usage() {
	cat <<'EOF'
usage: mark-ticket.sh --config <file> --status <done|done-awaiting-review|blocked|canceled|proposed|approved|rejected|needs-triage|applied-task|applied-review|approved-task|approved-review> [--note <text>] <ticket-file|target/slug|slug>
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--config)
			CONFIG_PATH="$2"
			shift 2
			;;
		--status)
			STATUS_VALUE="$2"
			shift 2
			;;
		--note)
			NOTE_VALUE="$2"
			shift 2
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			if [[ -z "${TICKET_INPUT}" ]]; then
				TICKET_INPUT="$1"
				shift
			else
				die "too many positional arguments"
			fi
			;;
	esac
done

[[ -n "${STATUS_VALUE}" ]] || die "missing --status"
[[ -n "${TICKET_INPUT}" ]] || die "missing ticket identifier"

case "${STATUS_VALUE}" in
	done|done-awaiting-review|blocked|canceled|proposed|approved|rejected|needs-triage|applied-task|applied-review|approved-task|approved-review)
		;;
	*)
		die "unsupported status '${STATUS_VALUE}'"
		;;
esac

load_config "${CONFIG_PATH}"
mkdir -p "${DISPATCH_TICKET_ROOT}"

TICKET_FILE="$(resolve_ticket_file "${TICKET_INPUT}")"

python3 - "${TICKET_FILE}" "${STATUS_VALUE}" "${NOTE_VALUE}" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

ticket_path = Path(sys.argv[1])
status = sys.argv[2]
note = sys.argv[3]

data = json.loads(ticket_path.read_text())
data["status"] = status
data["updated_at"] = datetime.now(timezone.utc).isoformat()
if note:
    notes = data.get("notes", [])
    notes.append({"status": status, "note": note, "updated_at": data["updated_at"]})
    data["notes"] = notes
ticket_path.write_text(json.dumps(data, ensure_ascii=False))
print(ticket_path)
print(status)
PY
