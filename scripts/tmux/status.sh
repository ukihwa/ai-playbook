#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""
JSON_OUTPUT="false"

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
		*)
			die "unknown argument: $1"
			;;
	esac
done

need_cmd tmux
need_cmd git
load_config "${CONFIG_PATH}"
export PRODUCT_NAME TMUX_SESSION WORK_ROOT WORKTREE_ROOT DISPATCH_TICKET_ROOT INTAKE_AUDIT_ROOT
while IFS= read -r key; do
	export "${key}"
done < <(compgen -A variable | grep -E '^(TARGET_|RUN_)')

port_status() {
	local port="$1"
	if lsof -nP -iTCP:"${port}" -sTCP:LISTEN >/dev/null 2>&1; then
		printf 'ready'
	else
		printf 'down'
	fi
}

print_dispatch_summary() {
	python3 - "${DISPATCH_TICKET_ROOT}" <<'PY'
import json
import sys
from collections import Counter
from pathlib import Path

root = Path(sys.argv[1])
counter = Counter()
daily_report_allowed = {"applied-task", "applied-review", "done", "blocked"}
latest = None

if root.exists():
    for path in sorted(root.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True):
        try:
            data = json.loads(path.read_text())
        except Exception:
            continue
        if latest is None:
            latest = data | {"ticket_file": str(path)}
        counter[data.get("status", "unknown")] += 1

total = sum(counter.values())
print(f" - total tickets: {total}")
for key in ["proposed", "needs-triage", "approved", "approved-task", "approved-review", "applied-task", "applied-review", "done", "blocked", "rejected"]:
    if counter.get(key):
        print(f" - {key}: {counter[key]}")
daily_report_count = sum(counter.get(key, 0) for key in daily_report_allowed)
print(f" - daily-report candidates: {daily_report_count}")
if latest:
    print(
        f" - latest ticket: [{latest.get('status', 'unknown')}] "
        f"{latest.get('target', '?')}/{latest.get('slug', '?')}"
    )
    goal = latest.get("goal")
    if goal:
        print(f"   - goal: {goal}")
PY
}

print_intake_summary() {
	python3 - "${INTAKE_AUDIT_ROOT}" <<'PY'
import json
import sys
from collections import Counter
from pathlib import Path

root = Path(sys.argv[1])
items = []

if root.exists():
    for path in sorted(root.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True):
        try:
            data = json.loads(path.read_text())
        except Exception:
            continue
        items.append(data)

counter = Counter(item.get("classification", "unknown") for item in items)
total = sum(counter.values())
recent = items[:10]
recent_counter = Counter(item.get("classification", "unknown") for item in recent)

print(f" - total inputs: {total}")
for key in ["actionable", "ignore", "unknown"]:
    if counter.get(key):
        print(f" - {key}: {counter[key]}")

if recent:
    actionable = recent_counter.get("actionable", 0)
    ignore = recent_counter.get("ignore", 0)
    print(f" - recent(10): actionable={actionable}, ignore={ignore}")
    latest = recent[0]
    print(
        f" - latest intake: [{latest.get('classification', 'unknown')}] "
        f"{latest.get('reason', '')}"
    )
    request = latest.get("request")
    if request:
        print(f"   - request: {request}")
PY
}

if [[ "${JSON_OUTPUT}" == "true" ]]; then
	TMP_DIR="$(mktemp -d)"
	trap 'rm -rf "${TMP_DIR}"' EXIT

	TARGETS_FILE="${TMP_DIR}/targets.json"
	TMUX_FILE="${TMP_DIR}/tmux.json"
	RUNTIME_FILE="${TMP_DIR}/runtime.json"
	WORKTREES_FILE="${TMP_DIR}/worktrees.json"
	DISPATCH_FILE="${TMP_DIR}/dispatch.txt"
	INTAKE_FILE="${TMP_DIR}/intake.txt"

	python3 - <<'PY' > "${TARGETS_FILE}"
import json, os
targets = {}
for key, value in sorted(os.environ.items()):
    if key.startswith("TARGET_"):
        targets[key[7:]] = value
print(json.dumps(targets, ensure_ascii=False))
PY

	if tmux_has_session; then
		tmux list-windows -t "${TMUX_SESSION}" -F '{"name":"#W","panes":#{window_panes},"path":"#{pane_current_path}"}' > "${TMUX_FILE}"
	else
		: > "${TMUX_FILE}"
	fi

	python3 - <<'PY' > "${RUNTIME_FILE}"
import json, os, subprocess

session = os.environ["TMUX_SESSION"]
entries = []

def run(cmd):
    result = subprocess.run(cmd, text=True, capture_output=True)
    if result.returncode != 0:
        raise subprocess.CalledProcessError(result.returncode, cmd, result.stdout, result.stderr)
    return result.stdout.strip()

for runtime in ("fe", "be", "app"):
    window = f"{runtime}-run"
    try:
        panes = run(["tmux", "list-panes", "-t", f"{session}:{window}", "-F", "#{pane_id}"])
    except subprocess.CalledProcessError:
        continue
    pane_id = panes.splitlines()[0]
    cmd = run(["tmux", "display-message", "-p", "-t", pane_id, "#{pane_current_command}"])
    path = run(["tmux", "display-message", "-p", "-t", pane_id, "#{pane_current_path}"])
    wait_ports = os.environ.get(f"RUN_{runtime.upper()}_WAIT_PORTS", "")
    ports = []
    for port in [p.strip() for p in wait_ports.split(",") if p.strip()]:
        rc = subprocess.call(
            f"lsof -nP -iTCP:{port} -sTCP:LISTEN >/dev/null 2>&1",
            shell=True,
        )
        ports.append({"port": int(port), "status": "ready" if rc == 0 else "down"})
    entries.append({"window": window, "command": cmd or "unknown", "dir": path or "unknown", "ports": ports})

