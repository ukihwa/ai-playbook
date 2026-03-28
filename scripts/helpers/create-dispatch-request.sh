#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../tmux/common.sh"

CONFIG_PATH=""
INPUT_TEXT=""
INPUT_FILE=""
SLUG_OVERRIDE=""
TITLE_OVERRIDE=""

usage() {
	cat <<'EOF'
usage: create-dispatch-request.sh --config <file> [--text <request>] [--slug <slug>] [--title <title>] [<request.md>]

Creates a dispatch inbox request file in DISPATCH_INBOX_ROOT and prints the path.
EOF
}

slugify() {
	local text="$1"
	local slug
	slug="$(printf '%s' "${text}" \
		| tr '[:upper:]' '[:lower:]' \
		| sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')"
	slug="$(printf '%s' "${slug}" | cut -d'-' -f1-6)"
	if [[ -z "${slug}" ]]; then
		slug="request-$(date +%m%d-%H%M%S)"
	fi
	printf '%s' "${slug}"
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--config)
			CONFIG_PATH="$2"
			shift 2
			;;
		--text)
			INPUT_TEXT="$2"
			shift 2
			;;
		--slug)
			SLUG_OVERRIDE="$2"
			shift 2
			;;
		--title)
			TITLE_OVERRIDE="$2"
			shift 2
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			if [[ -z "${INPUT_FILE}" ]]; then
				INPUT_FILE="$1"
				shift
			else
				die "too many positional arguments"
			fi
			;;
	esac
done

if [[ -z "${INPUT_TEXT}" && -z "${INPUT_FILE}" ]]; then
	die "missing request text or request file"
fi

if [[ -n "${INPUT_TEXT}" && -n "${INPUT_FILE}" ]]; then
	die "use either --text or an input file, not both"
fi

load_config "${CONFIG_PATH}"
mkdir -p "${DISPATCH_INBOX_ROOT}"

timestamp="$(date +%Y%m%d-%H%M%S)"

if [[ -n "${INPUT_FILE}" ]]; then
	[[ -f "${INPUT_FILE}" ]] || die "input file not found: ${INPUT_FILE}"
	base_slug="${SLUG_OVERRIDE:-$(slugify "$(basename "${INPUT_FILE}")")}"
	output_path="${DISPATCH_INBOX_ROOT}/${timestamp}-${base_slug}.md"
	cp "${INPUT_FILE}" "${output_path}"
else
	base_slug="${SLUG_OVERRIDE:-$(slugify "${INPUT_TEXT}")}"
	output_path="${DISPATCH_INBOX_ROOT}/${timestamp}-${base_slug}.md"
	{
		if [[ -n "${TITLE_OVERRIDE}" ]]; then
			printf '# %s\n\n' "${TITLE_OVERRIDE}"
		fi
		printf '%s\n' "${INPUT_TEXT}"
	} > "${output_path}"
fi

printf '%s\n' "${output_path}"
