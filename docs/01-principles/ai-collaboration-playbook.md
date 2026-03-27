---
title: AI Collaboration Playbook
description: 사람과 AI가 함께 일할 때 사용하는 기본 운영 원칙과 역할 분리를 설명하는 문서
doc_type: principles
status: active
source_of_truth: true
priority: 10
when_to_use:
  - 새 프로젝트에 AI 협업 방식을 도입할 때
  - 메인 triage, worker, review 역할을 정할 때
owners:
  - ukihwa
scope:
  - cross-project
tags:
  - ai
  - collaboration
  - workflow
related:
  - ../04-automation/tmux-harness-architecture.md
  - ../06-checklists/new-project-checklist.md
last_reviewed: 2026-03-27
---

# AI Collaboration Playbook

## Core Principle

사람은 판단과 책임을 맡고, AI는 실행과 기록을 가속한다.

## Role Split

- `Main triage session`
  - 요구사항 구체화
  - 작업 분류
  - 영향 범위 판단
  - 완료 조건 정의
- `Worker session`
  - 구현
  - 테스트
  - 문서 반영
- `Review session`
  - 회귀 위험 확인
  - 누락된 테스트 확인
  - 기준 문서와 구현 정합성 확인

## Routing Rules

- 새 작업, 모호한 작업, 범위가 큰 작업은 메인 triage를 먼저 거친다.
- 이미 정의된 작업의 세부 수정은 worker에서 이어서 처리한다.
- 설계가 바뀌거나 다른 repo로 영향이 번지면 다시 메인 triage로 올린다.

## Documentation Rules

- 지속돼야 할 기준은 대화가 아니라 문서에 남긴다.
- 프로젝트 규칙은 `CLAUDE.md`와 `docs/`에 기록한다.
- reference 문서는 source of truth로 취급하지 않는다.

## Review Rules

- AI 리뷰는 사람 승인을 대체하지 않는다.
- 구현과 승인 패스를 분리한다.
- 중요 변경은 교차검증을 고려한다.
- 프로젝트 내부 사실은 코드, 테스트, 현재 문서를 우선 근거로 삼는다.
- 외부 SDK, framework, API, 보안/인증, 플랫폼 제약, 최신 사양이 걸린 변경은 공식 문서나 신뢰 가능한 웹 근거를 확인한 뒤 리뷰한다.
- AI가 말한 설명 자체는 근거가 아니며, 필요한 경우 링크와 테스트 결과로 검증한다.

## PR Rules

- 협업 프로젝트에서는 PR을 기본으로 한다.
- PR에는 변경 요약, 검증 결과, 관련 문서 링크를 남긴다.
