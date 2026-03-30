#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER_DIR="$(cd "${SCRIPT_DIR}/../helpers" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
AGENT_NAME=""
PANE_INDEX="0"
PROMPT_MODE="shell"
HANDOFF_FILE=""
SKIP_HANDOFF="false"
GOAL=""
TITLE=""
declare -a IN_SCOPE=()
declare -a OUT_OF_SCOPE=()
declare -a DONE_CRITERIA=()
declare -a REFERENCES=()
declare -a REVIEW_FOCUS=()

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
		--handoff-file)
			HANDOFF_FILE="$2"
			shift 2
			;;
		--mode)
			PROMPT_MODE="$2"
			shift 2
			;;
		--skip-handoff)
			SKIP_HANDOFF="true"
			shift
			;;
		--title)
			TITLE="$2"
			shift 2
			;;
		--goal)
			GOAL="$2"
			shift 2
			;;
		--in-scope)
			IN_SCOPE+=("$2")
			shift 2
			;;
		--out-of-scope)
			OUT_OF_SCOPE+=("$2")
			shift 2
			;;
		--done)
			DONE_CRITERIA+=("$2")
			shift 2
			;;
		--reference)
			REFERENCES+=("$2")
			shift 2
			;;
		--review-focus)
			REVIEW_FOCUS+=("$2")
			shift 2
			;;
		*)
			break
			;;
	esac
done

[[ $# -eq 2 ]] || die "usage: start-task.sh --config <file> [--agent <claude|codex|gemini>] [--mode shell|prompt|exec] [--handoff-file <path>] [--goal <text>] [--in-scope <text>] [--out-of-scope <text>] [--done <text>] [--reference <path>] [--review-focus <text>] <target> <slug>"

TARGET="$1"
SLUG="$2"

need_cmd git
need_cmd tmux
load_config "${CONFIG_PATH}"

WINDOW_NAME="${TARGET}/${SLUG}"
WORKTREE_DIR="$(target_worktree_dir "${TARGET}" "${SLUG}")"

new_task_args=(--config "${CONFIG_PATH}" --pane "${PANE_INDEX}")
if [[ -n "${AGENT_NAME}" && "${PROMPT_MODE}" != "exec" ]]; then
	new_task_args+=(--agent "${AGENT_NAME}")
fi
new_task_args+=("${TARGET}" "${SLUG}")

"${SCRIPT_DIR}/new-task.sh" "${new_task_args[@]}" >/dev/null

if [[ "${SKIP_HANDOFF}" == "false" ]]; then
	if [[ -z "${HANDOFF_FILE}" ]]; then
		HANDOFF_FILE="${HANDOFF_ROOT}/${TARGET}-${SLUG}.md"
	fi

	create_args=(--output "${HANDOFF_FILE}")
	if [[ -n "${TITLE}" ]]; then
		create_args+=(--title "${TITLE}")
	fi
	if [[ -n "${GOAL}" ]]; then
		create_args+=(--goal "${GOAL}")
	fi
	local_item=""
	if (( ${#IN_SCOPE[@]} )); then
		for local_item in "${IN_SCOPE[@]}"; do
			create_args+=(--in-scope "${local_item}")
		done
	fi
	if (( ${#OUT_OF_SCOPE[@]} )); then
		for local_item in "${OUT_OF_SCOPE[@]}"; do
			create_args+=(--out-of-scope "${local_item}")
		done
	fi
	if (( ${#DONE_CRITERIA[@]} )); then
		for local_item in "${DONE_CRITERIA[@]}"; do
			create_args+=(--done "${local_item}")
		done
	fi
	if (( ${#REFERENCES[@]} )); then
		for local_item in "${REFERENCES[@]}"; do
			create_args+=(--reference "${local_item}")
		done
	fi
	if (( ${#REVIEW_FOCUS[@]} )); then
		for local_item in "${REVIEW_FOCUS[@]}"; do
			create_args+=(--review-focus "${local_item}")
		done
	fi

	"${HELPER_DIR}/create-handoff.sh" "${create_args[@]}" >/dev/null
	if [[ -n "${AGENT_NAME}" && "${PROMPT_MODE}" != "exec" ]]; then
		if ! wait_for_agent_ready "${WINDOW_NAME}" "${PANE_INDEX}" "${AGENT_NAME}" 14; then
			current_command="$(pane_current_command "${WINDOW_NAME}" "${PANE_INDEX}")"
			"${SCRIPT_DIR}/request-triage.sh" --config "${CONFIG_PATH}" \
				--note "worker bootstrap failed for ${AGENT_NAME}; pane command=${current_command:-unknown}" \
				"${TARGET}/${SLUG}" >/dev/null || true
			"${SCRIPT_DIR}/cleanup-task.sh" --config "${CONFIG_PATH}" --delete-worktree "${TARGET}/${SLUG}" >/dev/null 2>&1 || true
			echo "warning: worker bootstrap did not stabilize for ${WINDOW_NAME} (cmd=${current_command:-unknown})" >&2
			print_header "task blocked"
			echo "session: ${TMUX_SESSION}"
			echo "window: ${WINDOW_NAME}"
			echo "agent: ${AGENT_NAME}"
			echo "reason: worker bootstrap failed; escalated to needs-triage"
			exit 0
		fi
		if ! wait_for_agent_prompt_ready "${WINDOW_NAME}" "${PANE_INDEX}" "${AGENT_NAME}" 20; then
			current_command="$(pane_current_command "${WINDOW_NAME}" "${PANE_INDEX}")"
			"${SCRIPT_DIR}/request-triage.sh" --config "${CONFIG_PATH}" \
				--note "worker prompt did not become ready for ${AGENT_NAME}; pane command=${current_command:-unknown}" \
				"${TARGET}/${SLUG}" >/dev/null || true
			"${SCRIPT_DIR}/cleanup-task.sh" --config "${CONFIG_PATH}" --delete-worktree "${TARGET}/${SLUG}" >/dev/null 2>&1 || true
			echo "warning: worker prompt did not become ready for ${WINDOW_NAME} (cmd=${current_command:-unknown})" >&2
			print_header "task blocked"
			echo "session: ${TMUX_SESSION}"
			echo "window: ${WINDOW_NAME}"
			echo "agent: ${AGENT_NAME}"
			echo "reason: worker prompt not ready; escalated to needs-triage"
			exit 0
		fi
	fi
	if [[ "${PROMPT_MODE}" == "exec" ]]; then
		run_agent_exec_prompt "${WINDOW_NAME}" "${PANE_INDEX}" "${AGENT_NAME}" "${WORKTREE_DIR}" "${HANDOFF_FILE}"
	else
		"${SCRIPT_DIR}/handoff.sh" --config "${CONFIG_PATH}" --pane "${PANE_INDEX}" --mode "${PROMPT_MODE}" "${WINDOW_NAME}" "${HANDOFF_FILE}" >/dev/null
	fi
fi

print_header "task started"
echo "session: ${TMUX_SESSION}"
echo "window: ${WINDOW_NAME}"
if [[ -n "${AGENT_NAME}" ]]; then
	echo "agent: ${AGENT_NAME}"
fi
if [[ "${SKIP_HANDOFF}" == "false" ]]; then
	echo "handoff: ${HANDOFF_FILE}"
	echo "handoff_mode: ${PROMPT_MODE}"
fi
