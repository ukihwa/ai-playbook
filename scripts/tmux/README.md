# Tmux Scripts

이 디렉터리는 tmux 기반 AI 협업 자동화를 위한 실행 스크립트를 담습니다.

## Commands

- `init-product.sh --config <file> [--bootstrap-defaults]`
- `../setup/init-project.sh <project> --root <absolute-path> [--primary-target <name>] [--primary-dir <path>]`
- `start-runtime.sh --config <file> [--wait] <fe|be|app>`
- `stop-runtime.sh --config <file> <fe|be|app>`
- `bootstrap-agent.sh --config <file> --agent <claude|codex|gemini> <window>`
- `new-task.sh --config <file> [--agent <claude|codex|gemini>] [--pane <index>] <target> <slug>`
- `start-task.sh --config <file> [--agent <claude|codex|gemini>] <target> <slug>`
- `start-task-from-spec.sh --config <file> [--agent <claude|codex|gemini>] <target> <slug> <spec-or-issue-file>`
- `handoff.sh --config <file> [--pane <index>] [--mode shell|prompt] [--interrupt|--no-interrupt] <window> <ticket-file>`
- `review-task.sh --config <file> [--agent <claude|codex|gemini>] [--pane <index>] <target> <slug>`
- `start-review.sh --config <file> [--agent <claude|codex|gemini>] <target> <slug>`
- `status.sh --config <file> [--json]`
- `intake-history.sh --config <file> [--json] [--classification <value>] [--latest <n>]`
- `intake-report.sh --config <file> [--json]`
- `intake-tune.sh --config <file> [--json] [--latest <n>]`
- `queue.sh --config <file> [--json] [--status <value>] [--target <value>] [--latest <n>] [--count]`
- `history.sh --config <file> [--json] [--status <csv>] [--latest <n>]`
- `report.sh --config <file> [--json]`
- `daily-report.sh --config <file> [--json] [--latest <n>] [--include-proposed]`
- `apply-ticket.sh --config <file> [--agent <name>] [--mode <mode>] [--pane <index>] <ticket-file|target/slug|slug>`
- `approve-ticket.sh --config <file> [--agent <name>] [--mode <mode>] [--pane <index>] [--note <text>] <ticket-file|target/slug|slug>`
- `reject-ticket.sh --config <file> [--note <text>] <ticket-file|target/slug|slug>`
- `request-triage.sh --config <file> [--note <text>] <ticket-file|target/slug|slug>`
- `mark-ticket.sh --config <file> --status <value> [--note <text>] <ticket-file|target/slug|slug>`
- `dispatch-watch.sh --config <file> [--apply] [--auto-apply] [--interval <seconds>] [--once]`
- `triage-bridge.sh --config <file> [--interval <seconds>] [--mode auto|apply|propose]`
- `intake.sh --config <file> [--text <request> | --file <path>] [--mode auto|apply|propose] [--interval <seconds>] [--force] [--json]`
- `start-watch.sh --config <file> [--apply] [--auto-apply] [--interval <seconds>]`
- `stop-watch.sh --config <file>`
- `archive-ticket.sh --config <file> <ticket-file|target/slug|slug>`
- `archive-completed.sh --config <file> [--latest <n>]`
- `cleanup-task.sh --config <file> [--delete-worktree] <target> <slug>`

## Common Flows

- 단일 명령 래퍼:
- `workspace up <project>`
- `workspace init-project <project> --root /absolute/path/to/project`
  - `workspace up-bootstrap <project>`
  - `workspace dev <project>`
  - `workspace all <project>`
  - `workspace run <project> <fe|be|app>`
  - `workspace stop-run <project> <fe|be|app>`
  - `workspace status <project>`
  - `workspace status <project> --json`
  - `workspace intake-history <project>`
  - `workspace intake-report <project>`
  - `workspace intake-tune <project>`
  - `workspace queue <project>`
  - `workspace queue <project> --include-archived`
  - `workspace queue <project> --status proposed`
  - `workspace queue <project> --latest 5`
  - `workspace queue <project> --count`
  - `workspace history <project>`
  - `workspace report <project>`
  - `workspace daily-report <project>`
  - `workspace apply-ticket <project> <ticket>`
  - `workspace approve-ticket <project> <ticket>`
  - `workspace reject-ticket <project> <ticket>`
  - `workspace request-triage <project> <ticket>`
  - `workspace mark-ticket <project> --status done <ticket>`
  - `workspace dispatch-watch <project>`
  - `workspace enqueue-dispatch <project> --text "..."`
  - `workspace intake <project> --text "..."`
  - `workspace watch <project>`
  - `workspace stop-watch <project>`
  - `workspace archive-ticket <project> <ticket>`
  - `workspace archive-completed <project>`
  - `workspace start-task <project> ...`
  - `workspace task-from-spec <project> ...`
  - `workspace dispatch <project> --text "..."`
  - `workspace queue <project> --json`
  - `workspace dispatch-watch <project> --once`
  - `workspace dispatch-watch <project> --auto-apply --once`
  - `workspace start-review <project> ...`
  - `ws up <project>`
  - triage pane custom commands:
    - `/dispatch-task ...`
    - `/apply-dispatch ...`
