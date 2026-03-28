#!/usr/bin/env bash

set -euo pipefail

COMPOSE_FILE=""
declare -a SERVICE_SPECS=()

usage() {
	echo "usage: ensure-compose-services.sh --compose-file <path> --service <name:port> [--service <name:port> ...]" >&2
	exit 1
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--compose-file)
			COMPOSE_FILE="$2"
			shift 2
			;;
		--service)
			SERVICE_SPECS+=("$2")
			shift 2
			;;
		*)
			usage
			;;
	esac
done

[[ -n "${COMPOSE_FILE}" ]] || usage
[[ ${#SERVICE_SPECS[@]} -gt 0 ]] || usage

export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"

if ! command -v docker >/dev/null 2>&1; then
	echo "error: docker command not found" >&2
	exit 1
fi

docker info >/dev/null 2>&1 || docker desktop start --detach
until docker info >/dev/null 2>&1; do
	sleep 1
done

declare -a SERVICES_TO_START=()
for spec in "${SERVICE_SPECS[@]}"; do
	service="${spec%%:*}"
	port="${spec##*:}"

	if lsof -nP -iTCP:"${port}" -sTCP:LISTEN >/dev/null 2>&1; then
		echo "port ${port} already listening; reusing existing service for ${service}"
		continue
	fi

	SERVICES_TO_START+=("${service}")
done

if [[ ${#SERVICES_TO_START[@]} -eq 0 ]]; then
	echo "all requested service ports already available"
	exit 0
fi

docker compose -f "${COMPOSE_FILE}" up -d "${SERVICES_TO_START[@]}"
