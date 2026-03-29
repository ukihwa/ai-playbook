#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
TEXT_VALUE=""
FILE_VALUE=""
MODE_VALUE="auto"
INTERVAL_SECONDS="3"
FORCE_VALUE="false"
JSON_OUTPUT="false"

usage() {
	cat <<'EOF'
usage: intake.sh --config <file> [--text <request> | --file <path>] [--mode auto|apply|propose] [--interval <seconds>] [--force] [--json]

Creates a dispatch inbox item and immediately processes it once.
- auto: auto-apply if policy allows, otherwise escalate to needs-triage
- apply: always apply immediately
- propose: proposal only
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--config)
			CONFIG_PATH="$2"
			shift 2
			;;
		--text)
			TEXT_VALUE="$2"
			shift 2
			;;
		--file)
			FILE_VALUE="$2"
			shift 2
			;;
		--mode)
			MODE_VALUE="$2"
			shift 2
			;;
		--interval)
			INTERVAL_SECONDS="$2"
			shift 2
			;;
		--force)
			FORCE_VALUE="true"
			shift
			;;
		--json)
			JSON_OUTPUT="true"
			shift
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			die "unknown argument: $1"
			;;
	esac
done

[[ -n "${CONFIG_PATH}" ]] || die "missing --config"
if [[ -n "${TEXT_VALUE}" && -n "${FILE_VALUE}" ]]; then
	die "use either --text or --file"
fi
if [[ -z "${TEXT_VALUE}" && -z "${FILE_VALUE}" ]]; then
	die "missing --text or --file"
fi

case "${MODE_VALUE}" in
	auto|apply|propose)
		;;
	*)
		die "unsupported --mode '${MODE_VALUE}'"
		;;
esac

load_config "${CONFIG_PATH}"
mkdir -p "${INTAKE_AUDIT_ROOT}"

RAW_INPUT=""
if [[ -n "${TEXT_VALUE}" ]]; then
	RAW_INPUT="${TEXT_VALUE}"
else
	RAW_INPUT="$(sed -n '1,120p' "${FILE_VALUE}")"
fi

CLASSIFICATION="$(python3 - "${RAW_INPUT}" "${FORCE_VALUE}" "${JSON_OUTPUT}" <<'PY'
import json
import re
import sys

text = sys.argv[1].strip()
force = sys.argv[2].lower() == "true"
json_output = sys.argv[3].lower() == "true"
lowered = text.lower()

greeting_patterns = [
    r"^(안녕|안녕하세요|반가워|좋은 아침|좋은 저녁)",
    r"^(hi|hello|hey)\b",
]
thanks_patterns = [
    r"^(고마워|감사|감사합니다|thanks|thank you)\b",
]
action_patterns = [
    r"(해줘|해주세요|부탁해|부탁합니다)",
    r"(구현|수정|정리|개선|추가|삭제|제거|설계|작성|검토|리뷰|분석|조사|연결|세팅|설정|자동화|테스트|디버그|고쳐)",
    r"\b(implement|fix|update|refactor|review|check|investigate|analyze|create|set up|setup|wire|write|test|debug|clean up)\b",
]
question_patterns = [
    r"(어떻게|왜|뭐가|무엇이|가능할까|가능한가|맞나요|맞는지)",
    r"\b(how|why|what|should|could|can)\b",
]

classification = "actionable"
reason = "explicit-action"

if force:
    classification = "actionable"
    reason = "forced"
elif not text:
    classification = "ignore"
    reason = "empty"
elif any(re.search(p, lowered) for p in greeting_patterns):
    classification = "ignore"
    reason = "greeting"
elif any(re.search(p, lowered) for p in thanks_patterns):
    classification = "ignore"
    reason = "thanks"
elif any(re.search(p, lowered) for p in action_patterns):
    classification = "actionable"
    reason = "explicit-action"
elif len(text) < 20 and text.endswith("?"):
    classification = "ignore"
    reason = "short-question"
elif any(re.search(p, lowered) for p in question_patterns):
    classification = "ignore"
    reason = "question-without-action"
