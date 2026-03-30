#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
APPLY="false"

usage() {
	cat <<'EOF'
usage: repair-tasks.sh --config <file> [--apply]

Find stuck task windows whose primary pane is still a shell, mark their tickets as
needs-triage with a repair note, and clean up the tmux window/worktree when --apply
is provided. Without --apply it reports what would be repaired.
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
need_cmd tmux

is_exec_worker_pane() {
	local window_name="$1"
	local pane_index="${2:-0}"
	pane_contains_text "${window_name}" "${pane_index}" "OpenAI Codex v" \
		|| pane_contains_text "${window_name}" "${pane_index}" "session id:" \
		|| pane_contains_text "${window_name}" "${pane_index}" "approval: never"
}

print_header "repair tasks"
echo "session: ${TMUX_SESSION}"
echo "apply: ${APPLY}"

if ! tmux_has_session; then
	echo "session not created"
	exit 0
fi

BASE_WINDOWS_PATTERN='^(triage|fe-run|be-run|app-run|claude-fe|claude-be|claude-app|dispatch-watch|triage-watch)$'
FOUND="false"

while IFS= read -r window_name; do
	[[ -n "${window_name}" ]] || continue
	if [[ "${window_name}" =~ ${BASE_WINDOWS_PATTERN} ]]; then
		continue
	fi

	pane_zero_command="$(pane_current_command "${window_name}" 0)"
	if [[ "${pane_zero_command}" != "zsh" && "${pane_zero_command}" != "bash" && "${pane_zero_command}" != "sh" ]]; then
		continue
	fi
	if is_exec_worker_pane "${window_name}" 0; then
		continue
	fi

	target="${window_name%%/*}"
	slug="${window_name#*/}"
	if [[ -z "${target}" || -z "${slug}" || "${target}" == "${slug}" ]]; then
		continue
	fi

	if ! ticket_file="$(resolve_ticket_file "${target}/${slug}" 2>/dev/null)"; then
		continue
	fi

	status_value="$(python3 - "${ticket_file}" <<'PY'
import json
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text())
print(data.get("status", "unknown"))
PY
)"

	case "${status_value}" in
		applied-task|approved-task)
			;;
		*)
			continue
			;;
	esac

	FOUND="true"
	echo "- ${window_name} | pane0=${pane_zero_command} | ticket_status=${status_value}"

	if [[ "${APPLY}" == "true" ]]; then
		"${SCRIPT_DIR}/request-triage.sh" --config "${CONFIG_PATH}" \
			--note "repair-tasks detected shell-only worker window; manual triage required" \
			"${target}/${slug}" >/dev/null
		"${SCRIPT_DIR}/cleanup-task.sh" --config "${CONFIG_PATH}" --delete-worktree "${target}/${slug}" >/dev/null
		echo "  repaired: moved to needs-triage and cleaned window/worktree"
	else
		echo "  dry-run: would move to needs-triage and clean window/worktree"
	fi
done < <(tmux list-windows -t "${TMUX_SESSION}" -F '#W')

if [[ "${FOUND}" != "true" ]]; then
	echo "(no stuck task windows found)"
fi
