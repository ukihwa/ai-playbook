---
title: Project Bootstrap Rehearsal
description: 새 프로젝트를 workspace 하네스에 연결할 때 실제로 따라가는 리허설 절차 문서
doc_type: checklist
status: active
source_of_truth: true
priority: 20
when_to_use:
  - 새 프로젝트를 하네스에 처음 연결할 때
  - ws init-project 결과를 검증할 때
owners:
  - ukihwa
scope:
  - cross-project
tags:
  - checklist
  - bootstrap
  - workspace
related:
  - ./new-project-checklist.md
  - ../04-automation/tmux-harness-architecture.md
last_reviewed: 2026-03-28
---

# Project Bootstrap Rehearsal

## Goal

이 문서는 새 프로젝트를 `workspace/ws` 하네스에 연결할 때, `ws init-project`부터 실제 `dispatch` 흐름까지 검증하는 절차를 정리합니다.

## Step 1. Project Structure 확인

- [ ] 프로젝트 루트 절대 경로를 확인합니다.
- [ ] 주 구현 대상 디렉터리를 정합니다.
- [ ] 보조 서비스 디렉터리가 있으면 분리합니다.
- [ ] `.claude/commands`를 어느 디렉터리에 둘지 정합니다.

## Step 2. Bootstrap 실행

예시:

```bash
ws init-project <project> \
  --root /absolute/path/to/project \
  --primary-target frontend \
  --primary-dir /absolute/path/to/project/frontend \
  --backend-target ai-service \
  --backend-dir /absolute/path/to/project/ai-service \
  --claude-dir /absolute/path/to/project/frontend
```

체크:

- [ ] `ai-playbook/config/<project>.env`가 생성됨
- [ ] `docs/README.md`가 생성됨
- [ ] `docs/tasks/triage-status.md`가 생성됨
- [ ] `.claude/commands/*`가 생성됨
- [ ] `.gitignore`에 운영 산출물 제외 규칙이 들어감

## Step 3. Config 검토

- [ ] `DISPATCH_DEFAULT_TARGET`이 제품 구조와 맞는지 확인
- [ ] `TARGET_*` 경로가 실제 디렉터리와 맞는지 확인
- [ ] `RUN_FE_CMD`, `RUN_BE_CMD`가 실제 실행 명령과 맞는지 확인
- [ ] `CLAUDE_FE_DIR`, `CLAUDE_BE_DIR`가 실제 작업 위치와 맞는지 확인

## Step 4. Session Smoke Test

```bash
ws up <project>
ws status <project>
```

체크:

- [ ] tmux 세션이 생성됨
- [ ] triage / runtime / claude 창 구조가 예상과 맞음

## Step 5. Runtime Smoke Test

```bash
ws dev <project>
ws status <project>
```

체크:

- [ ] 필요한 런타임만 실행됨
- [ ] 포트 대기와 readiness가 정상 동작함
- [ ] 불필요한 런타임은 자동으로 뜨지 않음

## Step 6. Dispatch Smoke Test

```bash
ws dispatch <project> --json --text "로그인/권한 흐름을 정리해줘"
```

체크:

- [ ] target이 의도한 디렉터리로 추론됨
- [ ] `references`에 `docs/tasks/triage-status.md`가 들어감
- [ ] `doc_updates`에 필요한 문서가 포함됨

## Step 7. Watcher Smoke Test

```bash
ws watch <project>
ws enqueue-dispatch <project> --text "모바일 진입 UX를 정리해줘"
ws queue <project>
```

체크:

- [ ] inbox 요청이 watcher에서 처리됨
- [ ] proposal ticket이 queue에 나타남
- [ ] `apply-ticket`으로 실제 작업 시작이 가능함

## Step 8. Claude Command Smoke Test

Claude 세션에서:

- [ ] `/dispatch-task ...`
- [ ] `/dispatch-queue`
- [ ] `/apply-ticket ...`

체크:

- [ ] command가 현재 프로젝트명으로 연결돼 있음
- [ ] triage pane에서 긴 shell 명령 없이도 기본 흐름이 가능함

## Done Criteria

- [ ] `ws up`, `ws dev`, `ws dispatch`, `ws watch`, `ws queue`가 모두 동작
- [ ] 기본 target 추론이 제품 구조와 맞음
- [ ] 새 프로젝트의 source of truth 문서가 최소 세트로 준비됨
- [ ] 실제 첫 작업을 안전하게 dispatch할 수 있음
