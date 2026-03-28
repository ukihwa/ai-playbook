#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
TEXT_VALUE=""
FILE_VALUE=""
MODE_VALUE="auto"
INTERVAL_SECONDS="3"

usage() {
	cat <<'EOF'
usage: intake.sh --config <file> [--text <request> | --file <path>] [--mode auto|apply|propose] [--interval <seconds>]

Creates a dispatch inbox item and immediately processes it once.
- auto: auto-apply if policy allows, otherwise escalate to needs-triage
- apply: always apply immediately
- propose: proposal only
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--config)
			CONFIG_PATH="$2"
			shift 2
			;;
		--text)
			TEXT_VALUE="$2"
			shift 2
			;;
		--file)
			FILE_VALUE="$2"
			shift 2
			;;
		--mode)
			MODE_VALUE="$2"
			shift 2
			;;
		--interval)
			INTERVAL_SECONDS="$2"
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

[[ -n "${CONFIG_PATH}" ]] || die "missing --config"
if [[ -n "${TEXT_VALUE}" && -n "${FILE_VALUE}" ]]; then
	die "use either --text or --file"
fi
if [[ -z "${TEXT_VALUE}" && -z "${FILE_VALUE}" ]]; then
	die "missing --text or --file"
fi

case "${MODE_VALUE}" in
	auto|apply|propose)
		;;
	*)
		die "unsupported --mode '${MODE_VALUE}'"
		;;
esac

load_config "${CONFIG_PATH}"

CREATE_CMD=("${ROOT_DIR}/scripts/helpers/create-dispatch-request.sh" --config "${CONFIG_PATH}")
if [[ -n "${TEXT_VALUE}" ]]; then
	CREATE_CMD+=(--text "${TEXT_VALUE}")
else
	[[ -f "${FILE_VALUE}" ]] || die "input file not found: ${FILE_VALUE}"
	CREATE_CMD+=("${FILE_VALUE}")
fi

REQUEST_FILE="$("${CREATE_CMD[@]}")"

WATCH_CMD=("${SCRIPT_DIR}/dispatch-watch.sh" --config "${CONFIG_PATH}" --interval "${INTERVAL_SECONDS}" --once)
case "${MODE_VALUE}" in
	auto)
		WATCH_CMD+=(--auto-apply)
		;;
	apply)
		WATCH_CMD+=(--apply)
		;;
	propose)
		;;
esac

"${WATCH_CMD[@]}"
printf 'request: %s\n' "${REQUEST_FILE}"
