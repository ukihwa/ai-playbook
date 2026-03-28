#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
INPUT_TEXT=""
INPUT_FILE=""
APPLY="false"
AGENT_NAME="codex"
MODE="prompt"
TARGET_OVERRIDE=""
SLUG_OVERRIDE=""
TITLE_OVERRIDE=""
PANE_INDEX="0"
CONFIDENCE="0.55"
JSON_OUTPUT="false"
JSON_PAYLOAD=""
STATUS_VALUE="proposed"
TICKET_FILE=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		--config)
			CONFIG_PATH="$2"
			shift 2
			;;
		--text)
			INPUT_TEXT="$2"
			shift 2
			;;
		--apply)
			APPLY="true"
			shift
			;;
		--agent)
			AGENT_NAME="$2"
			shift 2
			;;
		--mode)
			MODE="$2"
			shift 2
			;;
		--target)
			TARGET_OVERRIDE="$2"
			shift 2
			;;
		--slug)
			SLUG_OVERRIDE="$2"
			shift 2
			;;
		--title)
			TITLE_OVERRIDE="$2"
			shift 2
			;;
		--pane)
			PANE_INDEX="$2"
			shift 2
			;;
		--json)
			JSON_OUTPUT="true"
			shift
			;;
		*)
			break
			;;
	esac
done

