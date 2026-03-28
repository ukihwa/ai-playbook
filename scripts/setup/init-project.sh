#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TEMPLATE_DIR="${ROOT_DIR}/templates"
CONFIG_DIR="${ROOT_DIR}/config"

PROJECT_NAME=""
ROOT_PATH=""
PRIMARY_TARGET="pro-web"
PRIMARY_DIR=""
BACKEND_TARGET=""
BACKEND_DIR=""
APP_TARGET="app"
APP_DIR=""
CLAUDE_DIR=""
DEFAULT_BRANCH="main"
FORCE="false"

usage() {
	cat <<'EOF'
Usage: init-project.sh <project> --root <absolute-path> [options]

Options:
  --primary-target <name>   Primary implementation target name (default: pro-web)
  --primary-dir <path>      Primary target directory (default: <root>)
  --backend-target <name>   Secondary/backend target name (default: backend or primary target)
  --backend-dir <path>      Secondary/backend target directory
  --app-target <name>       App target alias (default: app)
  --app-dir <path>          App target directory (default: primary dir)
  --claude-dir <path>       Directory that should receive .claude/commands (default: primary dir)
  --default-branch <name>   Default git branch (default: main)
  --force                   Overwrite generated files if they already exist
EOF
}

die() {
	echo "error: $*" >&2
	exit 1
}

