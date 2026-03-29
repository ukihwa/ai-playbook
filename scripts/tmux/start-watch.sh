#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
APPLY="false"
AUTO_APPLY="false"
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
		--auto-apply)
			AUTO_APPLY="true"
			shift
			;;
		--interval)
			INTERVAL_SECONDS="$2"
			shift 2
			;;
		*)
			die "usage: start-watch.sh --config <file> [--apply] [--auto-apply] [--interval <seconds>]"
			;;
	esac
done

need_cmd tmux
load_config "${CONFIG_PATH}"
tmux_has_session || die "tmux session '${TMUX_SESSION}' does not exist. run init-product.sh first."

WINDOW_NAME="${DISPATCH_WATCH_WINDOW:-dispatch-watch}"
WINDOW_DIR="${TRIAGE_DIR}"
TRIAGE_BRIDGE_WINDOW_NAME="${TRIAGE_BRIDGE_WINDOW_NAME:-triage-watch}"
TRIAGE_BRIDGE_DIR="${TRIAGE_DIR}"

ensure_window "${WINDOW_NAME}" "${WINDOW_DIR}"
elapsed=0
while ! tmux_window_exists "${WINDOW_NAME}"; do
	sleep 1
	((elapsed += 1))
	if (( elapsed >= 5 )); then
		die "failed to create watcher window '${WINDOW_NAME}'"
	fi
done

WATCH_PANE_TARGET="$(tmux list-panes -t "$(pane_path "${WINDOW_NAME}")" -F '#{pane_id}' | head -n 1)"
[[ -n "${WATCH_PANE_TARGET}" ]] || die "failed to resolve watcher pane for '${WINDOW_NAME}'"
tmux send-keys -t "${WATCH_PANE_TARGET}" C-c
tmux send-keys -t "${WATCH_PANE_TARGET}" "cd ${WINDOW_DIR}" C-m

WATCH_CMD="${SCRIPT_DIR}/dispatch-watch.sh --config ${CONFIG_PATH} --interval ${INTERVAL_SECONDS}"
if [[ "${APPLY}" == "true" ]]; then
	WATCH_CMD+=" --apply"
fi
if [[ "${AUTO_APPLY}" == "true" ]]; then
	WATCH_CMD+=" --auto-apply"
fi
tmux send-keys -t "${WATCH_PANE_TARGET}" "${WATCH_CMD}" C-m

TRIAGE_BRIDGE_CMD=""
TRIAGE_BRIDGE_MODE=""
if [[ "${TRIAGE_MODE:-console}" != "console" ]]; then
	ensure_window "${TRIAGE_BRIDGE_WINDOW_NAME}" "${TRIAGE_BRIDGE_DIR}"
	elapsed=0
	while ! tmux_window_exists "${TRIAGE_BRIDGE_WINDOW_NAME}"; do
		sleep 1
		((elapsed += 1))
		if (( elapsed >= 5 )); then
			die "failed to create triage bridge window '${TRIAGE_BRIDGE_WINDOW_NAME}'"
		fi
	done

	TRIAGE_BRIDGE_PANE_TARGET="$(tmux list-panes -t "$(pane_path "${TRIAGE_BRIDGE_WINDOW_NAME}")" -F '#{pane_id}' | head -n 1)"
	[[ -n "${TRIAGE_BRIDGE_PANE_TARGET}" ]] || die "failed to resolve triage bridge pane for '${TRIAGE_BRIDGE_WINDOW_NAME}'"
	tmux send-keys -t "${TRIAGE_BRIDGE_PANE_TARGET}" C-c
	tmux send-keys -t "${TRIAGE_BRIDGE_PANE_TARGET}" "cd ${TRIAGE_BRIDGE_DIR}" C-m

	TRIAGE_BRIDGE_MODE="propose"
	if [[ "${APPLY}" == "true" ]]; then
		TRIAGE_BRIDGE_MODE="apply"
	elif [[ "${AUTO_APPLY}" == "true" ]]; then
		TRIAGE_BRIDGE_MODE="auto"
	fi
	TRIAGE_BRIDGE_CMD="${SCRIPT_DIR}/triage-bridge.sh --config ${CONFIG_PATH} --interval ${INTERVAL_SECONDS} --mode ${TRIAGE_BRIDGE_MODE}"
	tmux send-keys -t "${TRIAGE_BRIDGE_PANE_TARGET}" "${TRIAGE_BRIDGE_CMD}" C-m
elif tmux_window_exists "${TRIAGE_BRIDGE_WINDOW_NAME}"; then
	tmux kill-window -t "$(pane_path "${TRIAGE_BRIDGE_WINDOW_NAME}")"
fi

print_header "dispatch watcher started"
echo "session: ${TMUX_SESSION}"
echo "window: ${WINDOW_NAME}"
echo "dir: ${WINDOW_DIR}"
echo "apply: ${APPLY}"
echo "auto_apply: ${AUTO_APPLY}"
echo "interval_seconds: ${INTERVAL_SECONDS}"
echo "command: ${WATCH_CMD}"
if [[ -n "${TRIAGE_BRIDGE_CMD}" ]]; then
	echo "triage_bridge_window: ${TRIAGE_BRIDGE_WINDOW_NAME}"
	echo "triage_bridge_mode: ${TRIAGE_BRIDGE_MODE}"
	echo "triage_bridge_command: ${TRIAGE_BRIDGE_CMD}"
else
	echo "triage_bridge: disabled (triage console mode)"
fi
