#!/usr/bin/env bash

set -euo pipefail

OUTPUT=""
TITLE=""
GOAL=""
DATE_STR="$(date +%F)"
declare -a IN_SCOPE=()
declare -a OUT_OF_SCOPE=()
declare -a DONE_CRITERIA=()
declare -a REFERENCES=()
declare -a REVIEW_FOCUS=()

while [[ $# -gt 0 ]]; do
	case "$1" in
		--output)
			OUTPUT="$2"
			shift 2
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
			echo "error: unknown argument: $1" >&2
			exit 1
			;;
	esac
done

[[ -n "${OUTPUT}" ]] || { echo "error: missing --output <file>" >&2; exit 1; }

mkdir -p "$(dirname "${OUTPUT}")"

if [[ -z "${TITLE}" ]]; then
	base_name="$(basename "${OUTPUT}" .md)"
	TITLE="Task Handoff: ${base_name}"
fi

print_list_section() {
	local heading="$1"
	shift
	local items=("$@")
	printf '## %s\n\n' "${heading}"
	if [[ ${#items[@]} -eq 0 ]]; then
		printf -- '- TODO\n\n'
		return
	fi
	local item
	for item in "${items[@]}"; do
		printf -- '- %s\n' "${item}"
	done
	printf '\n'
}

{
	printf -- '---\n'
	printf 'title: %s\n' "${TITLE}"
	printf 'description: 메인 triage에서 worker에게 넘기는 작업 브리프\n'
	printf 'doc_type: task\n'
	printf 'status: active\n'
	printf 'source_of_truth: true\n'
	printf 'priority: 20\n'
	printf 'when_to_use:\n'
	printf '  - 메인 triage가 worker에게 작업을 넘길 때\n'
	printf '  - task window를 새로 만들고 첫 handoff를 보낼 때\n'
	printf 'owners:\n'
	printf '  - team\n'
	printf 'scope:\n'
	printf '  - project\n'
	printf 'tags:\n'
	printf '  - task\n'
	printf '  - handoff\n'
	printf 'last_reviewed: %s\n' "${DATE_STR}"
	printf -- '---\n\n'
	printf '# Task Handoff\n\n'
	print_list_section "Goal" "${GOAL:-TODO}"
	if (( ${#IN_SCOPE[@]} )); then
		print_list_section "In Scope" "${IN_SCOPE[@]}"
	else
		print_list_section "In Scope"
	fi
	if (( ${#OUT_OF_SCOPE[@]} )); then
		print_list_section "Out Of Scope" "${OUT_OF_SCOPE[@]}"
	else
		print_list_section "Out Of Scope"
	fi
	if (( ${#DONE_CRITERIA[@]} )); then
		print_list_section "Done Criteria" "${DONE_CRITERIA[@]}"
	else
		print_list_section "Done Criteria"
	fi
	if (( ${#REFERENCES[@]} )); then
		print_list_section "Reference Docs" "${REFERENCES[@]}"
	else
		print_list_section "Reference Docs"
	fi
	if (( ${#REVIEW_FOCUS[@]} )); then
		print_list_section "Review Focus" "${REVIEW_FOCUS[@]}"
	else
		print_list_section "Review Focus"
	fi
} > "${OUTPUT}"

printf '%s\n' "${OUTPUT}"