is_abs() {
	[[ "$1" == /* ]]
}

normalize_target_key() {
	printf '%s' "$1" | tr '[:lower:]-' '[:upper:]_'
}

write_file() {
	local path="$1"
	local content="$2"
	if [[ -e "${path}" && "${FORCE}" != "true" ]]; then
		return 0
	fi
	mkdir -p "$(dirname "${path}")"
	printf '%s' "${content}" > "${path}"
}

copy_if_missing() {
	local from="$1"
	local to="$2"
	if [[ -e "${to}" && "${FORCE}" != "true" ]]; then
		return 0
	fi
	mkdir -p "$(dirname "${to}")"
	cp "${from}" "${to}"
}

render_command_template() {
	local from="$1"
	local to="$2"
	if [[ -e "${to}" && "${FORCE}" != "true" ]]; then
		return 0
	fi
	mkdir -p "$(dirname "${to}")"
	sed "s/soullink/${PROJECT_NAME}/g" "${from}" > "${to}"
}

append_ignore_if_missing() {
	local gitignore_path="$1"
	local entry="$2"
	mkdir -p "$(dirname "${gitignore_path}")"
	touch "${gitignore_path}"
	if ! grep -Fxq "${entry}" "${gitignore_path}"; then
		printf '\n%s\n' "${entry}" >> "${gitignore_path}"
	fi
}

append_block_line() {
	local __var_name="$1"
	local __line="$2"
	printf -v "${__var_name}" '%s%s\n' "${!__var_name:-}" "${__line}"
}

infer_runtime_cmd() {
	local dir="$1"
	local kind="$2"
	if [[ -z "${dir}" || ! -d "${dir}" ]]; then
		return 0
	fi
	if [[ "${kind}" == "fe" && -f "${dir}/package.json" ]]; then
		printf 'corepack pnpm dev'
		return 0
	fi
	if [[ "${kind}" == "be" && -f "${dir}/pyproject.toml" ]]; then
		printf 'uv run uvicorn app.main:app --reload --port 8000'
		return 0
	fi
}

PROJECT_NAME="${1:-}"
[[ -n "${PROJECT_NAME}" ]] || {
	usage >&2
	exit 1
}
shift

while [[ $# -gt 0 ]]; do
	case "$1" in
		--root)
			ROOT_PATH="$2"
			shift 2
			;;
		--primary-target)
			PRIMARY_TARGET="$2"
			shift 2
			;;
		--primary-dir)
			PRIMARY_DIR="$2"
			shift 2
			;;
		--backend-target)
			BACKEND_TARGET="$2"
			shift 2
			;;
		--backend-dir)
			BACKEND_DIR="$2"
			shift 2
			;;
		--app-target)
			APP_TARGET="$2"
			shift 2
			;;
		--app-dir)
			APP_DIR="$2"
			shift 2
			;;
		--claude-dir)
			CLAUDE_DIR="$2"
			shift 2
			;;
		--default-branch)
			DEFAULT_BRANCH="$2"
			shift 2
			;;
		--force)
			FORCE="true"
			shift
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			die "unknown option: $1"
			;;
	esac
done

[[ -n "${ROOT_PATH}" ]] || die "--root is required"
is_abs "${ROOT_PATH}" || die "--root must be an absolute path"
[[ -d "${ROOT_PATH}" ]] || die "root path not found: ${ROOT_PATH}"

PRIMARY_DIR="${PRIMARY_DIR:-${ROOT_PATH}}"
APP_DIR="${APP_DIR:-${PRIMARY_DIR}}"
CLAUDE_DIR="${CLAUDE_DIR:-${PRIMARY_DIR}}"
BACKEND_TARGET="${BACKEND_TARGET:-backend}"
if [[ -z "${BACKEND_DIR}" ]]; then
	BACKEND_TARGET="${PRIMARY_TARGET}"
	BACKEND_DIR="${PRIMARY_DIR}"
fi

is_abs "${PRIMARY_DIR}" || die "--primary-dir must be absolute"
is_abs "${APP_DIR}" || die "--app-dir must be absolute"
is_abs "${CLAUDE_DIR}" || die "--claude-dir must be absolute"
is_abs "${BACKEND_DIR}" || die "--backend-dir must be absolute"

WORK_ROOT="$(cd "${ROOT_PATH}/.." && pwd)"
WORKTREE_ROOT="${WORK_ROOT}/worktrees/${PROJECT_NAME}"
CONFIG_PATH="${CONFIG_DIR}/${PROJECT_NAME}.env"
FE_CMD="$(infer_runtime_cmd "${PRIMARY_DIR}" fe)"
BE_CMD="$(infer_runtime_cmd "${BACKEND_DIR}" be)"
TARGET_BLOCK=""
add_target_assignment() {
	local target_name="$1"
	local target_dir="$2"
	local key
	key="$(normalize_target_key "${target_name}")"
	[[ -n "${target_dir}" ]] || return 0
	if printf '%s\n' "${TARGET_BLOCK}" | grep -Fq "TARGET_${key}="; then
		return 0
	fi
	append_block_line TARGET_BLOCK "TARGET_${key}=${target_dir}"
}

add_target_assignment "${PRIMARY_TARGET}" "${PRIMARY_DIR}"
add_target_assignment "pro-web" "${PRIMARY_DIR}"
add_target_assignment "frontend" "${PRIMARY_DIR}"
add_target_assignment "backend" "${BACKEND_DIR}"
add_target_assignment "${BACKEND_TARGET}" "${BACKEND_DIR}"
add_target_assignment "${APP_TARGET}" "${APP_DIR}"
add_target_assignment "app" "${APP_DIR}"

RUNTIME_BLOCK=""
append_block_line RUNTIME_BLOCK "RUN_FE_DIR=${PRIMARY_DIR}"
append_block_line RUNTIME_BLOCK "RUN_BE_DIR=${BACKEND_DIR}"
if [[ -n "${FE_CMD}" ]]; then
	append_block_line RUNTIME_BLOCK "RUN_FE_CMD=${FE_CMD}"
fi
if [[ -n "${BE_CMD}" ]]; then
	append_block_line RUNTIME_BLOCK "RUN_BE_CMD=${BE_CMD}"
fi

CLAUDE_BLOCK=""
append_block_line CLAUDE_BLOCK "CLAUDE_FE_DIR=${PRIMARY_DIR}"
append_block_line CLAUDE_BLOCK "CLAUDE_BE_DIR=${BACKEND_DIR}"

CONFIG_CONTENT=$(cat <<EOF
PRODUCT_NAME=${PROJECT_NAME}
TMUX_SESSION=${PROJECT_NAME}
DEFAULT_BRANCH=${DEFAULT_BRANCH}

WORK_ROOT=${WORK_ROOT}
WORKTREE_ROOT=${WORKTREE_ROOT}
TRIAGE_DIR=${ROOT_PATH}
DISPATCH_TICKET_ROOT=${ROOT_PATH}/.dispatch-tickets
DISPATCH_INBOX_ROOT=${ROOT_PATH}/docs/tasks/dispatch-inbox

AGENT_CLAUDE_CMD=/Users/ukihwa/.local/bin/claude
AGENT_CODEX_CMD=/Applications/Codex.app/Contents/Resources/codex
AGENT_GEMINI_CMD=/Users/ukihwa/.local/bin/gemini

${TARGET_BLOCK}

DISPATCH_DEFAULT_TARGET=${PRIMARY_TARGET}
DISPATCH_WEB_TARGET=${PRIMARY_TARGET}
DISPATCH_BACKEND_TARGET=${BACKEND_TARGET}
DISPATCH_APP_TARGET=${APP_TARGET}
DISPATCH_DOC_UPDATE_PRO_WEB=${ROOT_PATH}/docs/README.md
DISPATCH_DOC_UPDATE_FRONTEND=${ROOT_PATH}/docs/README.md
DISPATCH_DOC_UPDATE_BACKEND=${ROOT_PATH}/docs/tasks/triage-status.md
DISPATCH_DOC_UPDATE_DESIGN_INTENT=${ROOT_PATH}/docs/review/design-intent.md
DISPATCH_DOC_UPDATE_EVALUATION_CRITERIA=${ROOT_PATH}/docs/review/evaluation-criteria.md

${RUNTIME_BLOCK}

${CLAUDE_BLOCK}
EOF
)

write_file "${CONFIG_PATH}" "${CONFIG_CONTENT}"$'\n'

copy_if_missing "${TEMPLATE_DIR}/docs/README.md" "${ROOT_PATH}/docs/README.md"
copy_if_missing "${TEMPLATE_DIR}/docs/tasks/triage-status.md" "${ROOT_PATH}/docs/tasks/triage-status.md"

mkdir -p "${CLAUDE_DIR}/.claude/commands"
for command in dispatch-task dispatch-now apply-dispatch watch-dispatch dispatch-queue apply-ticket; do
	render_command_template \
		"${TEMPLATE_DIR}/.claude/commands/${command}.md" \
		"${CLAUDE_DIR}/.claude/commands/${command}.md"
done

append_ignore_if_missing "${ROOT_PATH}/.gitignore" ".dispatch-tickets/"
append_ignore_if_missing "${ROOT_PATH}/.gitignore" "docs/tasks/dispatch-inbox/"
append_ignore_if_missing "${ROOT_PATH}/.gitignore" "docs/tasks/handoffs/"
append_ignore_if_missing "${ROOT_PATH}/.gitignore" ".review-artifacts/"

echo "initialized project harness:"
echo "  project: ${PROJECT_NAME}"
echo "  config: ${CONFIG_PATH}"
echo "  root: ${ROOT_PATH}"
echo "  primary target: ${PRIMARY_TARGET} -> ${PRIMARY_DIR}"
echo "  backend target: ${BACKEND_TARGET} -> ${BACKEND_DIR}"
echo "  command dir: ${CLAUDE_DIR}/.claude/commands"
