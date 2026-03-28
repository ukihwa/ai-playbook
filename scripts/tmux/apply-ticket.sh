#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
AGENT_NAME="codex"
MODE="prompt"
PANE_INDEX="0"
TICKET_INPUT=""
PRESERVE_APPROVED="false"

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
		--approved)
			PRESERVE_APPROVED="true"
			shift
			;;
		*)
			if [[ -z "${TICKET_INPUT}" ]]; then
				TICKET_INPUT="$1"
				shift
			else
				die "usage: apply-ticket.sh --config <file> [--agent <name>] [--mode <mode>] [--pane <index>] <ticket-file|target/slug|slug>"
			fi
			;;
	esac
done

[[ -n "${TICKET_INPUT}" ]] || die "usage: apply-ticket.sh --config <file> [--agent <name>] [--mode <mode>] [--pane <index>] <ticket-file|target/slug|slug>"

load_config "${CONFIG_PATH}"
mkdir -p "${DISPATCH_TICKET_ROOT}"

resolve_ticket_file() {
	local input="$1"
	if [[ -f "${input}" ]]; then
		printf '%s' "${input}"
		return
	fi

	if [[ -f "${DISPATCH_TICKET_ROOT}/${input}.json" ]]; then
		printf '%s' "${DISPATCH_TICKET_ROOT}/${input}.json"
		return
	fi

	local normalized="${input//\//-}"
	if [[ -f "${DISPATCH_TICKET_ROOT}/${normalized}.json" ]]; then
		printf '%s' "${DISPATCH_TICKET_ROOT}/${normalized}.json"
		return
	fi

	local matches=()
	while IFS= read -r path; do
		[[ -n "${path}" ]] || continue
		matches+=("${path}")
	done < <(find "${DISPATCH_TICKET_ROOT}" -maxdepth 1 -type f -name "*.json" | sort | while read -r path; do
		base="$(basename "${path}" .json)"
		if [[ "${base}" == *"${normalized}"* ]]; then
			printf '%s\n' "${path}"
		fi
	done)

	if (( ${#matches[@]} == 1 )); then
		printf '%s' "${matches[0]}"
		return
	fi

	if (( ${#matches[@]} > 1 )); then
		printf 'error: multiple tickets match "%s"\n' "${input}" >&2
		printf '  - %s\n' "${matches[@]}" >&2
		exit 1
	fi

	die "ticket not found: ${input}"
}

TICKET_FILE="$(resolve_ticket_file "${TICKET_INPUT}")"

python3 - "${TICKET_FILE}" "${SCRIPT_DIR}" "${CONFIG_PATH}" "${AGENT_NAME}" "${MODE}" "${PANE_INDEX}" "${PRESERVE_APPROVED}" <<'PY'
import json
import shlex
import subprocess
import sys
from pathlib import Path

ticket_path = Path(sys.argv[1])
script_dir = Path(sys.argv[2])
config_path = sys.argv[3]
agent_name = sys.argv[4]
mode = sys.argv[5]
pane_index = sys.argv[6]
preserve_approved = sys.argv[7].lower() == "true"

data = json.loads(ticket_path.read_text())

target = data["target"]
slug = data["slug"]
title = data.get("title", f"Dispatch: {target}/{slug}")
goal = data.get("goal", "Review the request and prepare the implementation task.")
references = data.get("references", [])
review_focus = data.get("review_focus", [])
in_scope = data.get("in_scope", [])
out_of_scope = data.get("out_of_scope", [])
done_criteria = data.get("done_criteria", [])
review_only = bool(data.get("review_only"))

def run(cmd):
    subprocess.run(cmd, check=True)

if review_only:
    data["status"] = "approved-review" if preserve_approved else "applied-review"
    ticket_path.write_text(json.dumps(data, ensure_ascii=False))
    cmd = [
        str(script_dir / "start-review.sh"),
        "--config", config_path,
        "--pane", pane_index,
        "--mode", mode,
        "--agent", agent_name,
    ]
    for item in references:
        cmd += ["--reference", item]
    for item in review_focus:
        cmd += ["--review-focus", item]
    cmd += [target, slug]
    run(cmd)
else:
    data["status"] = "approved-task" if preserve_approved else "applied-task"
    ticket_path.write_text(json.dumps(data, ensure_ascii=False))
    cmd = [
        str(script_dir / "start-task.sh"),
        "--config", config_path,
        "--pane", pane_index,
        "--mode", mode,
        "--agent", agent_name,
        "--title", title,
        "--goal", goal,
    ]
    for item in in_scope:
        cmd += ["--in-scope", item]
    for item in out_of_scope:
        cmd += ["--out-of-scope", item]
    for item in done_criteria:
        cmd += ["--done", item]
    for item in references:
        cmd += ["--reference", item]
    for item in review_focus:
        cmd += ["--review-focus", item]
    cmd += [target, slug]
    run(cmd)
PY
