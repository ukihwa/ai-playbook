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

if root.exists():
    for path in root.glob("*.json"):
        try:
            data = json.loads(path.read_text())
        except Exception:
            continue
        counter[data.get("status", "unknown")] += 1

total = sum(counter.values())
print(f" - total tickets: {total}")
for key in ["proposed", "needs-triage", "approved", "applied-task", "applied-review", "done", "blocked", "rejected"]:
    if counter.get(key):
        print(f" - {key}: {counter[key]}")
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
