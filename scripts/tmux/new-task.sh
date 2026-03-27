#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
BRANCH_NAME=""
AGENT_NAME=""
PANE_INDEX="0"

while [[ $# -gt 0 ]]; do
	case "$1" in
		--config)
			CONFIG_PATH="$2"
			shift 2
			;;
		--branch)
			BRANCH_NAME="$2"
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

[[ $# -eq 2 ]] || die "usage: new-task.sh --config <file> [--branch <name>] <target> <slug>"

TARGET="$1"
SLUG="$2"

need_cmd tmux
need_cmd git
load_config "${CONFIG_PATH}"
tmux_has_session || die "tmux session '${TMUX_SESSION}' does not exist. run init-product.sh first."

REPO_DIR="$(resolve_target_dir "${TARGET}")"
BRANCH_NAME="${BRANCH_NAME:-$(target_branch_name "${TARGET}" "${SLUG}")}"
WORKTREE_DIR="$(create_worktree_if_missing "${TARGET}" "${SLUG}" "${REPO_DIR}" "${BRANCH_NAME}")"
WINDOW_NAME="${TARGET}/${SLUG}"

ensure_window "${WINDOW_NAME}" "${WORKTREE_DIR}"
ensure_two_panes "${WINDOW_NAME}"
tmux send-keys -t "$(pane_path "${WINDOW_NAME}").0" "cd ${WORKTREE_DIR}" C-m
tmux send-keys -t "$(pane_path "${WINDOW_NAME}").1" "cd ${REPO_DIR}" C-m

if [[ -n "${AGENT_NAME}" ]]; then
	"${SCRIPT_DIR}/bootstrap-agent.sh" --config "${CONFIG_PATH}" --agent "${AGENT_NAME}" --pane "${PANE_INDEX}" "${WINDOW_NAME}" >/dev/null
fi

print_header "task worker ready"
echo "session: ${TMUX_SESSION}"
echo "window: ${WINDOW_NAME}"
echo "repo: ${REPO_DIR}"
echo "worktree: ${WORKTREE_DIR}"
echo "branch: ${BRANCH_NAME}"
if [[ -n "${AGENT_NAME}" ]]; then
	echo "agent: ${AGENT_NAME} (pane ${PANE_INDEX})"
fi
