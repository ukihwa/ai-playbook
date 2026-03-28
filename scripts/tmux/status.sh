#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		--config)
			CONFIG_PATH="$2"
			shift 2
			;;
		*)
			die "unknown argument: $1"
			;;
	esac
done

need_cmd tmux
need_cmd git
load_config "${CONFIG_PATH}"

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
PY
}

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
