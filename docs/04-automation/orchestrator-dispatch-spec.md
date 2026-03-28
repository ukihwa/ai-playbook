---
title: Orchestrator Dispatch Spec
description: triage 입력을 구조화하고 workspace 명령으로 연결하는 dispatcher/orchestrator의 입출력과 판단 규칙을 정의한다
doc_type: automation
status: active
source_of_truth: true
priority: 10
when_to_use:
  - 자연어 요구사항을 task/review 실행으로 연결할 때
  - ws dispatch 명령을 구현하거나 수정할 때
owners:
  - ukihwa
scope:
  - cross-project
tags:
  - orchestrator
  - dispatch
  - triage
  - workspace
related:
  - ./tmux-harness-architecture.md
  - ../03-workflows/doc-update-policy.md
  - ../03-workflows/spec-workflow.md
last_reviewed: 2026-03-28
---

# Orchestrator Dispatch Spec

## Goal

사용자가 triage pane에 자연어 요구사항만 입력해도, 시스템이 구조화된 task 계획으로 변환하고 필요 시 `workspace` 명령을 호출할 수 있게 한다.

## Position In The Architecture

- `workspace/ws`: 실행기
- `tmux harness`: 세션, runtime, task, review 엔진
- `OMC / skills / subagents`: 병렬 에이전트와 전문 역할
- `dispatcher/orchestrator`: 자연어 요구사항을 실행 계획으로 변환하는 판단기

즉 orchestrator는 직접 구현을 하지 않고, 적절한 `workspace` 명령을 선택하고 필요한 입력을 채운다.

## Supported Inputs

dispatcher는 아래 입력 형태를 지원해야 한다.

1. 자연어 텍스트
- 예: `"모바일 조문객 첫 진입 UX를 개선하고 review도 같이 준비해줘"`

2. Markdown 문서
- issue 본문
- spec 초안
- 회의 메모
- planning note

3. Structured sections
- `Goal`
- `In Scope`
- `Out Of Scope`
- `Success Criteria`
- `References`
- `Review Expectations`

## Primary Command Surface

권장 명령 인터페이스:

```bash
ws dispatch <project> --text "..."
ws dispatch <project> /path/to/request.md
ws dispatch <project> --text "..." --apply
ws dispatch <project> /path/to/request.md --apply
```

기본값은 `propose-only` 이다.

- `--apply` 없음:
  - 구조화 결과를 보여주고 종료
- `--apply` 있음:
  - 판단 결과에 따라 `workspace start-task ...` 또는 `workspace start-review ...`를 실제 실행

## Output Schema

dispatcher는 내부적으로 아래 구조를 만든다.

```json
{
  "project": "soullink",
  "target": "pro-web",
  "slug": "mobile-entry-ux",
  "goal": "모바일 조문객 첫 진입 UX를 개선한다.",
  "in_scope": [
    "공개 링크 진입 첫 화면 정리",
    "모바일 CTA 우선순위 재정의"
  ],
  "out_of_scope": [
    "결제 플로우 재설계",
    "백엔드 API 변경"
  ],
  "success_criteria": [
    "모바일에서 첫 행동 유도 CTA가 명확하다",
    "새 요구사항이 docs에 반영된다"
  ],
  "references": [
    "/absolute/path/to/docs/tasks/triage-status.md"
  ],
  "review_expectations": [
    "모바일 반응형 UX 리스크 확인",
    "기존 관리자 백오피스 흐름과 충돌 여부 확인"
  ],
  "should_start_review": false,
  "should_cross_verify": false,
  "doc_updates": [
    "docs/tasks/triage-status.md",
    "docs/review/design-intent.md",
    "docs/review/evaluation-criteria.md"
  ],
  "confidence": 0.82
}
```

## Required Decisions

dispatcher는 최소한 아래를 판단해야 한다.

1. project
- 현재는 명령 인자로 받는 것을 기본으로 한다
- 장기적으로는 자동 project inference 가능

2. target
- 예: `pro-web`, `backend`, `app`

3. slug
- 짧고 안정적인 kebab-case
- 기본 규칙:
  - 명사+행동 기반
  - 2~5 token

4. apply or propose
- 기본은 propose
- `--apply`가 있을 때만 실제 실행

5. task vs review
- 구현 작업이면 `start-task`
- review-only 요청이면 `start-review`

6. document updates
- `doc-update-policy` 기준으로 필요한 문서 업데이트 후보 산정

## Target Routing Rules

초기 규칙은 명시적이고 단순해야 한다.

### `pro-web`
- 관리자 웹 UI
- 반응형 웹
- 공개 링크 UX 초안
- 운영 레이어 / 추모 레이어 UI

### `app`
- Flutter 앱
- 디바이스 연동
- 앱 네이티브 UX

### `backend`
- FastAPI
- DB, auth, API, infra

## Review Routing Rules

### `should_start_review = true`
- 사용자가 review를 명시적으로 요청
- 고위험 변경
- 아키텍처/보안/API 계약 관련

### `should_cross_verify = true`
- 외부 사실이 중요한 변경
- reviewer와 qa-inspector 간 충돌 예상
- 중요한 PR 최종 확인

## Doc Update Rules

dispatcher는 실제로 문서를 수정하지 않아도, 최소한 어떤 문서를 갱신해야 하는지 계산해야 한다.

기본 규칙:

- 새 작업:
  - `docs/tasks/triage-status.md`
- 구현 전 task:
  - `docs/review/design-intent.md`
  - `docs/review/evaluation-criteria.md`
- 구조 변경 가능성:
  - `docs/architecture/*`
- 새 규칙 발견 가능성:
  - `docs/conventions/*`

## Apply Phase Behavior

`--apply` 시 dispatcher는 아래 명령 중 하나를 호출한다.

### Task path

```bash
workspace start-task <project> \
  --goal "..." \
  --in-scope "..." \
  --out-of-scope "..." \
  --done "..." \
  --reference "/abs/path" \
  --review-focus "..." \
  <target> <slug>
```

### Review path

```bash
workspace start-review <project> \
  --review-focus "..." \
  --reference "/abs/path" \
  <target> <slug>
```

## Safety Rules

- 기본은 `propose-only`
- confidence가 낮으면 자동 적용 금지
- target이 모호하면 apply 금지
- destructive action 금지
- review와 task를 동시에 자동 실행하지 않음

## Minimum Viable Orchestrator

1차 구현에서는 아래만 하면 충분하다.

1. 입력 source 읽기
2. 섹션 추출 또는 자연어 구조화
3. target/slug 제안
4. `workspace start-task` 호출 스펙 생성
5. `--apply` 시 실제 실행

## What This Does Not Do Yet

- multi-project auto inference
- OMC team orchestration 직접 호출
- 자동 PR 생성
- 자동 commit/push
- 자동 docs write-back

이것들은 2차 이후 단계에서 붙인다.
