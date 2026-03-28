#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
APPLY="false"
INTERVAL_SECONDS="3"

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
		*)
			die "usage: start-watch.sh --config <file> [--apply] [--interval <seconds>]"
			;;
	esac
done

need_cmd tmux
load_config "${CONFIG_PATH}"
tmux_has_session || die "tmux session '${TMUX_SESSION}' does not exist. run init-product.sh first."

WINDOW_NAME="${DISPATCH_WATCH_WINDOW:-dispatch-watch}"
WINDOW_DIR="${TRIAGE_DIR}"

ensure_window "${WINDOW_NAME}" "${WINDOW_DIR}"
tmux send-keys -t "$(pane_path "${WINDOW_NAME}").0" C-c
tmux send-keys -t "$(pane_path "${WINDOW_NAME}").0" "cd ${WINDOW_DIR}" C-m

WATCH_CMD="${SCRIPT_DIR}/dispatch-watch.sh --config ${CONFIG_PATH} --interval ${INTERVAL_SECONDS}"
if [[ "${APPLY}" == "true" ]]; then
	WATCH_CMD+=" --apply"
fi
tmux send-keys -t "$(pane_path "${WINDOW_NAME}").0" "${WATCH_CMD}" C-m

print_header "dispatch watcher started"
echo "session: ${TMUX_SESSION}"
echo "window: ${WINDOW_NAME}"
echo "dir: ${WINDOW_DIR}"
echo "apply: ${APPLY}"
echo "interval_seconds: ${INTERVAL_SECONDS}"
echo "command: ${WATCH_CMD}"
