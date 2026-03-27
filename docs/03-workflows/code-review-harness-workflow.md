---
title: Code Review Harness Workflow
description: 설계의도, 평가기준, 리뷰 에이전트, QA 교차검증을 묶어 코드리뷰 하네스를 운영하는 방법을 설명하는 문서
doc_type: workflow
status: active
source_of_truth: true
priority: 20
when_to_use:
  - 리뷰 자동화를 강화하고 싶을 때
  - 구현 전 설계의도와 평가기준을 먼저 만들고 싶을 때
  - 리뷰 에이전트와 QA 에이전트를 분리하고 싶을 때
owners:
  - ukihwa
scope:
  - cross-project
tags:
  - review
  - harness
  - qa
related:
  - ../01-principles/ai-collaboration-playbook.md
  - ../04-automation/omc-usage-guide.md
  - ../06-checklists/new-project-checklist.md
last_reviewed: 2026-03-27
---

# Code Review Harness Workflow

## Goal

리뷰를 구현 이후의 소극적 확인이 아니라, 설계의도와 평가기준을 기준으로 한 능동적 검증 파이프라인으로 운영한다.

## Core Flow

1. `design intent`를 작성한다.
2. `evaluation criteria`를 작성한다.
3. 구현 에이전트와 리뷰/QA 에이전트가 같은 기준 문서를 읽게 한다.
4. 리뷰 결과를 `.review-artifacts/{branch-or-task}/`에 저장한다.
5. 사람은 최종 승인과 우선순위 결정을 맡는다.

## Required Artifacts

- `docs/review/design-intent.md`
- `docs/review/evaluation-criteria.md`
- `docs/review/code-review.md`
- `.review-artifacts/{branch-or-task}/`

## Team Shape

- `implementer`
  - 기능 구현
  - 테스트 작성
  - 문서 반영
- `reviewer`
  - 변경 범위, 회귀 위험, 기준 문서 정합성 확인
- `qa-inspector`
  - 경계면 교차 비교
  - API 응답과 소비측 타입/훅/링크/상태 전이 비교
- `cross-verify` (optional)
  - Claude 외 다른 모델의 관점을 수집
  - 합의점, 상충점, 누락 관점을 정리

## Evidence Rules

- 프로젝트 내부 변경은 코드, 테스트, 현재 기준 문서를 우선 근거로 사용한다.
- 외부 SDK, framework, API, 보안/인증, 플랫폼 제약, 최신 기준이 걸린 변경은 공식 문서 또는 신뢰 가능한 웹 근거를 함께 확인한다.
- AI가 생성한 설명은 근거가 아니며, 필요한 경우 링크와 검증 결과를 남긴다.

## QA Focus

QA 에이전트는 단순 존재 확인보다 `boundary mismatch`를 우선 검증한다.

- API 응답 shape ↔ 프론트 훅/타입 정의
- 파일 경로 ↔ 링크/href/router 이동 경로
- 상태 전이 맵 ↔ 실제 status 업데이트 코드
- DB/API/UI 필드명 매핑

## Integration Rules

- 전체 운영체계는 기존 `CLAUDE.md + docs + tmux/OMC` 구조를 유지한다.
- 코드리뷰 하네스는 `review` 단계에 추가되는 특화 계층으로 취급한다.
- 모든 프로젝트에 강제하지 않고, 변경 복잡도와 협업 밀도에 따라 선택적으로 도입한다.

## Cross-Verify Policy

- `cross-verify`는 기본 리뷰 단계를 대체하지 않는다.
- 먼저 `reviewer`와 `qa-inspector`를 수행하고, 필요할 때만 `cross-verify`를 추가한다.
- 권장 상황:
  - 보안, 인증, API 계약, 외부 SDK 사용
  - 아키텍처 선택
  - reviewer와 qa-inspector의 판단이 갈릴 때
  - 중요한 PR의 최종 second opinion이 필요할 때
- 비권장 상황:
  - 사소한 UI 수정
  - 이미 내부 기준과 테스트로 충분히 검증된 변경
  - 비용과 시간이 더 중요할 때

## Cross-Verify Runtime Notes

- `Codex CLI` 또는 `Gemini CLI` 중 최소 하나가 설치되어 있을 때만 유의미하다.
- 현재 프로젝트 환경에서는 `Claude + Codex` 2축 검증부터 시작해도 충분하다.
- Agent Teams가 없더라도 순차 실행 fallback이 가능해야 한다.
