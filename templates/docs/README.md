---
title: Documentation Index
description: 이 저장소의 문서 읽기 순서와 source of truth를 설명하는 진입 문서
doc_type: onboarding
status: active
source_of_truth: true
priority: 10
when_to_use:
  - 이 저장소에서 작업을 시작할 때
  - 어떤 문서를 먼저 읽어야 할지 판단할 때
owners:
  - team
scope:
  - project
tags:
  - docs
  - onboarding
  - index
related:
  - ../CLAUDE.md
  - ./tasks/triage-status.md
last_reviewed: 2026-03-27
---

# Documentation Index

## Read First

작업 시작 시 아래 순서로 읽습니다.

1. `docs/tasks/triage-status.md`
2. `docs/conventions/code-convention.md`
3. `docs/architecture/overview.md`
4. 관련 `docs/architecture/*`
5. 관련 `docs/adr/*`
6. 필요할 때만 `docs/reference/*`

## Source Of Truth

- 현재 구현 기준: `docs/conventions/*`, `docs/architecture/*`
- 현재 작업 상태: `docs/tasks/triage-status.md`
- 의사결정 기록: `docs/adr/*`
- 참고 전용: `docs/reference/*`

## Notes

- reference 문서는 비교와 제약 확인 용도다.
- 오래된 원본 문서는 새 구조로 흡수 중이라는 안내를 남긴다.
- 커밋과 PR 작성 시에는 프로젝트의 git workflow 문서를 함께 따른다.
