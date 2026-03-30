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
	REVIEW_ARTIFACT_ROOT="${REVIEW_ARTIFACT_ROOT:-${TRIAGE_DIR}/.review-artifacts}"
	DISPATCH_TICKET_ROOT="${DISPATCH_TICKET_ROOT:-${TRIAGE_DIR}/.dispatch-tickets}"
	DISPATCH_ARCHIVE_ROOT="${DISPATCH_ARCHIVE_ROOT:-${TRIAGE_DIR}/.dispatch-tickets-archive}"
	DISPATCH_INBOX_ROOT="${DISPATCH_INBOX_ROOT:-${TRIAGE_DIR}/docs/tasks/dispatch-inbox}"
	INTAKE_AUDIT_ROOT="${INTAKE_AUDIT_ROOT:-${TRIAGE_DIR}/.intake-audit}"
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

resolve_named_var() {
	local prefix="$1"
	local suffix="$2"
	local key
	key="$(normalize_target_key "${suffix}")"
	local var_name="${prefix}_${key}"
	printf '%s' "${!var_name:-}"
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

tmux_window_id() {
	local window_name="$1"
	tmux list-windows -t "${TMUX_SESSION}" -F '#{window_id}\t#{window_name}' 2>/dev/null \
		| awk -F '\t' -v name="${window_name}" '$2 == name { print $1; exit }'
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
	local window_id=""
	window_id="$(tmux_window_id "${window_name}" || true)"
	if [[ -n "${window_id}" ]]; then
		printf '%s' "${window_id}"
	else
		printf '%s:%s' "${TMUX_SESSION}" "${window_name}"
	fi
}

tmux_pane_target() {
	local window_name="$1"
	local pane_index="${2:-0}"
	printf '%s.%s' "$(pane_path "${window_name}")" "${pane_index}"
}

wait_for_pane_command() {
	local window_name="$1"
	local pane_index="$2"
	local expected="$3"
	local timeout_seconds="${4:-8}"
	local pane_target
	pane_target="$(tmux_pane_target "${window_name}" "${pane_index}")"
	local current=""
	local elapsed=0

	while (( elapsed < timeout_seconds )); do
		current="$(tmux display-message -p -t "${pane_target}" '#{pane_current_command}' 2>/dev/null || true)"
		if [[ "${current}" == "${expected}" ]]; then
			return 0
		fi
		sleep 1
		((elapsed += 1))
	done

	return 1
}

pane_current_command() {
	local window_name="$1"
	local pane_index="${2:-0}"
	local pane_target
	pane_target="$(tmux_pane_target "${window_name}" "${pane_index}")"
	tmux display-message -p -t "${pane_target}" '#{pane_current_command}' 2>/dev/null || true
}

pane_contains_text() {
	local window_name="$1"
	local pane_index="$2"
	local needle="$3"
	local start_line="${4:--120}"
	local pane_target
	pane_target="$(tmux_pane_target "${window_name}" "${pane_index}")"
	tmux capture-pane -p -t "${pane_target}" -S "${start_line}" 2>/dev/null | grep -Fq "${needle}"
}

maybe_accept_codex_trust() {
	local window_name="$1"
	local pane_index="${2:-0}"
	local timeout_seconds="${3:-10}"
	local pane_target
	pane_target="$(tmux_pane_target "${window_name}" "${pane_index}")"
	local elapsed=0
	local accepted="false"

	while (( elapsed < timeout_seconds )); do
		if pane_contains_text "${window_name}" "${pane_index}" "Do you trust the contents of this directory?"; then
			tmux send-keys -t "${pane_target}" "1" C-m
			accepted="true"
			sleep 1
		fi

		if [[ "${accepted}" == "true" ]] && ! pane_contains_text "${window_name}" "${pane_index}" "Do you trust the contents of this directory?"; then
			return 0
		fi

		sleep 1
		((elapsed += 1))
	done

	[[ "${accepted}" == "true" ]]
}

wait_for_agent_ready() {
	local window_name="$1"
	local pane_index="$2"
	local agent_name="$3"
	local timeout_seconds="${4:-12}"
	local elapsed=0
	local current=""

	while (( elapsed < timeout_seconds )); do
		if [[ "${agent_name}" == "codex" ]]; then
			maybe_accept_codex_trust "${window_name}" "${pane_index}" 1 || true
		fi

		current="$(pane_current_command "${window_name}" "${pane_index}")"
		if [[ "${current}" == "${agent_name}" ]]; then
			return 0
		fi

		sleep 1
		((elapsed += 1))
	done

	return 1
}

wait_for_ports() {
	local ports_csv="$1"
	local timeout_seconds="${2:-45}"

	[[ -n "${ports_csv}" ]] || return 0

	IFS=',' read -r -a ports <<< "${ports_csv}"
	local elapsed=0
	local all_ready=""
	local port=""

	while (( elapsed < timeout_seconds )); do
		all_ready="true"
		for port in "${ports[@]}"; do
			port="${port//[[:space:]]/}"
			[[ -n "${port}" ]] || continue
			if ! lsof -nP -iTCP:"${port}" -sTCP:LISTEN >/dev/null 2>&1; then
				all_ready="false"
				break
			fi
		done
		if [[ "${all_ready}" == "true" ]]; then
			return 0
		fi
		sleep 1
		((elapsed += 1))
	done

	return 1
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

resolve_ticket_file() {
	local input="$1"
	local roots=("${DISPATCH_TICKET_ROOT}")
	if [[ -n "${DISPATCH_ARCHIVE_ROOT:-}" ]]; then
		roots+=("${DISPATCH_ARCHIVE_ROOT}")
	fi

	if [[ -f "${input}" ]]; then
		printf '%s' "${input}"
		return
	fi

	local root=""
	local normalized="${input//\//-}"
	for root in "${roots[@]}"; do
		[[ -d "${root}" ]] || continue

		if [[ -f "${root}/${input}.json" ]]; then
			printf '%s' "${root}/${input}.json"
			return
		fi

		if [[ -f "${root}/${normalized}.json" ]]; then
			printf '%s' "${root}/${normalized}.json"
			return
		fi

		local matches=()
		local path=""
		local base=""
		while IFS= read -r path; do
			[[ -n "${path}" ]] || continue
			base="$(basename "${path}" .json)"
			if [[ "${base}" == *"${normalized}"* ]]; then
				matches+=("${path}")
			fi
		done < <(find "${root}" -maxdepth 1 -type f -name '*.json' | sort)

		if (( ${#matches[@]} == 1 )); then
			printf '%s' "${matches[0]}"
			return
		fi
		if (( ${#matches[@]} > 1 )); then
			printf 'error: multiple tickets match "%s"\n' "${input}" >&2
			printf '  - %s\n' "${matches[@]}" >&2
			exit 1
		fi
	done

	die "ticket not found: ${input}"
}
