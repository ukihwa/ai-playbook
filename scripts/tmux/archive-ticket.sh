#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
TICKET_INPUT=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		--config)
			CONFIG_PATH="$2"
			shift 2
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

[[ -n "${TICKET_INPUT}" ]] || die "usage: archive-ticket.sh --config <file> <ticket-file|target/slug|slug>"

load_config "${CONFIG_PATH}"
mkdir -p "${DISPATCH_TICKET_ROOT}" "${DISPATCH_ARCHIVE_ROOT}"

TICKET_FILE="$(resolve_ticket_file "${TICKET_INPUT}")"
DEST_FILE="${DISPATCH_ARCHIVE_ROOT}/$(basename "${TICKET_FILE}")"

if [[ "${TICKET_FILE}" == "${DEST_FILE}" ]]; then
	echo "${DEST_FILE}"
	exit 0
fi

mv "${TICKET_FILE}" "${DEST_FILE}"
print_header "ticket archived"
echo "from: ${TICKET_FILE}"
echo "to: ${DEST_FILE}"
