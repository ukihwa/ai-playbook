#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
MODE_VALUE="auto"

usage() {
	cat <<'EOF'
usage: triage-console.sh --config <file> [--mode auto|apply|propose]

Interactive triage console for plain natural-language requests.
Plain text is routed through intake. Slash-style helper commands are also available.
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--config)
			CONFIG_PATH="$2"
			shift 2
			;;
		--mode)
			MODE_VALUE="$2"
			shift 2
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			die "unknown argument: $1"
			;;
	esac
done

case "${MODE_VALUE}" in
	auto|apply|propose)
		;;
	*)
		die "unsupported --mode '${MODE_VALUE}'"
		;;
esac

need_cmd python3
load_config "${CONFIG_PATH}"

echo "== triage console =="
echo "project: ${PRODUCT_NAME}"
echo "mode: ${MODE_VALUE}"
echo "plain text -> intake"
echo "commands: /status, /queue, /queue-needs, /approve <ticket>, /reject <ticket> [note], /exit"
echo

while true; do
	printf 'triage> '
	if ! IFS= read -r line; then
		exit 0
	fi

	line="${line#"${line%%[![:space:]]*}"}"
	line="${line%"${line##*[![:space:]]}"}"
	[[ -n "${line}" ]] || continue

	case "${line}" in
		/exit|/quit)
			echo "bye"
			exit 0
			;;
		/status)
			"${SCRIPT_DIR}/status.sh" --config "${CONFIG_PATH}"
			continue
			;;
		/queue)
			"${SCRIPT_DIR}/queue.sh" --config "${CONFIG_PATH}"
			continue
			;;
		/queue-needs)
			"${SCRIPT_DIR}/queue.sh" --config "${CONFIG_PATH}" --status needs-triage
			continue
			;;
		/approve\ *)
			ticket="${line#"/approve "}"
			"${SCRIPT_DIR}/approve-ticket.sh" --config "${CONFIG_PATH}" "${ticket}"
			continue
			;;
		/reject\ *)
			rest="${line#"/reject "}"
			ticket="${rest%% *}"
			note=""
			if [[ "${rest}" != "${ticket}" ]]; then
				note="${rest#${ticket} }"
			fi
			if [[ -n "${note}" ]]; then
				"${SCRIPT_DIR}/reject-ticket.sh" --config "${CONFIG_PATH}" --note "${note}" "${ticket}"
			else
				"${SCRIPT_DIR}/reject-ticket.sh" --config "${CONFIG_PATH}" "${ticket}"
			fi
			continue
			;;
		/*)
			echo "unsupported command: ${line}"
			continue
			;;
	esac

	result="$("${SCRIPT_DIR}/intake.sh" --config "${CONFIG_PATH}" --mode "${MODE_VALUE}" --json --text "${line}")"
	python3 - "${result}" <<'PY'
import json
import sys

payload = json.loads(sys.argv[1])
classification = payload.get("classification", "unknown")
if classification == "ignore":
    print(f"ignored: {payload.get('reason', 'unknown')}")
else:
    print(f"queued: {payload.get('request', '')}")
PY
done
