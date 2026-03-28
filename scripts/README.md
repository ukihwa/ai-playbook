# Scripts

AI 협업 자동화에 사용하는 실행 스크립트를 저장하는 폴더입니다.

## Directories

- `tmux/`: 세션, window, worker orchestration
- `helpers/`: 문서 생성, 검증, 상태 확인 보조 스크립트

## Current State

- `tmux/`는 실제로 실행 가능한 최소 하네스를 제공합니다.
- 모든 스크립트는 `config/*.env`를 읽도록 설계되어 있습니다.
- `helpers/`는 handoff 문서 생성 같은 반복 작업을 자동화합니다.
- `helpers/`는 review artifact 생성 같은 반복 템플릿 작업도 담당합니다.
- `helpers/`는 dispatch inbox 요청 파일 생성 같은 triage 입력 자동화도 담당합니다.
