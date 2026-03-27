#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
PANE_INDEX="0"
PRINT_ONLY="false"
MODE="shell"
INTERRUPT=""

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
		--mode)
			MODE="$2"
			shift 2
			;;
		--interrupt)
			INTERRUPT="true"
			shift
			;;
		--no-interrupt)
			INTERRUPT="false"
			shift
			;;
		--print-only)
			PRINT_ONLY="true"
			shift
			;;
		*)
			break
			;;
	esac
done

[[ $# -eq 2 ]] || die "usage: handoff.sh --config <file> [--pane <index>] [--mode shell|prompt] [--interrupt|--no-interrupt] [--print-only] <window> <ticket-file>"

WINDOW_NAME="$1"
TICKET_FILE="$2"

need_cmd tmux
load_config "${CONFIG_PATH}"
tmux_has_session || die "tmux session '${TMUX_SESSION}' does not exist. run init-product.sh first."
tmux_window_exists "${WINDOW_NAME}" || die "tmux window '${WINDOW_NAME}' does not exist in session '${TMUX_SESSION}'"
[[ -f "${TICKET_FILE}" ]] || die "ticket file not found: ${TICKET_FILE}"
tmux list-panes -t "$(pane_path "${WINDOW_NAME}")" -F '#{pane_index}' | grep -Fxq "${PANE_INDEX}" || die "pane '${PANE_INDEX}' does not exist in window '${WINDOW_NAME}'"
[[ "${MODE}" == "shell" || "${MODE}" == "prompt" ]] || die "mode must be 'shell' or 'prompt'"

if [[ -z "${INTERRUPT}" ]]; then
	if [[ "${MODE}" == "shell" ]]; then
		INTERRUPT="true"
	else
		INTERRUPT="false"
	fi
fi

PANE_TARGET="$(tmux_pane_target "${WINDOW_NAME}" "${PANE_INDEX}")"
MESSAGE_FILE="$(mktemp)"

if [[ "${MODE}" == "shell" ]]; then
	{
		printf "cat <<'__AI_PLAYBOOK_HANDOFF__'\n"
		printf '# Handoff\n'
		printf '\n'
		printf 'Read the task brief below and acknowledge the goal, scope, and done criteria before editing code.\n'
		printf '\n'
		printf 'Source file: %s\n' "${TICKET_FILE}"
		printf '\n'
		cat "${TICKET_FILE}"
		printf '\n__AI_PLAYBOOK_HANDOFF__\n'
	} > "${MESSAGE_FILE}"
else
	{
		printf '# Handoff\n'
		printf '\n'
		printf 'Read the task brief below and acknowledge the goal, scope, and done criteria before editing code.\n'
		printf '\n'
		printf 'Source file: %s\n' "${TICKET_FILE}"
		printf '\n'
		cat "${TICKET_FILE}"
		printf '\n'
	} > "${MESSAGE_FILE}"
fi

if [[ "${PRINT_ONLY}" == "true" ]]; then
	cat "${MESSAGE_FILE}"
	rm -f "${MESSAGE_FILE}"
	exit 0
fi

tmux load-buffer -b ai-playbook-handoff "${MESSAGE_FILE}"
if [[ "${INTERRUPT}" == "true" ]]; then
	tmux send-keys -t "${PANE_TARGET}" C-c
fi
tmux paste-buffer -t "${PANE_TARGET}" -b ai-playbook-handoff
tmux send-keys -t "${PANE_TARGET}" C-m
tmux delete-buffer -b ai-playbook-handoff >/dev/null 2>&1 || true
rm -f "${MESSAGE_FILE}"

print_header "handoff sent"
echo "session: ${TMUX_SESSION}"
echo "window: ${WINDOW_NAME}"
echo "pane: ${PANE_INDEX}"
echo "mode: ${MODE}"
echo "interrupt: ${INTERRUPT}"
echo "ticket: ${TICKET_FILE}"
