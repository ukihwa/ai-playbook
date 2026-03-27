---
title: Code Review Guide
description: 변경사항 리뷰 시 우선 확인할 기준과 질문을 정리한 문서
doc_type: review
status: active
source_of_truth: true
priority: 30
when_to_use:
  - 구현 후 리뷰를 준비할 때
  - AI 또는 사람이 변경사항을 검토할 때
owners:
  - team
scope:
  - project
tags:
  - review
  - quality
related:
  - ./review-checklist.md
  - ../conventions/code-convention.md
  - ../tasks/triage-status.md
last_reviewed: 2026-03-27
---

# Code Review Guide

## Review Priorities

1. 현재 작업이 triage 범위 안에 있는가
2. 기존 패턴과 충돌하지 않는가
3. reference를 source of truth처럼 사용하지 않았는가
4. 회귀 위험이 없는가
5. 필요한 테스트나 검증 포인트가 있는가

## Evidence Rules

- 프로젝트 내부 변경은 코드, 테스트, 현재 기준 문서를 우선 근거로 사용한다.
- 외부 SDK, framework, API, 보안/인증, 플랫폼 제약, 최신 기준이 걸린 변경은 공식 문서 또는 신뢰 가능한 웹 근거를 확인한다.
- AI의 설명만으로 승인하지 않고, 필요한 경우 링크와 재현 가능한 검증 결과를 남긴다.

## Output Expectations

- 요약보다 finding 중심으로 리뷰합니다.
- 동작, 품질, 유지보수 리스크를 우선합니다.
