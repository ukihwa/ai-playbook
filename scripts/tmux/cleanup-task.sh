#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
DELETE_WORKTREE="false"
POSITIONAL=()

while [[ $# -gt 0 ]]; do
	case "$1" in
		--config)
			CONFIG_PATH="$2"
			shift 2
			;;
		--delete-worktree)
			DELETE_WORKTREE="true"
			shift
			;;
		*)
			POSITIONAL+=("$1")
			shift
			;;
	esac
done

if [[ ${#POSITIONAL[@]} -eq 1 ]]; then
	if [[ "${POSITIONAL[0]}" != */* ]]; then
		die "usage: cleanup-task.sh --config <file> [--delete-worktree] <target> <slug> | <target/slug>"
	fi
	TARGET="${POSITIONAL[0]%%/*}"
	SLUG="${POSITIONAL[0]#*/}"
elif [[ ${#POSITIONAL[@]} -eq 2 ]]; then
	TARGET="${POSITIONAL[0]}"
	SLUG="${POSITIONAL[1]}"
else
	die "usage: cleanup-task.sh --config <file> [--delete-worktree] <target> <slug> | <target/slug>"
fi

need_cmd tmux
need_cmd git
load_config "${CONFIG_PATH}"

WINDOW_NAME="${TARGET}/${SLUG}"
REVIEW_WINDOW_NAME="review-${TARGET}-${SLUG}"
WORKTREE_DIR="$(target_worktree_dir "${TARGET}" "${SLUG}")"
REPO_DIR="$(resolve_target_dir "${TARGET}")"

if tmux_has_session && tmux_window_exists "${WINDOW_NAME}"; then
	tmux kill-window -t "$(pane_path "${WINDOW_NAME}")"
fi

if tmux_has_session && tmux_window_exists "${REVIEW_WINDOW_NAME}"; then
	tmux kill-window -t "$(pane_path "${REVIEW_WINDOW_NAME}")"
fi

if [[ "${DELETE_WORKTREE}" == "true" && -d "${WORKTREE_DIR}" ]]; then
	git -C "${REPO_DIR}" worktree remove "${WORKTREE_DIR}" --force >/dev/null
fi

print_header "cleanup complete"
echo "window: ${WINDOW_NAME}"
echo "review window: ${REVIEW_WINDOW_NAME}"
echo "worktree: ${WORKTREE_DIR}"
echo "delete_worktree: ${DELETE_WORKTREE}"
