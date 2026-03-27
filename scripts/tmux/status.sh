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
			die "unknown argument: $1"
			;;
	esac
done

need_cmd tmux
need_cmd git
load_config "${CONFIG_PATH}"

print_header "config"
echo "product: ${PRODUCT_NAME}"
echo "session: ${TMUX_SESSION}"
echo "work root: ${WORK_ROOT}"
echo "worktree root: ${WORKTREE_ROOT}"

print_header "targets"
while IFS= read -r key; do
	echo " - ${key#TARGET_} -> ${!key}"
done < <(compgen -A variable | grep '^TARGET_' | sort)

print_header "tmux"
if tmux_has_session; then
	tmux list-windows -t "${TMUX_SESSION}" -F ' - #W | panes=#{window_panes} | #{pane_current_path}'
else
	echo " - session not created"
fi

print_header "worktrees"
if [[ -d "${WORKTREE_ROOT}" ]]; then
	find "${WORKTREE_ROOT}" -mindepth 2 -maxdepth 2 -type d | sort | while read -r dir; do
		echo " - ${dir}"
	done
else
	echo " - none"
fi