- 기본 세션 + 기본 Claude 창 부팅:
  - `scripts/tmux/init-product.sh --config config/<product>.env --bootstrap-defaults`
- 기본 세션 + FE/BE 런타임 시작:
  - `scripts/tmux/start-runtime.sh --config config/<product>.env --wait be`
  - `scripts/tmux/start-runtime.sh --config config/<product>.env --wait fe`
- 개별 런타임 시작/중지:
  - `scripts/tmux/start-runtime.sh --config config/<product>.env app`
  - `scripts/tmux/stop-runtime.sh --config config/<product>.env app`
- 새 task window + Codex 부팅:
  - `scripts/tmux/new-task.sh --config config/<product>.env --agent codex <target> <slug>`
- 새 task window + handoff 생성 + Codex 부팅:
  - `scripts/tmux/start-task.sh --config config/<product>.env --agent codex --mode prompt --goal "..." --done "..." <target> <slug>`
- spec 또는 GitHub issue 본문에서 바로 task 시작:
  - `scripts/tmux/start-task-from-spec.sh --config config/<product>.env --agent codex <target> <slug> /path/to/spec.md`
- 자연어 또는 markdown에서 task 제안/실행:
  - `scripts/tmux/dispatch.sh --config config/<product>.env --text "..." `
  - `scripts/tmux/dispatch.sh --config config/<product>.env /path/to/request.md --apply`
- 파일 inbox를 감시하며 자연어/markdown 요청 처리:
  - `scripts/tmux/dispatch-watch.sh --config config/<product>.env`
  - `scripts/tmux/dispatch-watch.sh --config config/<product>.env --apply`
- 자연어 요청을 한 번에 intake:
  - `workspace intake <project> --text "..."`
  - `workspace intake <project> --file /path/to/request.md --mode auto`
- intake 분류 관측:
  - `workspace intake-history <project>`
  - `workspace intake-history <project> --classification ignore`
  - `workspace intake-report <project>`
  - `workspace intake-tune <project>`
- queue에서 proposal 필터링/실행:
  - `workspace queue <project> --status proposed`
  - `workspace queue <project> --status needs-triage`
  - `workspace queue <project> --latest 5`
  - `workspace apply-ticket <project> backend/api`
  - `workspace request-triage <project> backend/api`
  - `workspace approve-ticket <project> backend/api`
  - `workspace reject-ticket <project> backend/api`
  - `workspace mark-ticket <project> --status done backend/api`
- 완료/보류 흐름 요약:
  - `workspace history <project>`
  - `workspace report <project>`
  - `workspace daily-report <project>`
  - `workspace watch <project>`
  - `workspace watch <project> --auto-apply`
  - `workspace watch <project> --apply`
- triage 입력을 inbox 파일로 저장:
  - `scripts/helpers/create-dispatch-request.sh --config config/<product>.env --text "..."`
  - `workspace enqueue-dispatch <project> --text "..."`
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
- 새 프로젝트는 먼저 `workspace init-project <project> --root <absolute-path>`로 config 초안을 생성한 뒤 필요 시 수정합니다.

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
- `RUN_FE_CMD`, `RUN_BE_CMD`, `RUN_APP_CMD`
- `RUN_FE_PRE_CMD`, `RUN_BE_PRE_CMD`, `RUN_APP_PRE_CMD`
- `RUN_FE_PRE_WAIT_PORTS`, `RUN_BE_PRE_WAIT_PORTS`, `RUN_APP_PRE_WAIT_PORTS`
- `RUN_FE_WAIT_PORTS`, `RUN_BE_WAIT_PORTS`, `RUN_APP_WAIT_PORTS`
- `RUN_FE_WAIT_TIMEOUT`, `RUN_BE_WAIT_TIMEOUT`, `RUN_APP_WAIT_TIMEOUT`
- `DISPATCH_TICKET_ROOT`
- `DISPATCH_INBOX_ROOT`
- `CLAUDE_FE_DIR`, `CLAUDE_BE_DIR`, `CLAUDE_APP_DIR`

