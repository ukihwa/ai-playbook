# Tmux Scripts

이 디렉터리는 tmux 기반 AI 협업 자동화를 위한 스크립트 골격을 담습니다.

## Planned Commands

- `init-product.sh`
- `new-task.sh`
- `review-task.sh`
- `status.sh`
- `cleanup-task.sh`

## Design Rules

- 특정 사용자 절대 경로를 하드코딩하지 않습니다.
- 환경 변수 또는 config 파일로 경로를 주입합니다.
- 메인 triage, runtime, worker, review를 분리합니다.

