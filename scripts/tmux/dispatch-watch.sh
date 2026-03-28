#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
APPLY="false"
INTERVAL_SECONDS="3"
ONCE="false"

usage() {
	cat <<'EOF'
usage: dispatch-watch.sh --config <file> [--apply] [--interval <seconds>] [--once]

Watches the configured dispatch inbox directory and runs dispatch for any
new .md or .txt request files.
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--config)
			CONFIG_PATH="$2"
			shift 2
			;;
		--apply)
			APPLY="true"
			shift
			;;
		--interval)
			INTERVAL_SECONDS="$2"
			shift 2
			;;
		--once)
			ONCE="true"
			shift
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

load_config "${CONFIG_PATH}"

mkdir -p "${DISPATCH_INBOX_ROOT}"
PROCESSED_DIR="${DISPATCH_INBOX_ROOT}/processed"
FAILED_DIR="${DISPATCH_INBOX_ROOT}/failed"
mkdir -p "${PROCESSED_DIR}" "${FAILED_DIR}"

process_file() {
	local request_file="$1"
	local base_name
	base_name="$(basename "${request_file}")"
	local lock_file="${request_file}.lock"
	local processed_file="${PROCESSED_DIR}/${base_name}"
	local failed_file="${FAILED_DIR}/${base_name}"
	local dispatch_cmd=("${SCRIPT_DIR}/dispatch.sh" --config "${CONFIG_PATH}" --json)
	local output_file
	local log_file
	output_file="$(mktemp)"
	log_file="$(mktemp)"

	if [[ "${APPLY}" == "true" ]]; then
		dispatch_cmd+=(--apply)
	fi

	if [[ -e "${lock_file}" || -e "${processed_file}" ]]; then
		return 0
	fi

	mv "${request_file}" "${lock_file}"
	printf 'processing: %s\n' "${base_name}"

	if "${dispatch_cmd[@]}" "${lock_file}" >"${output_file}" 2>"${log_file}"; then
		mv "${lock_file}" "${processed_file}"
		printf 'processed: %s\n' "${base_name}"
	else
		mv "${lock_file}" "${failed_file}"
		printf 'failed: %s\n' "${base_name}" >&2
		cat "${log_file}" >&2 || true
	fi

	rm -f "${output_file}" "${log_file}"
}

watch_once() {
	local found="false"
	local file=""

	while IFS= read -r file; do
		found="true"
		process_file "${file}"
	done < <(find "${DISPATCH_INBOX_ROOT}" -maxdepth 1 -type f \( -name '*.md' -o -name '*.txt' \) | sort)

	if [[ "${found}" != "true" ]]; then
		printf 'dispatch inbox idle: %s\n' "${DISPATCH_INBOX_ROOT}"
	fi
}

print_header "dispatch watch"
echo "inbox: ${DISPATCH_INBOX_ROOT}"
echo "apply: ${APPLY}"
echo "interval_seconds: ${INTERVAL_SECONDS}"

if [[ "${ONCE}" == "true" ]]; then
	watch_once
	exit 0
fi

while true; do
	watch_once
	sleep "${INTERVAL_SECONDS}"
done
