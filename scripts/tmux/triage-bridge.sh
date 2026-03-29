#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
INTERVAL_SECONDS="3"
MODE_VALUE="auto"

usage() {
	cat <<'EOF'
usage: triage-bridge.sh --config <file> [--interval <seconds>] [--mode auto|apply|propose]

Watch the triage pane for plain natural-language requests and forward new inputs to intake.
The current latest prompt is used as a baseline, so older chat history is not reprocessed.
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--config)
			CONFIG_PATH="$2"
			shift 2
			;;
		--interval)
			INTERVAL_SECONDS="$2"
			shift 2
			;;
		--mode)
			MODE_VALUE="$2"
			shift 2
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

case "${MODE_VALUE}" in
	auto|apply|propose)
		;;
	*)
		die "unsupported --mode '${MODE_VALUE}'"
		;;
esac

need_cmd tmux
need_cmd python3
load_config "${CONFIG_PATH}"
tmux_has_session || die "tmux session '${TMUX_SESSION}' does not exist."

TRIAGE_WINDOW_NAME="${TRIAGE_WINDOW_NAME:-triage}"
STATE_DIR="${TRIAGE_DIR}/.triage-bridge"
STATE_FILE="${STATE_DIR}/state.json"
mkdir -p "${STATE_DIR}"

extract_latest_prompt() {
	local pane_target="$1"
	tmux capture-pane -pt "${pane_target}" -S -200 | python3 -c '
import re
import sys

candidate = ""
for raw in sys.stdin.read().splitlines():
    line = raw.rstrip()
    match = re.match(r"^\s*[❯>]\s*(.+?)\s*$", line)
    if not match:
        continue
    value = match.group(1).strip()
    if not value or value.startswith("/"):
        continue
    candidate = value

print(candidate)
'
}

read_state_hash() {
	if [[ ! -f "${STATE_FILE}" ]]; then
		return 0
	fi
	python3 - "${STATE_FILE}" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
try:
    data = json.loads(path.read_text())
except Exception:
    data = {}
print(data.get("last_hash", ""))
PY
}

write_state() {
	local text="$1"
	python3 - "${STATE_FILE}" "${text}" <<'PY'
import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

path = Path(sys.argv[1])
text = sys.argv[2]
payload = {
    "last_text": text,
    "last_hash": hashlib.sha256(text.encode("utf-8")).hexdigest(),
    "updated_at": datetime.now(timezone.utc).isoformat(),
}
path.write_text(json.dumps(payload, ensure_ascii=False))
PY
}

hash_text() {
	python3 - "$1" <<'PY'
import hashlib
import sys
print(hashlib.sha256(sys.argv[1].encode("utf-8")).hexdigest())
PY
}

TRIAGE_PANE_TARGET="${TMUX_SESSION}:${TRIAGE_WINDOW_NAME}.0"
last_hash="$(read_state_hash)"
if [[ -z "${last_hash}" ]]; then
	initial_candidate="$(extract_latest_prompt "${TRIAGE_PANE_TARGET}")"
	if [[ -n "${initial_candidate}" ]]; then
		write_state "${initial_candidate}"
		last_hash="$(hash_text "${initial_candidate}")"
	fi
fi

while true; do
	if ! tmux_has_session; then
		exit 0
	fi

	if ! tmux_window_exists "${TRIAGE_WINDOW_NAME}"; then
		sleep "${INTERVAL_SECONDS}"
		continue
	fi

	candidate="$(extract_latest_prompt "${TRIAGE_PANE_TARGET}")"
	if [[ -z "${candidate}" ]]; then
		sleep "${INTERVAL_SECONDS}"
		continue
	fi

	current_hash="$(hash_text "${candidate}")"

	if [[ "${current_hash}" != "${last_hash}" ]]; then
		if ! "${SCRIPT_DIR}/intake.sh" --config "${CONFIG_PATH}" --mode "${MODE_VALUE}" --text "${candidate}" >/dev/null; then
			printf 'triage-bridge warning: intake failed for "%s"\n' "${candidate}" >&2
		fi
		write_state "${candidate}"
		last_hash="${current_hash}"
	fi

	sleep "${INTERVAL_SECONDS}"
done