else:
    classification = "actionable"
    reason = "default-action"

payload = {"classification": classification, "reason": reason}
if json_output:
    print(json.dumps(payload, ensure_ascii=False))
else:
    print(f"{classification}:{reason}")
PY
)"

if [[ "${JSON_OUTPUT}" == "true" ]]; then
	CLASSIFICATION_VALUE="$(python3 - "${CLASSIFICATION}" <<'PY'
import json, sys
print(json.loads(sys.argv[1])["classification"])
PY
)"
	REASON_VALUE="$(python3 - "${CLASSIFICATION}" <<'PY'
import json, sys
print(json.loads(sys.argv[1])["reason"])
PY
)"
else
	CLASSIFICATION_VALUE="${CLASSIFICATION%%:*}"
	REASON_VALUE="${CLASSIFICATION#*:}"
fi

if [[ "${CLASSIFICATION_VALUE}" != "actionable" ]]; then
	AUDIT_FILE="${INTAKE_AUDIT_ROOT}/$(date +%Y%m%d-%H%M%S)-ignore.json"
	python3 - "${AUDIT_FILE}" "${PRODUCT_NAME}" "${MODE_VALUE}" "${REASON_VALUE}" "${RAW_INPUT}" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

path = Path(sys.argv[1])
payload = {
    "project": sys.argv[2],
    "classification": "ignore",
    "mode": sys.argv[3],
    "reason": sys.argv[4],
    "request": sys.argv[5],
    "created_at": datetime.now(timezone.utc).isoformat(),
}
path.write_text(json.dumps(payload, ensure_ascii=False))
PY
	if [[ "${JSON_OUTPUT}" == "true" ]]; then
		printf '{"classification":"ignore","reason":"%s"}\n' "${REASON_VALUE}"
	else
		printf 'classification: ignore\n'
		printf 'reason: %s\n' "${REASON_VALUE}"
	fi
	exit 0
fi

CREATE_CMD=("${ROOT_DIR}/scripts/helpers/create-dispatch-request.sh" --config "${CONFIG_PATH}")
if [[ -n "${TEXT_VALUE}" ]]; then
	CREATE_CMD+=(--text "${TEXT_VALUE}")
else
	[[ -f "${FILE_VALUE}" ]] || die "input file not found: ${FILE_VALUE}"
	CREATE_CMD+=("${FILE_VALUE}")
fi

REQUEST_FILE="$("${CREATE_CMD[@]}")"
AUDIT_FILE="${INTAKE_AUDIT_ROOT}/$(date +%Y%m%d-%H%M%S)-actionable.json"
python3 - "${AUDIT_FILE}" "${PRODUCT_NAME}" "${MODE_VALUE}" "${REASON_VALUE}" "${RAW_INPUT}" "${REQUEST_FILE}" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

path = Path(sys.argv[1])
payload = {
    "project": sys.argv[2],
    "classification": "actionable",
    "mode": sys.argv[3],
    "reason": sys.argv[4],
    "request": sys.argv[5],
    "request_file": sys.argv[6],
    "created_at": datetime.now(timezone.utc).isoformat(),
}
path.write_text(json.dumps(payload, ensure_ascii=False))
PY

WATCH_CMD=("${SCRIPT_DIR}/dispatch-watch.sh" --config "${CONFIG_PATH}" --interval "${INTERVAL_SECONDS}" --once)
case "${MODE_VALUE}" in
	auto)
		WATCH_CMD+=(--auto-apply)
		;;
	apply)
		WATCH_CMD+=(--apply)
		;;
	propose)
		;;
esac

"${WATCH_CMD[@]}"
if [[ "${JSON_OUTPUT}" == "true" ]]; then
	python3 - "${REQUEST_FILE}" "${MODE_VALUE}" <<'PY'
import json, sys
print(json.dumps({
    "classification": "actionable",
    "mode": sys.argv[2],
    "request": sys.argv[1],
}, ensure_ascii=False))
PY
else
	printf 'classification: actionable\n'
	printf 'request: %s\n' "${REQUEST_FILE}"
fi
