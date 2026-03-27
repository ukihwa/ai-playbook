# Tmux Scripts

이 디렉터리는 tmux 기반 AI 협업 자동화를 위한 실행 스크립트를 담습니다.

## Commands

- `init-product.sh --config <file> [--bootstrap-defaults]`
- `bootstrap-agent.sh --config <file> --agent <claude|codex|gemini> <window>`
- `new-task.sh --config <file> [--agent <claude|codex|gemini>] [--pane <index>] <target> <slug>`
- `start-task.sh --config <file> [--agent <claude|codex|gemini>] <target> <slug>`
- `start-task-from-spec.sh --config <file> [--agent <claude|codex|gemini>] <target> <slug> <spec-or-issue-file>`
- `handoff.sh --config <file> [--pane <index>] [--mode shell|prompt] [--interrupt|--no-interrupt] <window> <ticket-file>`
- `review-task.sh --config <file> [--agent <claude|codex|gemini>] [--pane <index>] <target> <slug>`
- `start-review.sh --config <file> [--agent <claude|codex|gemini>] <target> <slug>`
- `status.sh --config <file>`
- `cleanup-task.sh --config <file> [--delete-worktree] <target> <slug>`

## Common Flows

- 기본 세션 + 기본 Claude 창 부팅:
  - `scripts/tmux/init-product.sh --config config/<product>.env --bootstrap-defaults`
- 새 task window + Codex 부팅:
  - `scripts/tmux/new-task.sh --config config/<product>.env --agent codex <target> <slug>`
- 새 task window + handoff 생성 + Codex 부팅:
  - `scripts/tmux/start-task.sh --config config/<product>.env --agent codex --mode prompt --goal "..." --done "..." <target> <slug>`
- spec 또는 GitHub issue 본문에서 바로 task 시작:
  - `scripts/tmux/start-task-from-spec.sh --config config/<product>.env --agent codex <target> <slug> /path/to/spec.md`
- 리뷰 window + Gemini 부팅:
  - `scripts/tmux/review-task.sh --config config/<product>.env --agent gemini <target> <slug>`
- 리뷰 window + artifact 생성 + Gemini 부팅:
  - `scripts/tmux/start-review.sh --config config/<product>.env --agent gemini --mode prompt --review-focus "..." <target> <slug>`
- worker pane에 task brief 전달:
  - `scripts/tmux/handoff.sh --config config/<product>.env <target>/<slug> /path/to/handoff.md`

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
- `AGENT_CLAUDE_CMD`
- `AGENT_CODEX_CMD`
- `AGENT_GEMINI_CMD`
- `RUN_FE_DIR`, `RUN_BE_DIR`, `RUN_APP_DIR`
- `CLAUDE_FE_DIR`, `CLAUDE_BE_DIR`, `CLAUDE_APP_DIR`

## Design Rules

- 특정 사용자 절대 경로를 스크립트 코드에 하드코딩하지 않습니다.
- config 파일로 경로를 주입합니다.
- 메인 triage, runtime, worker, review를 분리합니다.
- task worktree 브랜치는 기본적으로 `codex/<target>/<slug>` 규칙을 사용합니다.
- handoff는 task brief 파일을 기준으로 worker pane에 전달합니다.
- 기본값은 `--mode shell`이며, 일반 셸 pane에서도 에러 없이 handoff 내용을 출력합니다.
- Claude/Codex/Gemini 프롬프트 pane에 직접 붙일 때만 `--mode prompt`를 사용합니다.
- `shell` 모드에서는 기본적으로 `C-c`를 보내고, `prompt` 모드에서는 기본적으로 인터럽트를 보내지 않습니다.
- agent bootstrap은 config에 정의된 CLI 명령을 사용합니다.
- `start-task`와 `start-review`는 prompt 모드일 때 pane가 agent 프로세스로 전환될 때까지 잠시 기다린 뒤 handoff를 보냅니다.
