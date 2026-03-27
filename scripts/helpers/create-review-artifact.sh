#!/usr/bin/env bash

set -euo pipefail

OUTPUT=""
TITLE=""
DATE_STR="$(date +%F)"
BRANCH=""
WINDOW=""
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
		--branch)
			BRANCH="$2"
			shift 2
			;;
		--window)
			WINDOW="$2"
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
	base_name="$(basename "$(dirname "${OUTPUT}")")"
	TITLE="Review Artifact: ${base_name}"
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
	printf 'description: 리뷰 세션에서 findings와 근거를 남기는 artifact\n'
	printf 'doc_type: review\n'
	printf 'status: active\n'
	printf 'source_of_truth: false\n'
	printf 'priority: 30\n'
	printf 'tags:\n'
	printf '  - review\n'
	printf '  - artifact\n'
	printf 'last_reviewed: %s\n' "${DATE_STR}"
	printf -- '---\n\n'
	printf '# Review Artifact\n\n'
	print_list_section "Review Context" \
		"${WINDOW:+Window: ${WINDOW}}" \
		"${BRANCH:+Branch: ${BRANCH}}" \
		"Use docs/review/code-review.md, design-intent.md, and evaluation-criteria.md as the review baseline."
	print_list_section "Reference Docs" "${REFERENCES[@]}"
	print_list_section "Review Focus" "${REVIEW_FOCUS[@]}"
	print_list_section "Findings" \
		"Severity / file / line / explanation" \
		"Regression risks" \
		"Missing tests or docs"
	print_list_section "Evidence" \
		"Code paths inspected" \
		"Tests run" \
		"Official docs or web sources checked if needed"
	print_list_section "Decision" \
		"Approve / request changes / follow-up"
} > "${OUTPUT}"

printf '%s\n' "${OUTPUT}"
