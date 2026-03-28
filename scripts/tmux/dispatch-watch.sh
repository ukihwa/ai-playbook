#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
APPLY="false"
AUTO_APPLY=""
INTERVAL_SECONDS="3"
ONCE="false"

usage() {
	cat <<'EOF'
usage: dispatch-watch.sh --config <file> [--apply] [--auto-apply] [--interval <seconds>] [--once]

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
		--auto-apply)
			AUTO_APPLY="true"
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

if [[ -z "${AUTO_APPLY}" ]]; then
	AUTO_APPLY="${DISPATCH_AUTO_APPLY:-false}"
fi

AUTO_APPLY_MIN_CONFIDENCE="${DISPATCH_AUTO_APPLY_MIN_CONFIDENCE:-0.75}"
AUTO_APPLY_ALLOWED_TARGETS="${DISPATCH_AUTO_APPLY_ALLOWED_TARGETS:-pro-web,frontend,app}"
AUTO_APPLY_BLOCK_REVIEW_ONLY="${DISPATCH_AUTO_APPLY_BLOCK_REVIEW_ONLY:-true}"
AUTO_APPLY_BLOCK_CROSS_VERIFY="${DISPATCH_AUTO_APPLY_BLOCK_CROSS_VERIFY:-true}"

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

	if [[ -e "${lock_file}" || -e "${processed_file}" ]]; then
		return 0
	fi

	mv "${request_file}" "${lock_file}"
	printf 'processing: %s\n' "${base_name}"

	if "${dispatch_cmd[@]}" "${lock_file}" >"${output_file}" 2>"${log_file}"; then
		if [[ "${APPLY}" == "true" ]]; then
			local ticket_ref=""
			ticket_ref="$(python3 - "${output_file}" <<'PY'
import json, sys
data = json.loads(open(sys.argv[1]).read())
print(f"{data['target']}/{data['slug']}")
PY
)"
			printf 'applying: %s\n' "${ticket_ref}"
			"${SCRIPT_DIR}/apply-ticket.sh" --config "${CONFIG_PATH}" "${ticket_ref}" >>"${log_file}" 2>&1
		elif [[ "${AUTO_APPLY}" == "true" ]]; then
			local auto_apply_decision=""
			auto_apply_decision="$(python3 - "${output_file}" "${AUTO_APPLY_MIN_CONFIDENCE}" "${AUTO_APPLY_ALLOWED_TARGETS}" "${AUTO_APPLY_BLOCK_REVIEW_ONLY}" "${AUTO_APPLY_BLOCK_CROSS_VERIFY}" <<'PY'
import json
import sys

data = json.loads(open(sys.argv[1]).read())
min_conf = float(sys.argv[2])
allowed_targets = {item.strip() for item in sys.argv[3].split(",") if item.strip()}
block_review_only = sys.argv[4].lower() == "true"
block_cross_verify = sys.argv[5].lower() == "true"

target = data.get("target", "")
confidence = float(data.get("confidence", 0))
review_only = bool(data.get("review_only"))
cross_verify = bool(data.get("cross_verify_candidate"))

eligible = True
reason = "eligible"
if allowed_targets and target not in allowed_targets:
    eligible = False
    reason = f"target-not-allowed:{target}"
elif confidence < min_conf:
    eligible = False
    reason = f"low-confidence:{confidence:.2f}"
elif block_review_only and review_only:
    eligible = False
    reason = "review-only"
elif block_cross_verify and cross_verify:
    eligible = False
    reason = "cross-verify"

if eligible:
    print(f"apply {target}/{data.get('slug','')}")
else:
    print(f"skip {reason}")
PY
)"
			if [[ "${auto_apply_decision}" == apply\ * ]]; then
				local ticket_ref=""
				ticket_ref="${auto_apply_decision#apply }"
				printf 'auto-applying: %s\n' "${ticket_ref}"
				"${SCRIPT_DIR}/apply-ticket.sh" --config "${CONFIG_PATH}" "${ticket_ref}" >>"${log_file}" 2>&1
			else
				printf 'auto-apply skipped: %s\n' "${auto_apply_decision#skip }"
			fi
		fi
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
echo "auto_apply: ${AUTO_APPLY}"
echo "interval_seconds: ${INTERVAL_SECONDS}"

if [[ "${ONCE}" == "true" ]]; then
	watch_once
	exit 0
fi

while true; do
	watch_once
	sleep "${INTERVAL_SECONDS}"
done
