#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		--config)
			CONFIG_PATH="$2"
			shift 2
			;;
		*)
			die "usage: stop-watch.sh --config <file>"
			;;
	esac
done

need_cmd tmux
load_config "${CONFIG_PATH}"
tmux_has_session || die "tmux session '${TMUX_SESSION}' does not exist."

WINDOW_NAME="${DISPATCH_WATCH_WINDOW:-dispatch-watch}"

if tmux_window_exists "${WINDOW_NAME}"; then
	tmux send-keys -t "$(pane_path "${WINDOW_NAME}").0" C-c
	print_header "dispatch watcher stopped"
	echo "session: ${TMUX_SESSION}"
	echo "window: ${WINDOW_NAME}"
else
	print_header "dispatch watcher already stopped"
	echo "session: ${TMUX_SESSION}"
	echo "window: ${WINDOW_NAME}"
fi
