#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
TICKET_INPUT=""
NOTE_VALUE=""

usage() {
	cat <<'EOF'
usage: reject-ticket.sh --config <file> [--note <text>] <ticket-file|target/slug|slug>
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--config)
			CONFIG_PATH="$2"
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

CMD=("${SCRIPT_DIR}/mark-ticket.sh" --config "${CONFIG_PATH}" --status rejected)
if [[ -n "${NOTE_VALUE}" ]]; then
	CMD+=(--note "${NOTE_VALUE}")
fi
CMD+=("${TICKET_INPUT}")

exec "${CMD[@]}"
