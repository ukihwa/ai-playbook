---
title: Docs Structure Guide
description: 프로젝트 문서 구조와 각 문서의 역할, 읽기 순서를 정의하는 가이드
doc_type: docs
status: active
source_of_truth: true
priority: 10
when_to_use:
  - 새 프로젝트의 docs 구조를 잡을 때
  - 어떤 문서를 어디에 둘지 판단할 때
owners:
  - ukihwa
scope:
  - cross-project
tags:
  - docs
  - structure
  - source-of-truth
related:
  - ./docs-metadata-schema.md
  - ../01-principles/ai-collaboration-playbook.md
last_reviewed: 2026-03-27
---

# Docs Structure Guide

## Goal

사람과 AI가 모두 빠르게 읽고, 현재 기준 문서와 참고 문서를 명확히 구분할 수 있는 구조를 만든다.

## Recommended Structure

```text
docs/
  README.md
  architecture/
  conventions/
  adr/
  tasks/
  review/
  reference/
  archive/
```

## Document Roles

- `CLAUDE.md`
  - 상위 운영 지침
  - 읽기 순서
  - source of truth 규칙
- `docs/README.md`
  - 문서 인덱스
  - 진입점
- `docs/tasks/triage-status.md`
  - 현재 작업 상태
  - 우선순위
  - 열린 질문
- `docs/conventions/*`
  - 코드/디자인/프로젝트 규칙
- `docs/architecture/*`
  - 구조와 도메인 설계
- `docs/adr/*`
  - 기술적 의사결정 기록
- `docs/review/*`
  - 리뷰 기준
- `docs/reference/*`
  - 읽기 전용 참고 자료
- `docs/archive/*`
  - 더 이상 기준이 아닌 과거 문서

## Read Order

1. `CLAUDE.md`
2. `docs/README.md`
3. `docs/tasks/triage-status.md`
4. 관련 `docs/conventions/*`
5. 관련 `docs/architecture/*`
6. 관련 `docs/adr/*`
7. 필요 시 `docs/reference/*`

## Source Of Truth Rules

- 현재 기준 문서는 `source_of_truth: true`
- reference와 archive는 `source_of_truth: false`
- 오래된 원본 문서는 새 구조로 흡수 중이라는 안내를 넣는다