if [[ -n "${INPUT_TEXT}" ]]; then
	[[ $# -eq 0 ]] || die "usage: dispatch.sh --config <file> [--text <request>] [--apply] [--agent <name>] [--target <name>] [--slug <slug>] [--title <text>] [--pane <index>] [<request.md>]"
elif [[ $# -eq 1 ]]; then
	INPUT_FILE="$1"
	[[ -f "${INPUT_FILE}" ]] || die "input file not found: ${INPUT_FILE}"
else
	die "usage: dispatch.sh --config <file> [--text <request>] [--apply] [--agent <name>] [--target <name>] [--slug <slug>] [--title <text>] [--pane <index>] [<request.md>]"
fi

load_config "${CONFIG_PATH}"

extract_section() {
	local file="$1"
	local name="$2"
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
	' "${file}"
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

slugify() {
	local text="$1"
	local slug
	slug="$(printf '%s' "${text}" \
		| tr '[:upper:]' '[:lower:]' \
		| sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')"
	slug="$(printf '%s' "${slug}" | cut -d'-' -f1-5)"
	if [[ -z "${slug}" ]]; then
		slug="task-$(date +%m%d-%H%M%S)"
	fi
	printf '%s' "${slug}"
}

infer_target() {
	local text
	text="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
	local default_target="${DISPATCH_DEFAULT_TARGET:-pro-web}"
	local app_target="${DISPATCH_APP_TARGET:-app}"
	local backend_target="${DISPATCH_BACKEND_TARGET:-backend}"
	local web_target="${DISPATCH_WEB_TARGET:-pro-web}"
	local ai_target="${DISPATCH_AI_TARGET:-${backend_target}}"

	if [[ "${text}" == *"ai-service"* || "${text}" == *"ai service"* || "${text}" == *"모델"* || "${text}" == *"예측"* || "${text}" == *"학습"* || "${text}" == *"inference"* || "${text}" == *"ml"* ]]; then
		printf '%s' "${ai_target}"
	elif [[ "${text}" == *"flutter"* || "${text}" == *"android"* || "${text}" == *"ios"* || "${text}" == *"모바일 앱"* || "${text}" == *"native app"* ]]; then
		printf '%s' "${app_target}"
	elif [[ "${text}" == *"backend"* || "${text}" == *"api"* || "${text}" == *"auth"* || "${text}" == *"db"* || "${text}" == *"database"* || "${text}" == *"redis"* || "${text}" == *"server"* || "${text}" == *"백엔드"* ]]; then
		printf '%s' "${backend_target}"
	elif [[ "${text}" == *"frontend"* || "${text}" == *"ui"* || "${text}" == *"ux"* || "${text}" == *"web"* || "${text}" == *"svelte"* || "${text}" == *"sveltekit"* || "${text}" == *"프론트"* || "${text}" == *"화면"* ]]; then
		printf '%s' "${web_target}"
	else
		printf '%s' "${default_target}"
	fi
}

infer_review_only() {
	local text
	text="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
	if [[ "${text}" == review:* || "${text}" == *"review only"* || "${text}" == *"리뷰만"* || "${text}" == *"검토만"* ]]; then
		return 0
	fi
	return 1
}

infer_cross_verify() {
	local text
	text="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
	[[ "${text}" == *"security"* || "${text}" == *"보안"* || "${text}" == *"auth"* || "${text}" == *"api"* || "${text}" == *"sdk"* || "${text}" == *"계약"* ]]
}

infer_confidence() {
	local text="$1"
	local score="0.55"
	if [[ -n "${INPUT_FILE}" ]]; then
		score="0.75"
	fi
	if [[ -n "${TARGET_OVERRIDE}" ]]; then
		score="0.85"
	fi
	if [[ -n "${SLUG_OVERRIDE}" ]]; then
		score="0.90"
	fi
	if infer_review_only "${text}" || infer_cross_verify "${text}"; then
		score="0.80"
	fi
	printf '%s' "${score}"
}

INPUT_SUMMARY=""
GOAL_TEXT=""
IN_SCOPE_SECTION=""
OUT_OF_SCOPE_SECTION=""
SUCCESS_SECTION=""
REFERENCES_SECTION=""
REVIEW_SECTION=""

if [[ -n "${INPUT_FILE}" ]]; then
	GOAL_TEXT="$(first_nonempty_line "$(extract_section "${INPUT_FILE}" "Goal")")"
	if [[ -z "${GOAL_TEXT}" ]]; then
		GOAL_TEXT="$(first_nonempty_line "$(extract_section "${INPUT_FILE}" "Problem")")"
	fi
	if [[ -z "${GOAL_TEXT}" ]]; then
		GOAL_TEXT="$(first_nonempty_line "$(sed -n '1,80p' "${INPUT_FILE}")")"
	fi
	IN_SCOPE_SECTION="$(extract_section "${INPUT_FILE}" "In Scope")"
	OUT_OF_SCOPE_SECTION="$(extract_section "${INPUT_FILE}" "Out Of Scope")"
	SUCCESS_SECTION="$(extract_section "${INPUT_FILE}" "Success Criteria")"
	REFERENCES_SECTION="$(extract_section "${INPUT_FILE}" "References")"
	REVIEW_SECTION="$(extract_section "${INPUT_FILE}" "Review Expectations")"
	INPUT_SUMMARY="$(sed -n '1,80p' "${INPUT_FILE}")"
else
	GOAL_TEXT="${INPUT_TEXT}"
	INPUT_SUMMARY="${INPUT_TEXT}"
fi

[[ -n "${GOAL_TEXT}" ]] || GOAL_TEXT="Review the request and prepare the implementation task."

TARGET_NAME="${TARGET_OVERRIDE:-$(infer_target "${INPUT_SUMMARY}")}"
SLUG_VALUE="${SLUG_OVERRIDE:-$(slugify "${GOAL_TEXT}")}"
TITLE_VALUE="${TITLE_OVERRIDE:-Dispatch: ${TARGET_NAME}/${SLUG_VALUE}}"

REVIEW_ONLY="false"
if infer_review_only "${INPUT_SUMMARY}"; then
	REVIEW_ONLY="true"
fi

CROSS_VERIFY="false"
if infer_cross_verify "${INPUT_SUMMARY}"; then
	CROSS_VERIFY="true"
fi
CONFIDENCE="$(infer_confidence "${INPUT_SUMMARY}")"

TRIAGE_STATUS_DOC="${TRIAGE_DIR}/docs/tasks/triage-status.md"
declare -a REFERENCES=()
declare -a IN_SCOPE=()
declare -a OUT_OF_SCOPE=()
declare -a DONE_CRITERIA=()
declare -a REVIEW_FOCUS=()
declare -a DOC_UPDATES=()

maybe_add_doc_update() {
	local path="$1"
	[[ -n "${path}" ]] || return 0
	[[ -f "${path}" ]] || return 0
	DOC_UPDATES+=("${path}")
}

if [[ -f "${TRIAGE_STATUS_DOC}" ]]; then
	REFERENCES+=("${TRIAGE_STATUS_DOC}")
	maybe_add_doc_update "${TRIAGE_STATUS_DOC}"
fi
if [[ -n "${INPUT_FILE}" ]]; then
	REFERENCES+=("${INPUT_FILE}")
fi

while IFS= read -r item; do
	[[ -n "${item}" ]] || continue
	IN_SCOPE+=("${item}")
done < <(collect_bullets_or_text "${IN_SCOPE_SECTION}")

while IFS= read -r item; do
	[[ -n "${item}" ]] || continue
	OUT_OF_SCOPE+=("${item}")
done < <(collect_bullets_or_text "${OUT_OF_SCOPE_SECTION}")

while IFS= read -r item; do
	[[ -n "${item}" ]] || continue
	DONE_CRITERIA+=("${item}")
done < <(collect_bullets_or_text "${SUCCESS_SECTION}")

while IFS= read -r item; do
	[[ -n "${item}" ]] || continue
	REFERENCES+=("${item}")
done < <(collect_bullets_or_text "${REFERENCES_SECTION}")

while IFS= read -r item; do
	[[ -n "${item}" ]] || continue
	REVIEW_FOCUS+=("${item}")
done < <(collect_bullets_or_text "${REVIEW_SECTION}")

if (( ${#DONE_CRITERIA[@]} == 0 )); then
	DONE_CRITERIA+=("Task implementation is completed and validated in the target workspace.")
	DONE_CRITERIA+=("Relevant docs are updated according to doc-update-policy.")
fi

if (( ${#REVIEW_FOCUS[@]} == 0 )); then
	REVIEW_FOCUS+=("Check regression risks and missing evidence.")
fi
if [[ "${CROSS_VERIFY}" == "true" ]]; then
	REVIEW_FOCUS+=("Consider cross-verify because this request mentions high-risk external facts or contracts.")
fi

if [[ "${REVIEW_ONLY}" != "true" ]]; then
	maybe_add_doc_update "${DISPATCH_DOC_UPDATE_DESIGN_INTENT:-${TRIAGE_DIR}/docs/review/design-intent.md}"
	maybe_add_doc_update "${DISPATCH_DOC_UPDATE_EVALUATION_CRITERIA:-${TRIAGE_DIR}/docs/review/evaluation-criteria.md}"
fi

case "${TARGET_NAME}" in
	pro-web|frontend)
		maybe_add_doc_update "${DISPATCH_DOC_UPDATE_PRO_WEB:-${TRIAGE_DIR}/docs/architecture/overview.md}"
		maybe_add_doc_update "${DISPATCH_DOC_UPDATE_FRONTEND:-}"
		;;
	backend)
		maybe_add_doc_update "${DISPATCH_DOC_UPDATE_BACKEND:-${TRIAGE_DIR}/docs/reference/backend.md}"
		;;
	app)
		maybe_add_doc_update "${DISPATCH_DOC_UPDATE_APP:-${TRIAGE_DIR}/docs/reference/pro-web.md}"
		;;
	ai-service)
		maybe_add_doc_update "${DISPATCH_DOC_UPDATE_AI_SERVICE:-}"
		;;
esac

print_list() {
	local heading="$1"
	local array_name="$2"
	local count
	eval "count=\${#${array_name}[@]}"
	echo "${heading}:"
	if (( count == 0 )); then
		echo "  - (none)"
		return
	fi
	local item=""
	eval "for item in \"\${${array_name}[@]}\"; do echo \"  - \${item}\"; done"
}

json_escape() {
	printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
}

print_json_array() {
	local array_name="$1"
	local count
	eval "count=\${#${array_name}[@]}"
	if (( count == 0 )); then
		printf '[]'
		return
	fi
	eval "printf '%s\n' \"\${${array_name}[@]}\"" | python3 -c 'import json,sys; print(json.dumps([line.rstrip("\n") for line in sys.stdin if line.rstrip("\n")]), end="")'
}

build_json_payload() {
	printf '{'
	printf '"project":%s,' "$(json_escape "${PRODUCT_NAME}")"
	printf '"target":%s,' "$(json_escape "${TARGET_NAME}")"
	printf '"slug":%s,' "$(json_escape "${SLUG_VALUE}")"
	printf '"title":%s,' "$(json_escape "${TITLE_VALUE}")"
	printf '"status":%s,' "$(json_escape "${STATUS_VALUE}")"
	printf '"apply":%s,' "${APPLY}"
	printf '"mode":%s,' "$(json_escape "${MODE}")"
	printf '"agent":%s,' "$(json_escape "${AGENT_NAME}")"
	printf '"review_only":%s,' "${REVIEW_ONLY}"
	printf '"cross_verify_candidate":%s,' "${CROSS_VERIFY}"
	printf '"confidence":%s,' "$(json_escape "${CONFIDENCE}")"
	printf '"goal":%s,' "$(json_escape "${GOAL_TEXT}")"
	printf '"in_scope":'; print_json_array IN_SCOPE; printf ','
	printf '"out_of_scope":'; print_json_array OUT_OF_SCOPE; printf ','
	printf '"done_criteria":'; print_json_array DONE_CRITERIA; printf ','
	printf '"references":'; print_json_array REFERENCES; printf ','
	printf '"review_focus":'; print_json_array REVIEW_FOCUS; printf ','
	printf '"doc_updates":'; print_json_array DOC_UPDATES
	printf '}'
}

mkdir -p "${DISPATCH_TICKET_ROOT}"
TICKET_FILE="${DISPATCH_TICKET_ROOT}/${TARGET_NAME}-${SLUG_VALUE}.json"

write_ticket() {
	JSON_PAYLOAD="$(build_json_payload)"
	printf '%s\n' "${JSON_PAYLOAD}" > "${TICKET_FILE}"
}

write_ticket

if [[ "${JSON_OUTPUT}" == "true" ]]; then
	printf '%s\n' "${JSON_PAYLOAD}"
	if [[ "${APPLY}" != "true" ]]; then
		exit 0
	fi
fi

print_header "dispatch proposal"
echo "project: ${PRODUCT_NAME}"
echo "target: ${TARGET_NAME}"
echo "slug: ${SLUG_VALUE}"
echo "title: ${TITLE_VALUE}"
echo "apply: ${APPLY}"
echo "mode: ${MODE}"
echo "agent: ${AGENT_NAME}"
echo "review_only: ${REVIEW_ONLY}"
echo "cross_verify_candidate: ${CROSS_VERIFY}"
echo "confidence: ${CONFIDENCE}"
echo "ticket: ${TICKET_FILE}"
echo "goal: ${GOAL_TEXT}"
print_list "in_scope" IN_SCOPE
print_list "out_of_scope" OUT_OF_SCOPE
print_list "done_criteria" DONE_CRITERIA
print_list "references" REFERENCES
print_list "review_focus" REVIEW_FOCUS
print_list "doc_updates" DOC_UPDATES

if [[ "${APPLY}" != "true" ]]; then
	exit 0
fi

if [[ "${REVIEW_ONLY}" == "true" ]]; then
	STATUS_VALUE="applied-review"
	write_ticket
	review_args=(--config "${CONFIG_PATH}" --pane "${PANE_INDEX}" --mode "${MODE}" --agent "${AGENT_NAME}")
	local_item=""
	for local_item in "${REFERENCES[@]}"; do
		review_args+=(--reference "${local_item}")
	done
	for local_item in "${REVIEW_FOCUS[@]}"; do
		review_args+=(--review-focus "${local_item}")
	done
	review_args+=("${TARGET_NAME}" "${SLUG_VALUE}")
	exec "${SCRIPT_DIR}/start-review.sh" "${review_args[@]}"
fi

STATUS_VALUE="applied-task"
write_ticket
task_args=(--config "${CONFIG_PATH}" --pane "${PANE_INDEX}" --mode "${MODE}" --agent "${AGENT_NAME}" --title "${TITLE_VALUE}" --goal "${GOAL_TEXT}")
local_item=""
if (( ${#IN_SCOPE[@]} )); then
	for local_item in "${IN_SCOPE[@]}"; do
		task_args+=(--in-scope "${local_item}")
	done
fi
if (( ${#OUT_OF_SCOPE[@]} )); then
	for local_item in "${OUT_OF_SCOPE[@]}"; do
		task_args+=(--out-of-scope "${local_item}")
	done
fi
if (( ${#DONE_CRITERIA[@]} )); then
	for local_item in "${DONE_CRITERIA[@]}"; do
		task_args+=(--done "${local_item}")
	done
fi
if (( ${#REFERENCES[@]} )); then
	for local_item in "${REFERENCES[@]}"; do
		task_args+=(--reference "${local_item}")
	done
fi
if (( ${#REVIEW_FOCUS[@]} )); then
	for local_item in "${REVIEW_FOCUS[@]}"; do
		task_args+=(--review-focus "${local_item}")
	done
fi
task_args+=("${TARGET_NAME}" "${SLUG_VALUE}")
exec "${SCRIPT_DIR}/start-task.sh" "${task_args[@]}"
