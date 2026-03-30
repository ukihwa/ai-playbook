#!/usr/bin/env bash

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
MODE_VALUE="auto"

usage() {
	cat <<'EOF'
usage: triage-console.sh --config <file> [--mode auto|apply|propose]

Interactive triage console for plain natural-language requests.
Plain text is routed through intake. Slash-style helper commands are also available.
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--config)
			CONFIG_PATH="$2"
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

need_cmd python3
load_config "${CONFIG_PATH}"

run_helper() {
	local description="$1"
	shift
	if ! "$@"; then
		echo "error: ${description} failed"
		return 1
	fi
	return 0
}

restore_triage_focus() {
	if tmux_has_session && tmux_window_exists "triage"; then
		tmux select-window -t "$(pane_path "triage")" >/dev/null 2>&1 || true
		tmux select-pane -t "$(tmux_pane_target "triage" 0)" >/dev/null 2>&1 || true
	fi
}

echo "== triage console =="
echo "project: ${PRODUCT_NAME}"
echo "mode: ${MODE_VALUE}"
echo "plain text -> intake"
echo "commands: /status, /queue, /queue-needs, /queue-needs-latest, /daily-report, /repair, /repair-apply, /approve <ticket>, /reject <ticket> [note], /finish <ticket>, /exit"
echo

while true; do
	printf 'triage> '
	if ! IFS= read -r line; then
		exit 0
	fi

	line="${line#"${line%%[![:space:]]*}"}"
	line="${line%"${line##*[![:space:]]}"}"
	[[ -n "${line}" ]] || continue

	case "${line}" in
		/exit|/quit)
			echo "bye"
			exit 0
			;;
		/status)
			run_helper "status" "${SCRIPT_DIR}/status.sh" --config "${CONFIG_PATH}" || true
			restore_triage_focus
			continue
			;;
		/queue)
			run_helper "queue" "${SCRIPT_DIR}/queue.sh" --config "${CONFIG_PATH}" || true
			restore_triage_focus
			continue
			;;
		/queue-needs)
			run_helper "queue-needs" "${SCRIPT_DIR}/queue.sh" --config "${CONFIG_PATH}" --status needs-triage || true
			restore_triage_focus
			continue
			;;
		/queue-needs-latest)
			run_helper "queue-needs-latest" "${SCRIPT_DIR}/queue.sh" --config "${CONFIG_PATH}" --status needs-triage --latest 5 || true
			restore_triage_focus
			continue
			;;
		/daily-report)
			run_helper "daily-report" "${SCRIPT_DIR}/daily-report.sh" --config "${CONFIG_PATH}" || true
			restore_triage_focus
			continue
			;;
		/repair)
			run_helper "repair-tasks" "${SCRIPT_DIR}/repair-tasks.sh" --config "${CONFIG_PATH}" || true
			restore_triage_focus
			continue
			;;
		/repair-apply)
			run_helper "repair-tasks-apply" "${SCRIPT_DIR}/repair-tasks.sh" --config "${CONFIG_PATH}" --apply || true
			restore_triage_focus
			continue
			;;
		/approve\ *)
			ticket="${line#"/approve "}"
			run_helper "approve-ticket" "${SCRIPT_DIR}/approve-ticket.sh" --config "${CONFIG_PATH}" "${ticket}" || true
			restore_triage_focus
			continue
			;;
		/reject\ *)
			rest="${line#"/reject "}"
			ticket="${rest%% *}"
			note=""
			if [[ "${rest}" != "${ticket}" ]]; then
				note="${rest#${ticket} }"
			fi
			if [[ -n "${note}" ]]; then
				run_helper "reject-ticket" "${SCRIPT_DIR}/reject-ticket.sh" --config "${CONFIG_PATH}" --note "${note}" "${ticket}" || true
			else
				run_helper "reject-ticket" "${SCRIPT_DIR}/reject-ticket.sh" --config "${CONFIG_PATH}" "${ticket}" || true
			fi
			restore_triage_focus
			continue
			;;
		/finish\ *)
			ticket="${line#"/finish "}"
			run_helper "finish-task" "${SCRIPT_DIR}/finish-task.sh" --config "${CONFIG_PATH}" "${ticket}" || true
			restore_triage_focus
			continue
			;;
		/*)
			echo "unsupported command: ${line}"
			continue
			;;
	esac

	if ! result="$("${SCRIPT_DIR}/intake.sh" --config "${CONFIG_PATH}" --mode "${MODE_VALUE}" --json --text "${line}" 2>&1)"; then
		echo "error: intake failed"
		echo "${result}"
		restore_triage_focus
		continue
	fi

	if ! python3 - "${result}" <<'PY'
import json
import sys

payload = json.loads(sys.argv[1])
classification = payload.get("classification", "unknown")
if classification == "ignore":
    print(f"ignored: {payload.get('reason', 'unknown')}")
else:
    watch = payload.get("watch_result") or {}
    action = watch.get("action", "queued")
    ticket = watch.get("ticket", "")
    reason = watch.get("reason", "")
    request = payload.get("request", "")
    if action == "auto-applied":
        print(f"auto-applied: {ticket or request}")
    elif action == "applied":
        print(f"applied: {ticket or request}")
    elif action == "needs-triage":
        suffix = f" ({reason})" if reason else ""
        print(f"needs-triage: {ticket or request}{suffix}")
    elif action == "proposed":
        print(f"proposed: {ticket or request}")
    elif action == "failed":
        print(f"failed: {request}")
    else:
        print(f"queued: {request}")
PY
	then
		echo "error: failed to parse intake result"
		echo "${result}"
		restore_triage_focus
		continue
	fi
	restore_triage_focus
done
