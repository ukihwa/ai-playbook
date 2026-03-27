#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
AGENT_NAME=""
PANE_INDEX="0"

while [[ $# -gt 0 ]]; do
	case "$1" in
		--config)
			CONFIG_PATH="$2"
			shift 2
			;;
		--agent)
			AGENT_NAME="$2"
			shift 2
			;;
		--pane)
			PANE_INDEX="$2"
			shift 2
			;;
		*)
			break
			;;
	esac
done

[[ $# -eq 2 ]] || die "usage: review-task.sh --config <file> <target> <slug>"

TARGET="$1"
SLUG="$2"

need_cmd tmux
load_config "${CONFIG_PATH}"
tmux_has_session || die "tmux session '${TMUX_SESSION}' does not exist. run init-product.sh first."

REPO_DIR="$(resolve_target_dir "${TARGET}")"
WORKTREE_DIR="$(target_worktree_dir "${TARGET}" "${SLUG}")"
if [[ ! -d "${WORKTREE_DIR}" ]]; then
	WORKTREE_DIR="${REPO_DIR}"
fi

WINDOW_NAME="review-${TARGET}-${SLUG}"
ensure_window "${WINDOW_NAME}" "${WORKTREE_DIR}"
ensure_two_panes "${WINDOW_NAME}"
tmux send-keys -t "$(pane_path "${WINDOW_NAME}").0" "cd ${WORKTREE_DIR}" C-m
tmux send-keys -t "$(pane_path "${WINDOW_NAME}").1" "cd ${WORKTREE_DIR}" C-m

if [[ -n "${AGENT_NAME}" ]]; then
	"${SCRIPT_DIR}/bootstrap-agent.sh" --config "${CONFIG_PATH}" --agent "${AGENT_NAME}" --pane "${PANE_INDEX}" "${WINDOW_NAME}" >/dev/null
fi

print_header "review worker ready"
echo "session: ${TMUX_SESSION}"
echo "window: ${WINDOW_NAME}"
echo "dir: ${WORKTREE_DIR}"
if [[ -n "${AGENT_NAME}" ]]; then
	echo "agent: ${AGENT_NAME} (pane ${PANE_INDEX})"
fi
