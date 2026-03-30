#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
STATUS_VALUE="done"
NOTE_VALUE=""
KEEP_TICKET="false"
KEEP_WINDOW="false"
KEEP_WORKTREE="false"
DRY_RUN="false"
TICKET_INPUT=""

usage() {
	cat <<'EOF'
usage: finish-task.sh --config <file> [--status <done|done-awaiting-review|blocked|canceled|rejected>] [--note <text>] [--keep-ticket] [--keep-window] [--keep-worktree] [--dry-run] <ticket-file|target/slug|slug>
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
		--keep-ticket)
			KEEP_TICKET="true"
			shift
			;;
		--keep-window)
			KEEP_WINDOW="true"
			shift
			;;
		--keep-worktree)
			KEEP_WORKTREE="true"
			shift
			;;
		--dry-run)
			DRY_RUN="true"
			shift
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

case "${STATUS_VALUE}" in
	done|done-awaiting-review|blocked|canceled|rejected)
		;;
	*)
		die "unsupported finish status '${STATUS_VALUE}'"
		;;
esac

load_config "${CONFIG_PATH}"

TICKET_FILE="$(resolve_ticket_file "${TICKET_INPUT}")"

TICKET_META="$(
	python3 - "${TICKET_FILE}" <<'PY'
import json
import sys
from pathlib import Path

ticket = json.loads(Path(sys.argv[1]).read_text())
print("\t".join([
    str(ticket.get("target", "")),
    str(ticket.get("slug", "")),
    str(ticket.get("status", "")),
]))
PY
)"

IFS=$'\t' read -r TARGET SLUG CURRENT_STATUS <<< "${TICKET_META}"

[[ -n "${TARGET}" ]] || die "ticket is missing target: ${TICKET_FILE}"
[[ -n "${SLUG}" ]] || die "ticket is missing slug: ${TICKET_FILE}"

WINDOW_NAME="${TARGET}/${SLUG}"
WORKTREE_DIR="$(target_worktree_dir "${TARGET}" "${SLUG}")"

if [[ "${DRY_RUN}" == "true" ]]; then
	print_header "finish task dry run"
	echo "ticket: ${TICKET_FILE}"
	echo "current_status: ${CURRENT_STATUS}"
	echo "next_status: ${STATUS_VALUE}"
	echo "window: ${WINDOW_NAME}"
	echo "worktree: ${WORKTREE_DIR}"
	echo "archive_ticket: $([[ "${KEEP_TICKET}" == "true" ]] && echo false || echo true)"
	echo "cleanup_window: $([[ "${KEEP_WINDOW}" == "true" ]] && echo false || echo true)"
	echo "delete_worktree: $([[ "${KEEP_WORKTREE}" == "true" ]] && echo false || echo true)"
	exit 0
fi

MARK_ARGS=(--config "${CONFIG_PATH}" --status "${STATUS_VALUE}")
if [[ -n "${NOTE_VALUE}" ]]; then
	MARK_ARGS+=(--note "${NOTE_VALUE}")
fi
MARK_ARGS+=("${TICKET_FILE}")
"${SCRIPT_DIR}/mark-ticket.sh" "${MARK_ARGS[@]}" >/dev/null

if [[ "${KEEP_TICKET}" != "true" ]]; then
	"${SCRIPT_DIR}/archive-ticket.sh" --config "${CONFIG_PATH}" "${TICKET_FILE}" >/dev/null
fi

if [[ "${KEEP_WINDOW}" != "true" ]]; then
	CLEANUP_ARGS=(--config "${CONFIG_PATH}")
	if [[ "${KEEP_WORKTREE}" != "true" ]]; then
		CLEANUP_ARGS+=(--delete-worktree)
	fi
	CLEANUP_ARGS+=("${WINDOW_NAME}")
	"${SCRIPT_DIR}/cleanup-task.sh" "${CLEANUP_ARGS[@]}" >/dev/null
fi

print_header "finish task complete"
echo "ticket: ${TICKET_FILE}"
echo "status: ${STATUS_VALUE}"
echo "window: ${WINDOW_NAME}"
echo "archived: $([[ "${KEEP_TICKET}" == "true" ]] && echo false || echo true)"
echo "cleaned_window: $([[ "${KEEP_WINDOW}" == "true" ]] && echo false || echo true)"
echo "deleted_worktree: $([[ "${KEEP_WORKTREE}" == "true" ]] && echo false || echo true)"
