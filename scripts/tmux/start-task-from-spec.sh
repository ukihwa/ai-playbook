#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
AGENT_NAME=""
MODE="prompt"
PANE_INDEX="0"
TITLE=""
declare -a EXTRA_REFERENCES=()
declare -a EXTRA_REVIEW_FOCUS=()

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
		--mode)
			MODE="$2"
			shift 2
			;;
		--pane)
			PANE_INDEX="$2"
			shift 2
			;;
		--title)
			TITLE="$2"
			shift 2
			;;
		--reference)
			EXTRA_REFERENCES+=("$2")
			shift 2
			;;
		--review-focus)
			EXTRA_REVIEW_FOCUS+=("$2")
			shift 2
			;;
		*)
			break
			;;
	esac
done

[[ $# -eq 3 ]] || die "usage: start-task-from-spec.sh --config <file> [--agent <claude|codex|gemini>] [--mode shell|prompt] [--pane <index>] <target> <slug> <spec-or-issue-file>"

TARGET="$1"
SLUG="$2"
INPUT_FILE="$3"

[[ -f "${INPUT_FILE}" ]] || die "input file not found: ${INPUT_FILE}"
load_config "${CONFIG_PATH}"

extract_section() {
	local name="$1"
	awk -v section="${name}" '
		function trim(s) {
			sub(/^[[:space:]]+/, "", s)
			sub(/[[:space:]]+$/, "", s)
			return s
		}
		$0 ~ "^#+" {
			header=$0
			sub(/^#+[[:space:]]*/, "", header)
			header=trim(header)
			if (capture && header != section) exit
			if (header == section) {
				capture=1
				next
			}
		}
		capture { print }
	' "${INPUT_FILE}"
}

collect_bullets_or_text() {
	local content="$1"
	printf '%s\n' "${content}" | awk '
		{
			line=$0
			sub(/\r$/, "", line)
			if (line ~ /^[[:space:]]*[-*][[:space:]]+/) {
				sub(/^[[:space:]]*[-*][[:space:]]+/, "", line)
				print line
			} else if (line ~ /^[[:space:]]*[0-9]+\.[[:space:]]+/) {
				sub(/^[[:space:]]*[0-9]+\.[[:space:]]+/, "", line)
				print line
			} else if (line ~ /^[[:space:]]*$/) {
				next
			} else {
				print line
			}
		}
	'
}

first_nonempty_line() {
	printf '%s\n' "$1" | awk 'NF { print; exit }'
}

GOAL_SECTION="$(extract_section "Goal")"
PROBLEM_SECTION="$(extract_section "Problem")"
IN_SCOPE_SECTION="$(extract_section "In Scope")"
OUT_OF_SCOPE_SECTION="$(extract_section "Out Of Scope")"
SUCCESS_SECTION="$(extract_section "Success Criteria")"
REFERENCES_SECTION="$(extract_section "References")"
REVIEW_EXPECTATIONS_SECTION="$(extract_section "Review Expectations")"

GOAL_TEXT="$(first_nonempty_line "${GOAL_SECTION}")"
if [[ -z "${GOAL_TEXT}" ]]; then
	GOAL_TEXT="$(first_nonempty_line "${PROBLEM_SECTION}")"
fi
[[ -n "${GOAL_TEXT}" ]] || GOAL_TEXT="Review the source spec and implement the requested change."

start_args=(
	--config "${CONFIG_PATH}"
	--pane "${PANE_INDEX}"
	--mode "${MODE}"
	--goal "${GOAL_TEXT}"
)

if [[ -n "${AGENT_NAME}" ]]; then
	start_args+=(--agent "${AGENT_NAME}")
fi
if [[ -n "${TITLE}" ]]; then
	start_args+=(--title "${TITLE}")
fi

while IFS= read -r item; do
	[[ -n "${item}" ]] || continue
	start_args+=(--in-scope "${item}")
done < <(collect_bullets_or_text "${IN_SCOPE_SECTION}")

while IFS= read -r item; do
	[[ -n "${item}" ]] || continue
	start_args+=(--out-of-scope "${item}")
done < <(collect_bullets_or_text "${OUT_OF_SCOPE_SECTION}")

while IFS= read -r item; do
	[[ -n "${item}" ]] || continue
	start_args+=(--done "${item}")
done < <(collect_bullets_or_text "${SUCCESS_SECTION}")

while IFS= read -r item; do
	[[ -n "${item}" ]] || continue
	start_args+=(--reference "${item}")
done < <(collect_bullets_or_text "${REFERENCES_SECTION}")

if (( ${#EXTRA_REFERENCES[@]} )); then
	for item in "${EXTRA_REFERENCES[@]}"; do
		start_args+=(--reference "${item}")
	done
fi

while IFS= read -r item; do
	[[ -n "${item}" ]] || continue
	start_args+=(--review-focus "${item}")
done < <(collect_bullets_or_text "${REVIEW_EXPECTATIONS_SECTION}")

if (( ${#EXTRA_REVIEW_FOCUS[@]} )); then
	for item in "${EXTRA_REVIEW_FOCUS[@]}"; do
		start_args+=(--review-focus "${item}")
	done
fi

start_args+=("${TARGET}" "${SLUG}")

"${SCRIPT_DIR}/start-task.sh" "${start_args[@]}"