## Design Rules

- 특정 사용자 절대 경로를 스크립트 코드에 하드코딩하지 않습니다.
- config 파일로 경로를 주입합니다.
- 메인 triage, runtime, worker, review를 분리합니다.
- `dev`와 `all`은 기본적으로 FE/BE 런타임을 올리고 readiness check를 기다립니다.
- `app` 런타임은 더 무거울 수 있으므로 기본 자동 시작 대상에서 제외하고 필요할 때만 `run app`으로 올립니다.
- 필요하면 runtime 시작 전에 `RUN_*_PRE_CMD`로 인프라를 먼저 보장할 수 있습니다.
- 백엔드처럼 Docker 인프라가 필요한 경우 `RUN_BE_PRE_CMD`에서 Docker Desktop, db, redis를 먼저 준비한 뒤 앱을 실행합니다.
- 전역 `up`, `dev`처럼 너무 짧은 이름은 셸/도구 충돌 가능성이 커서, 공통 런처는 `workspace` 또는 `ws`를 기본으로 사용합니다.
- `dispatch`는 proposal/apply 결과를 `DISPATCH_TICKET_ROOT`에 JSON으로 남겨 다음 단계 오케스트레이터가 읽을 수 있게 합니다.
- triage pane 자체를 직접 파싱하기보다, 요청을 `DISPATCH_INBOX_ROOT`의 markdown/text 파일로 떨어뜨리고 `dispatch-watch`가 그것을 처리하는 방식이 더 안정적입니다.
- `workspace watch <project>`는 `dispatch-watch`와 함께 `triage-watch` 브리지도 켜서 triage pane의 최신 일반 입력을 `intake`로 넘깁니다.
- `triage-watch`는 일반 자연어만 대상으로 하며, slash command(`/...`)는 자동 intake 대상으로 삼지 않습니다.
- 실사용 UX는 `dispatch-task -> enqueue-dispatch -> dispatch-watch` 흐름으로 구성하는 편이 자연스럽습니다.
- triage에서 일반 자연어 구현 요청을 받으면, 내부적으로는 `workspace intake <project> --text "..."`를 기본 진입점으로 쓰는 것이 가장 단순합니다.
- `intake`는 짧은 인사, 감사, 일반 질문 같은 non-actionable 대화는 무시하고, 실제 구현/리뷰/정리 요청만 dispatch inbox로 보냅니다.
- `intake`는 모든 판단 결과를 `INTAKE_AUDIT_ROOT`에 남겨 나중에 오탐/누락을 조정할 수 있게 합니다.
- high-risk 또는 ambiguous 변경은 worker/reviewer가 `request-triage`로 triage queue에 다시 올리고, triage가 `approve-ticket` 또는 `reject-ticket`으로 승인 게이트를 담당합니다.
- task worktree 브랜치는 기본적으로 `codex/<target>/<slug>` 규칙을 사용합니다.
- handoff는 task brief 파일을 기준으로 worker pane에 전달합니다.
- 기본값은 `--mode shell`이며, 일반 셸 pane에서도 에러 없이 handoff 내용을 출력합니다.
- Claude/Codex/Gemini 프롬프트 pane에 직접 붙일 때만 `--mode prompt`를 사용합니다.
- `shell` 모드에서는 기본적으로 `C-c`를 보내고, `prompt` 모드에서는 기본적으로 인터럽트를 보내지 않습니다.
- agent bootstrap은 config에 정의된 CLI 명령을 사용합니다.
- `start-task`와 `start-review`는 prompt 모드일 때 pane가 agent 프로세스로 전환될 때까지 잠시 기다린 뒤 handoff를 보냅니다.
