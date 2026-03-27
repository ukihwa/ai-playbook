#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
WAIT="false"

while [[ $# -gt 0 ]]; do
	case "$1" in
		--config)
			CONFIG_PATH="$2"
			shift 2
			;;
		--wait)
			WAIT="true"
			shift
			;;
		*)
			break
			;;
	esac
done

[[ $# -eq 1 ]] || die "usage: start-runtime.sh --config <file> [--wait] <fe|be|app>"

TARGET="$1"

need_cmd tmux
load_config "${CONFIG_PATH}"
tmux_has_session || die "tmux session '${TMUX_SESSION}' does not exist. run init-product.sh first."

WINDOW_NAME="${TARGET}-run"
WINDOW_DIR="$(resolve_named_var "RUN" "${TARGET}_DIR")"
WINDOW_CMD="$(resolve_named_var "RUN" "${TARGET}_CMD")"
WAIT_PORTS="$(resolve_named_var "RUN" "${TARGET}_WAIT_PORTS")"
WAIT_TIMEOUT="$(resolve_named_var "RUN" "${TARGET}_WAIT_TIMEOUT")"
WAIT_TIMEOUT="${WAIT_TIMEOUT:-45}"

[[ -n "${WINDOW_DIR}" ]] || die "run dir for '${TARGET}' is not configured"
[[ -n "${WINDOW_CMD}" ]] || die "run command for '${TARGET}' is not configured"

ensure_window "${WINDOW_NAME}" "${WINDOW_DIR}"
tmux send-keys -t "$(pane_path "${WINDOW_NAME}").0" C-c
tmux send-keys -t "$(pane_path "${WINDOW_NAME}").0" "cd ${WINDOW_DIR}" C-m
tmux send-keys -t "$(pane_path "${WINDOW_NAME}").0" "${WINDOW_CMD}" C-m

print_header "runtime started"
echo "session: ${TMUX_SESSION}"
echo "window: ${WINDOW_NAME}"
echo "dir: ${WINDOW_DIR}"
echo "command: ${WINDOW_CMD}"

if [[ "${WAIT}" == "true" && -n "${WAIT_PORTS}" ]]; then
	echo "waiting for ports: ${WAIT_PORTS}"
	if wait_for_ports "${WAIT_PORTS}" "${WAIT_TIMEOUT}"; then
		echo "ready: ${WAIT_PORTS}"
	else
		echo "warning: ports not ready within ${WAIT_TIMEOUT}s: ${WAIT_PORTS}" >&2
	fi
fi
