#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
JSON_OUTPUT="false"
LATEST_LIMIT="20"

while [[ $# -gt 0 ]]; do
	case "$1" in
		--config)
			CONFIG_PATH="$2"
			shift 2
			;;
		--json)
			JSON_OUTPUT="true"
			shift
			;;
		--latest)
			LATEST_LIMIT="$2"
			shift 2
			;;
		*)
			die "usage: intake-tune.sh --config <file> [--json] [--latest <n>]"
			;;
	esac
done

load_config "${CONFIG_PATH}"
mkdir -p "${INTAKE_AUDIT_ROOT}"

python3 - "${INTAKE_AUDIT_ROOT}" "${JSON_OUTPUT}" "${LATEST_LIMIT}" <<'PY'
import json
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
json_output = sys.argv[2] == "true"
latest_limit = int(sys.argv[3])

action_keywords = [
    "해줘", "해주세요", "부탁해", "부탁합니다",
    "구현", "수정", "정리", "개선", "추가", "삭제", "제거", "설계", "작성", "검토", "리뷰", "분석", "조사", "연결", "세팅", "설정", "자동화", "테스트", "디버그", "고쳐",
    "implement", "fix", "update", "refactor", "review", "check", "investigate", "analyze", "create", "setup", "set up", "wire", "write", "test", "debug", "clean up",
]
chat_keywords = [
    "안녕", "안녕하세요", "반가워", "고마워", "감사", "thanks", "thank you", "hello", "hi", "hey"
]

items = []
for path in sorted(root.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True):
    try:
        data = json.loads(path.read_text())
    except Exception:
        continue
    data["audit_file"] = str(path)
    items.append(data)

recent = items[:latest_limit]
suspicious_ignored = []
suspicious_actionable = []

for item in recent:
    request = item.get("request", "")
    lowered = request.lower()
    classification = item.get("classification")

    looks_actionable = any(keyword in request or keyword in lowered for keyword in action_keywords)
    looks_chatty = any(keyword in request or keyword in lowered for keyword in chat_keywords)

    if classification == "ignore" and looks_actionable:
        suspicious_ignored.append(item)
    if classification == "actionable" and looks_chatty and not looks_actionable:
        suspicious_actionable.append(item)

recommendations = []
if suspicious_ignored:
    recommendations.append("Check ignored requests that still contain action verbs or explicit work language.")
if suspicious_actionable:
    recommendations.append("Check actionable requests that look like greetings or thanks.")
if not recommendations:
    recommendations.append("No obvious tuning candidates found in the latest intake audit sample.")

payload = {
    "root": str(root),
    "sample_size": len(recent),
    "suspicious_ignored": suspicious_ignored,
    "suspicious_actionable": suspicious_actionable,
    "recommendations": recommendations,
}

if json_output:
    print(json.dumps(payload, ensure_ascii=False))
    raise SystemExit(0)

print("== intake tune ==")
print(f"root: {root}")
print(f"sample_size: {len(recent)}")

print("suspicious_ignored:")
if suspicious_ignored:
    for item in suspicious_ignored:
        print(f"  - [{item.get('reason', '')}] {item.get('request', '')}")
else:
    print("  - (empty)")

print("suspicious_actionable:")
if suspicious_actionable:
    for item in suspicious_actionable:
        print(f"  - [{item.get('reason', '')}] {item.get('request', '')}")
else:
    print("  - (empty)")

print("recommendations:")
for recommendation in recommendations:
    print(f"  - {recommendation}")
PY
