#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_PLAYBOOK_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AI_PLAYBOOK_CONFIG_DIR="${AI_PLAYBOOK_ROOT}/config"

export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"

die() {
	echo "error: $*" >&2
	exit 1
}

need_cmd() {
	command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

normalize_target_key() {
	printf '%s' "$1" | tr '[:lower:]-' '[:upper:]_'
}

load_config() {
	local config_path="${1:-}"

	if [[ -z "${config_path}" ]]; then
		die "missing config path. use --config <file>"
	fi

	if [[ ! -f "${config_path}" ]]; then
		die "config file not found: ${config_path}"
	fi

	# shellcheck disable=SC1090
	source "${config_path}"

	: "${PRODUCT_NAME:?PRODUCT_NAME is required}"
	: "${WORK_ROOT:?WORK_ROOT is required}"
	: "${WORKTREE_ROOT:?WORKTREE_ROOT is required}"

	TMUX_SESSION="${TMUX_SESSION:-${PRODUCT_NAME}}"
	DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"
	TRIAGE_DIR="${TRIAGE_DIR:-${WORK_ROOT}}"
	HANDOFF_ROOT="${HANDOFF_ROOT:-${TRIAGE_DIR}/docs/tasks/handoffs}"
	AGENT_CLAUDE_CMD="${AGENT_CLAUDE_CMD:-claude}"
	AGENT_CODEX_CMD="${AGENT_CODEX_CMD:-codex}"
	AGENT_GEMINI_CMD="${AGENT_GEMINI_CMD:-gemini}"
}

resolve_target_dir() {
	local target="$1"
	local key
	key="$(normalize_target_key "${target}")"
	local var_name="TARGET_${key}"
	local value="${!var_name:-}"

	if [[ -z "${value}" ]]; then
		die "target '${target}' is not configured in $(basename "${CONFIG_PATH}")"
	fi

	printf '%s' "${value}"
}

target_branch_name() {
	local target="$1"
	local slug="$2"
	printf 'codex/%s/%s' "${target}" "${slug}"
}

target_worktree_dir() {
	local target="$1"
	local slug="$2"
	printf '%s/%s/%s' "${WORKTREE_ROOT}" "${target}" "${slug}"
}

tmux_has_session() {
	tmux has-session -t "${TMUX_SESSION}" 2>/dev/null
}

tmux_window_exists() {
	local window_name="$1"
	tmux list-windows -t "${TMUX_SESSION}" -F '#W' 2>/dev/null | grep -Fxq "${window_name}"
}

ensure_window() {
	local window_name="$1"
	local window_dir="$2"

	if tmux_window_exists "${window_name}"; then
		return 0
	fi

	tmux new-window -d -t "${TMUX_SESSION}" -n "${window_name}" -c "${window_dir}"
}

pane_path() {
	local window_name="$1"
	printf '%s:%s' "${TMUX_SESSION}" "${window_name}"
}

tmux_pane_target() {
	local window_name="$1"
	local pane_index="${2:-0}"
	printf '%s.%s' "$(pane_path "${window_name}")" "${pane_index}"
}

ensure_two_panes() {
	local window_name="$1"
	local window_target
	window_target="$(pane_path "${window_name}")"
	local pane_count
	pane_count="$(tmux list-panes -t "${window_target}" | wc -l | tr -d ' ')"

	if [[ "${pane_count}" -lt 2 ]]; then
		tmux split-window -h -t "${window_target}"
		tmux select-layout -t "${window_target}" even-horizontal >/dev/null
	fi
}

create_worktree_if_missing() {
	local target="$1"
	local slug="$2"
	local repo_dir="$3"
	local branch_name="${4:-$(target_branch_name "${target}" "${slug}")}"
	local worktree_dir
	worktree_dir="$(target_worktree_dir "${target}" "${slug}")"

	mkdir -p "$(dirname "${worktree_dir}")"

	if [[ -d "${worktree_dir}/.git" || -f "${worktree_dir}/.git" ]]; then
		printf '%s' "${worktree_dir}"
		return 0
	fi

	if git -C "${repo_dir}" show-ref --verify --quiet "refs/heads/${branch_name}"; then
		git -C "${repo_dir}" worktree add "${worktree_dir}" "${branch_name}" >/dev/null
	else
		git -C "${repo_dir}" worktree add -b "${branch_name}" "${worktree_dir}" "${DEFAULT_BRANCH}" >/dev/null
	fi

	printf '%s' "${worktree_dir}"
}

print_header() {
	printf '== %s ==\n' "$1"
}

resolve_agent_command() {
	local agent="$1"
	case "${agent}" in
		claude)
			printf '%s' "${AGENT_CLAUDE_CMD}"
			;;
		codex)
			printf '%s' "${AGENT_CODEX_CMD}"
			;;
		gemini)
			printf '%s' "${AGENT_GEMINI_CMD}"
			;;
		*)
			die "unsupported agent '${agent}'. use claude, codex, or gemini"
			;;
	esac
}
