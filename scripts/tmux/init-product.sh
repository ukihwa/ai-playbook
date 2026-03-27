#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
ATTACH="false"

while [[ $# -gt 0 ]]; do
	case "$1" in
		--config)
			CONFIG_PATH="$2"
			shift 2
			;;
		--attach)
			ATTACH="true"
			shift
			;;
		*)
			die "unknown argument: $1"
			;;
	esac
done

need_cmd tmux
load_config "${CONFIG_PATH}"

if ! tmux_has_session; then
	tmux new-session -d -s "${TMUX_SESSION}" -n triage -c "${TRIAGE_DIR}"
fi

ensure_window "triage" "${TRIAGE_DIR}"

for spec in \
	"fe-run:${RUN_FE_DIR:-}" \
	"be-run:${RUN_BE_DIR:-}" \
	"app-run:${RUN_APP_DIR:-}" \
	"claude-fe:${CLAUDE_FE_DIR:-}" \
	"claude-be:${CLAUDE_BE_DIR:-}" \
	"claude-app:${CLAUDE_APP_DIR:-}"
do
	window_name="${spec%%:*}"
	window_dir="${spec#*:}"
	if [[ -n "${window_dir}" ]]; then
		ensure_window "${window_name}" "${window_dir}"
	fi
done

print_header "tmux session ready"
echo "session: ${TMUX_SESSION}"
tmux list-windows -t "${TMUX_SESSION}" -F ' - #W -> #{pane_current_path}'

if [[ "${ATTACH}" == "true" ]]; then
	exec tmux attach-session -t "${TMUX_SESSION}"
fi