try:
    panes = run(["tmux", "list-panes", "-t", f"{session}:dispatch-watch", "-F", "#{pane_id}"])
    pane_id = panes.splitlines()[0]
    cmd = run(["tmux", "display-message", "-p", "-t", pane_id, "#{pane_current_command}"])
    watch = {"status": "running", "command": cmd or "unknown"}
except subprocess.CalledProcessError:
    watch = {"status": "stopped"}

print(json.dumps({"runtimes": entries, "watch": watch}, ensure_ascii=False))
PY

	if [[ -d "${WORKTREE_ROOT}" ]]; then
		find "${WORKTREE_ROOT}" -mindepth 2 -maxdepth 2 -type d | sort | python3 - <<'PY' > "${WORKTREES_FILE}"
import json, sys
print(json.dumps([line.strip() for line in sys.stdin if line.strip()], ensure_ascii=False))
PY
	else
		printf '[]\n' > "${WORKTREES_FILE}"
	fi

	print_dispatch_summary > "${DISPATCH_FILE}"
	print_intake_summary > "${INTAKE_FILE}"

	python3 - "${TARGETS_FILE}" "${TMUX_FILE}" "${RUNTIME_FILE}" "${WORKTREES_FILE}" "${DISPATCH_FILE}" "${INTAKE_FILE}" <<'PY'
import json
import os
import sys
from pathlib import Path

targets = json.loads(Path(sys.argv[1]).read_text())
tmux_windows = [json.loads(line) for line in Path(sys.argv[2]).read_text().splitlines() if line.strip()]
runtime_info = json.loads(Path(sys.argv[3]).read_text())
worktrees = json.loads(Path(sys.argv[4]).read_text())
dispatch_lines = [line.rstrip() for line in Path(sys.argv[5]).read_text().splitlines() if line.strip()]
intake_lines = [line.rstrip() for line in Path(sys.argv[6]).read_text().splitlines() if line.strip()]

payload = {
    "config": {
        "product": os.environ["PRODUCT_NAME"],
        "session": os.environ["TMUX_SESSION"],
        "work_root": os.environ["WORK_ROOT"],
        "worktree_root": os.environ["WORKTREE_ROOT"],
    },
    "targets": targets,
    "tmux": tmux_windows,
    "runtime": runtime_info,
    "worktrees": worktrees,
    "dispatch_summary": dispatch_lines,
    "intake_summary": intake_lines,
}

print(json.dumps(payload, ensure_ascii=False))
PY
	exit 0
fi

print_header "config"
echo "product: ${PRODUCT_NAME}"
echo "session: ${TMUX_SESSION}"
echo "work root: ${WORK_ROOT}"
echo "worktree root: ${WORKTREE_ROOT}"

print_header "targets"
while IFS= read -r key; do
	echo " - ${key#TARGET_} -> ${!key}"
done < <(compgen -A variable | grep '^TARGET_' | sort)

print_header "tmux"
if tmux_has_session; then
	tmux list-windows -t "${TMUX_SESSION}" -F ' - #W | panes=#{window_panes} | #{pane_current_path}'
else
	echo " - session not created"
fi

print_header "runtime"
if tmux_has_session; then
	for runtime in fe be app; do
		window_name="${runtime}-run"
		if ! tmux_window_exists "${window_name}"; then
			continue
		fi

		pane_id="$(tmux list-panes -t "$(pane_path "${window_name}")" -F '#{pane_id}' | head -n 1)"
		current_command="$(tmux display-message -p -t "${pane_id}" '#{pane_current_command}' 2>/dev/null || true)"
		current_path="$(tmux display-message -p -t "${pane_id}" '#{pane_current_path}' 2>/dev/null || true)"
		wait_ports="$(resolve_named_var "RUN" "${runtime}_WAIT_PORTS")"

		echo " - ${window_name} | cmd=${current_command:-unknown} | dir=${current_path:-unknown}"
		if [[ -n "${wait_ports}" ]]; then
			IFS=',' read -r -a ports <<< "${wait_ports}"
			for port in "${ports[@]}"; do
				port="${port//[[:space:]]/}"
				[[ -n "${port}" ]] || continue
				echo "   - port ${port}: $(port_status "${port}")"
			done
		fi
	done

	if tmux_window_exists "dispatch-watch"; then
		watch_pane_id="$(tmux list-panes -t "$(pane_path "dispatch-watch")" -F '#{pane_id}' | head -n 1)"
		watch_command="$(tmux display-message -p -t "${watch_pane_id}" '#{pane_current_command}' 2>/dev/null || true)"
		echo " - dispatch-watch | cmd=${watch_command:-unknown} | status=running"
	else
		echo " - dispatch-watch | status=stopped"
	fi
else
	echo " - session not created"
fi

print_header "worktrees"
if [[ -d "${WORKTREE_ROOT}" ]]; then
	find "${WORKTREE_ROOT}" -mindepth 2 -maxdepth 2 -type d | sort | while read -r dir; do
		echo " - ${dir}"
	done
else
	echo " - none"
fi

print_header "dispatch"
print_dispatch_summary

print_header "intake"
print_intake_summary
