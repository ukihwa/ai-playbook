# Tmux Scripts

이 디렉터리는 tmux 기반 AI 협업 자동화를 위한 실행 스크립트를 담습니다.

## Commands

- `init-product.sh --config <file>`
- `new-task.sh --config <file> <target> <slug>`
- `review-task.sh --config <file> <target> <slug>`
- `status.sh --config <file>`
- `cleanup-task.sh --config <file> [--delete-worktree] <target> <slug>`

## Config

예시:

- `config/example.env`
- `config/soullink.env`

필수 값:

- `PRODUCT_NAME`
- `WORK_ROOT`
- `WORKTREE_ROOT`
- `TARGET_<NAME>`

선택 값:

- `TMUX_SESSION`
- `DEFAULT_BRANCH`
- `TRIAGE_DIR`
- `RUN_FE_DIR`, `RUN_BE_DIR`, `RUN_APP_DIR`
- `CLAUDE_FE_DIR`, `CLAUDE_BE_DIR`, `CLAUDE_APP_DIR`

## Design Rules

- 특정 사용자 절대 경로를 스크립트 코드에 하드코딩하지 않습니다.
- config 파일로 경로를 주입합니다.
- 메인 triage, runtime, worker, review를 분리합니다.
- task worktree 브랜치는 기본적으로 `codex/<target>/<slug>` 규칙을 사용합니다.
