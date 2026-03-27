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

## Output Expectations

- 요약보다 finding 중심으로 리뷰합니다.
- 동작, 품질, 유지보수 리스크를 우선합니다.

