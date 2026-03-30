#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
AGENT_NAME="codex"
MODE="prompt"
PANE_INDEX="0"
TICKET_INPUT=""
NOTE_VALUE=""

usage() {
	cat <<'EOF'
usage: approve-ticket.sh --config <file> [--agent <name>] [--mode <mode>] [--pane <index>] [--note <text>] <ticket-file|target/slug|slug>
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--config)
			CONFIG_PATH="$2"
			shift 2
			;;
		--agent)
			AGENT_NAME="$2"
			shift 2
			;;
		--mode)
			MODE="$2"
			shift 2
			;;
		--pane)
			PANE_INDEX="$2"
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

[[ -n "${TICKET_INPUT}" ]] || die "missing ticket identifier"

MARK_CMD=("${SCRIPT_DIR}/mark-ticket.sh" --config "${CONFIG_PATH}" --status approved)
if [[ -n "${NOTE_VALUE}" ]]; then
	MARK_CMD+=(--note "${NOTE_VALUE}")
fi
MARK_CMD+=("${TICKET_INPUT}")
"${MARK_CMD[@]}" >/dev/null

python3 - "${SCRIPT_DIR}" "${CONFIG_PATH}" "${AGENT_NAME}" "${MODE}" "${PANE_INDEX}" "${TICKET_INPUT}" <<'PY'
import subprocess
import sys

script_dir = sys.argv[1]
config_path = sys.argv[2]
agent_name = sys.argv[3]
mode = sys.argv[4]
pane_index = sys.argv[5]
ticket_input = sys.argv[6]

subprocess.run(
    [
        f"{script_dir}/apply-ticket.sh",
        "--config", config_path,
        "--agent", agent_name,
        "--mode", mode,
        "--pane", pane_index,
        "--approved",
        ticket_input,
    ],
    check=True,
)
PY

load_config "${CONFIG_PATH}"
FINAL_TICKET_FILE="$(resolve_ticket_file "${TICKET_INPUT}")"
FINAL_STATE="$(
	python3 - "${FINAL_TICKET_FILE}" <<'PY'
import json
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text())
notes = data.get("notes", [])
latest_note = notes[-1].get("note", "") if notes else ""
print("\t".join([
    data.get("status", "unknown"),
    data.get("target", "?"),
    data.get("slug", "?"),
    latest_note,
]))
PY
)"

IFS=$'\t' read -r FINAL_STATUS FINAL_TARGET FINAL_SLUG FINAL_NOTE <<< "${FINAL_STATE}"

print_header "ticket approval submitted"
echo "ticket: ${TICKET_INPUT}"
echo "agent: ${AGENT_NAME}"
echo "mode: ${MODE}"
echo "result: ${FINAL_STATUS} (${FINAL_TARGET}/${FINAL_SLUG})"
if [[ -n "${FINAL_NOTE}" ]]; then
	echo "note: ${FINAL_NOTE}"
fi
