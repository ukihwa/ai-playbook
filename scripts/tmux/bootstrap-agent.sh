#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
PANE_INDEX="0"
AGENT=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		--config)
			CONFIG_PATH="$2"
			shift 2
			;;
		--pane)
			PANE_INDEX="$2"
			shift 2
			;;
		--agent)
			AGENT="$2"
			shift 2
			;;
		*)
			break
			;;
	esac
done

[[ $# -eq 1 ]] || die "usage: bootstrap-agent.sh --config <file> --agent <claude|codex|gemini> [--pane <index>] <window>"
[[ -n "${AGENT}" ]] || die "missing --agent <claude|codex|gemini>"

WINDOW_NAME="$1"

need_cmd tmux
load_config "${CONFIG_PATH}"
tmux_has_session || die "tmux session '${TMUX_SESSION}' does not exist. run init-product.sh first."
tmux_window_exists "${WINDOW_NAME}" || die "tmux window '${WINDOW_NAME}' does not exist in session '${TMUX_SESSION}'"
tmux list-panes -t "$(pane_path "${WINDOW_NAME}")" -F '#{pane_index}' | grep -Fxq "${PANE_INDEX}" || die "pane '${PANE_INDEX}' does not exist in window '${WINDOW_NAME}'"

AGENT_CMD="$(resolve_agent_command "${AGENT}")"
PANE_TARGET="$(tmux_pane_target "${WINDOW_NAME}" "${PANE_INDEX}")"

AGENT_DIR=""
if [[ "${WINDOW_NAME}" == "triage" ]]; then
	AGENT_DIR="${TRIAGE_AGENT_DIR:-${TRIAGE_DIR}}"
fi
if [[ -z "${AGENT_DIR}" ]]; then
	AGENT_DIR="$(tmux display-message -p -t "${PANE_TARGET}" '#{pane_current_path}' 2>/dev/null || true)"
fi

tmux respawn-pane -k -t "${PANE_TARGET}" -c "${AGENT_DIR}" "${AGENT_CMD}"

print_header "agent bootstrapped"
echo "session: ${TMUX_SESSION}"
echo "window: ${WINDOW_NAME}"
echo "pane: ${PANE_INDEX}"
echo "agent: ${AGENT}"
if [[ -n "${AGENT_DIR}" ]]; then
	echo "dir: ${AGENT_DIR}"
fi
echo "command: ${AGENT_CMD}"
