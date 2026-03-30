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

run_helper_capture() {
	local description="$1"
	shift
	local output=""
	if ! output="$("$@" 2>&1)"; then
		echo "error: ${description} failed"
		echo "${output}"
		return 1
	fi
	printf '%s' "${output}"
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
echo "commands: /status, /status-brief, /queue, /queue-latest, /queue-needs, /queue-needs-latest, /daily-report, /repair, /repair-apply, /approve <ticket>, /reject <ticket> [note], /finish <ticket>, /exit"
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
		/status-brief)
			if output="$(run_helper_capture "status-brief" "${SCRIPT_DIR}/status.sh" --config "${CONFIG_PATH}" --json)"; then
				python3 - "${output}" <<'PY'
import json
import sys

payload = json.loads(sys.argv[1])
runtime = payload.get("runtime", [])
dispatch = payload.get("dispatch_summary", {})
intake = payload.get("intake_summary", {})
task_workers = payload.get("task_workers", [])

ready = 0
down = 0
watchers = []
for entry in runtime:
    if entry.get("name", "").endswith("-watch"):
        watchers.append(f"{entry.get('name')}={entry.get('status', 'unknown')}")
        continue
    for port in entry.get("ports", []):
        if port.get("status") == "ready":
            ready += 1
        else:
            down += 1

stuck = 0
live = 0
for worker in task_workers:
    pane0 = worker.get("pane_0_command", "")
    if pane0 in {"zsh", "bash", "sh"}:
        stuck += 1
    elif pane0:
        live += 1

counts = dispatch.get("counts", {})
latest_ticket = dispatch.get("latest_ticket") or {}
latest_intake = intake.get("latest_intake") or {}

print("== status brief ==")
print(f"runtime: ready_ports={ready}, down_ports={down}")
if watchers:
    print("watchers: " + ", ".join(watchers))
print(
    "tickets: "
    f"needs-triage={counts.get('needs-triage', 0)}, "
    f"applied-task={counts.get('applied-task', 0)}, "
    f"proposed={counts.get('proposed', 0)}, "
    f"bootstrap-failures={dispatch.get('bootstrap_failures', 0)}"
)
print(f"workers: live={live}, stuck={stuck}")
print(
    "intake: "
    f"actionable={intake.get('counts', {}).get('actionable', 0)}, "
    f"ignore={intake.get('counts', {}).get('ignore', 0)}"
)
if latest_ticket:
    print(
        "latest-ticket: "
        f"[{latest_ticket.get('status', 'unknown')}] "
        f"{latest_ticket.get('target', '?')}/{latest_ticket.get('slug', '?')}"
    )
if latest_intake:
    print(
        "latest-intake: "
        f"[{latest_intake.get('classification', 'unknown')}] "
        f"{latest_intake.get('reason', '')}"
    )
if stuck > 0:
    print("hint: stuck tasks detected -> /repair or /repair-apply")
if counts.get("needs-triage", 0) > 0:
    print("hint: triage review needed -> /queue-needs-latest")
if dispatch.get("bootstrap_failures", 0) > 0:
    print("hint: bootstrap failures present -> /queue-needs-latest")
PY
			fi
			restore_triage_focus
			continue
			;;
		/queue)
			run_helper "queue" "${SCRIPT_DIR}/queue.sh" --config "${CONFIG_PATH}" || true
			restore_triage_focus
			continue
			;;
		/queue-latest)
			run_helper "queue-latest" "${SCRIPT_DIR}/queue.sh" --config "${CONFIG_PATH}" --latest 5 || true
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
			if output="$(run_helper_capture "approve-ticket" "${SCRIPT_DIR}/approve-ticket.sh" --config "${CONFIG_PATH}" "${ticket}")"; then
				python3 - "${ticket}" "${output}" <<'PY'
import sys

ticket = sys.argv[1]
output = sys.argv[2]
result = ""
note = ""
for raw_line in output.splitlines():
    line = raw_line.strip()
    if line.startswith("result: "):
        result = line[len("result: "):]
    elif line.startswith("note: "):
        note = line[len("note: "):]

if result:
    print(f"approved: {ticket} -> {result}")
else:
    print(f"approved: {ticket}")
if note:
    print(f"note: {note}")
PY
			fi
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
			if output="$(run_helper_capture "finish-task" "${SCRIPT_DIR}/finish-task.sh" --config "${CONFIG_PATH}" "${ticket}")"; then
				python3 - "${ticket}" "${output}" <<'PY'
import sys

ticket = sys.argv[1]
output = sys.argv[2]
status = ""
archived = ""
cleaned_window = ""
deleted_worktree = ""
for raw_line in output.splitlines():
    line = raw_line.strip()
    if line.startswith("status: "):
        status = line[len("status: "):]
    elif line.startswith("archived: "):
        archived = line[len("archived: "):]
    elif line.startswith("cleaned_window: "):
        cleaned_window = line[len("cleaned_window: "):]
    elif line.startswith("deleted_worktree: "):
        deleted_worktree = line[len("deleted_worktree: "):]

print(
    f"finished: {ticket}"
    + (f" -> {status}" if status else "")
    + (f" | archived={archived}" if archived else "")
    + (f" | window={cleaned_window}" if cleaned_window else "")
    + (f" | worktree={deleted_worktree}" if deleted_worktree else "")
)
PY
			fi
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
