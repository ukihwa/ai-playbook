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
ARTIFACT_FILE=""
SKIP_HANDOFF="false"
TITLE=""
BRANCH_NAME=""
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
		--mode)
			PROMPT_MODE="$2"
			shift 2
			;;
		--artifact-file)
			ARTIFACT_FILE="$2"
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
		--branch)
			BRANCH_NAME="$2"
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

[[ $# -eq 2 ]] || die "usage: start-review.sh --config <file> [--agent <claude|codex|gemini>] [--mode shell|prompt|exec] [--artifact-file <path>] [--branch <name>] [--reference <path>] [--review-focus <text>] <target> <slug>"

TARGET="$1"
SLUG="$2"

need_cmd git
need_cmd tmux
load_config "${CONFIG_PATH}"

WINDOW_NAME="review-${TARGET}-${SLUG}"
WORKTREE_DIR="$(target_worktree_dir "${TARGET}" "${SLUG}")"

review_task_args=(--config "${CONFIG_PATH}" --pane "${PANE_INDEX}")
if [[ -n "${AGENT_NAME}" && "${PROMPT_MODE}" != "exec" ]]; then
	review_task_args+=(--agent "${AGENT_NAME}")
fi
review_task_args+=("${TARGET}" "${SLUG}")

"${SCRIPT_DIR}/review-task.sh" "${review_task_args[@]}" >/dev/null

if [[ "${SKIP_HANDOFF}" == "false" ]]; then
	if [[ -z "${ARTIFACT_FILE}" ]]; then
		ARTIFACT_FILE="${REVIEW_ARTIFACT_ROOT}/${TARGET}-${SLUG}/review.md"
	fi

	if [[ -z "${BRANCH_NAME}" ]]; then
		BRANCH_NAME="$(target_branch_name "${TARGET}" "${SLUG}")"
	fi

	create_args=(--output "${ARTIFACT_FILE}" --branch "${BRANCH_NAME}" --window "${WINDOW_NAME}")
	if [[ -n "${TITLE}" ]]; then
		create_args+=(--title "${TITLE}")
	fi
	if (( ${#REFERENCES[@]} )); then
		for item in "${REFERENCES[@]}"; do
			create_args+=(--reference "${item}")
		done
	fi
	if (( ${#REVIEW_FOCUS[@]} )); then
		for item in "${REVIEW_FOCUS[@]}"; do
			create_args+=(--review-focus "${item}")
		done
	fi

	"${HELPER_DIR}/create-review-artifact.sh" "${create_args[@]}" >/dev/null
	if [[ -n "${AGENT_NAME}" && "${PROMPT_MODE}" != "exec" ]]; then
		if ! wait_for_agent_ready "${WINDOW_NAME}" "${PANE_INDEX}" "${AGENT_NAME}" 14; then
			current_command="$(pane_current_command "${WINDOW_NAME}" "${PANE_INDEX}")"
			"${SCRIPT_DIR}/request-triage.sh" --config "${CONFIG_PATH}" \
				--note "review worker bootstrap failed for ${AGENT_NAME}; pane command=${current_command:-unknown}" \
				"${TARGET}/${SLUG}" >/dev/null || true
			if tmux_has_session && tmux_window_exists "${WINDOW_NAME}"; then
				tmux kill-window -t "$(pane_path "${WINDOW_NAME}")" >/dev/null 2>&1 || true
			fi
			echo "warning: review worker bootstrap did not stabilize for ${WINDOW_NAME} (cmd=${current_command:-unknown})" >&2
			print_header "review blocked"
			echo "session: ${TMUX_SESSION}"
			echo "window: ${WINDOW_NAME}"
			echo "agent: ${AGENT_NAME}"
			echo "reason: review worker bootstrap failed; escalated to needs-triage"
			exit 0
		fi
		if ! wait_for_agent_prompt_ready "${WINDOW_NAME}" "${PANE_INDEX}" "${AGENT_NAME}" 20; then
			current_command="$(pane_current_command "${WINDOW_NAME}" "${PANE_INDEX}")"
			"${SCRIPT_DIR}/request-triage.sh" --config "${CONFIG_PATH}" \
				--note "review worker prompt did not become ready for ${AGENT_NAME}; pane command=${current_command:-unknown}" \
				"${TARGET}/${SLUG}" >/dev/null || true
			tmux kill-window -t "$(pane_path "${WINDOW_NAME}")" >/dev/null 2>&1 || true
			echo "warning: review worker prompt did not become ready for ${WINDOW_NAME} (cmd=${current_command:-unknown})" >&2
			print_header "review blocked"
			echo "session: ${TMUX_SESSION}"
			echo "window: ${WINDOW_NAME}"
			echo "agent: ${AGENT_NAME}"
			echo "reason: review worker prompt not ready; escalated to needs-triage"
			exit 0
		fi
	fi
	if [[ "${PROMPT_MODE}" == "exec" ]]; then
		run_agent_exec_prompt "${WINDOW_NAME}" "${PANE_INDEX}" "${AGENT_NAME}" "${WORKTREE_DIR}" "${ARTIFACT_FILE}"
	else
		"${SCRIPT_DIR}/handoff.sh" --config "${CONFIG_PATH}" --pane "${PANE_INDEX}" --mode "${PROMPT_MODE}" "${WINDOW_NAME}" "${ARTIFACT_FILE}" >/dev/null
	fi
fi

print_header "review started"
echo "session: ${TMUX_SESSION}"
echo "window: ${WINDOW_NAME}"
if [[ -n "${AGENT_NAME}" ]]; then
	echo "agent: ${AGENT_NAME}"
fi
if [[ "${SKIP_HANDOFF}" == "false" ]]; then
	echo "artifact: ${ARTIFACT_FILE}"
	echo "handoff_mode: ${PROMPT_MODE}"
fi
