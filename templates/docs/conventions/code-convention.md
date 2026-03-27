---
title: Code Convention
description: 이 저장소에서 구현 시 따라야 하는 코드 작성 기준의 시작 문서
doc_type: convention
status: active
source_of_truth: true
priority: 20
when_to_use:
  - 새 코드를 작성하거나 수정할 때
  - 리뷰 전에 구현 규칙을 확인할 때
owners:
  - team
scope:
  - project
tags:
  - code-style
  - convention
related:
  - ../review/code-review.md
  - ../architecture/overview.md
last_reviewed: 2026-03-27
---

# Code Convention

## Goal

이 문서는 현재 저장소에서 반복적으로 지켜야 하는 구현 규칙을 담습니다.

## Recommended Sections

- UI or component rules
- naming rules
- state management rules
- test expectations
- review expectations

## Rules

- 기존 패턴을 먼저 따릅니다.
- 새 패턴을 도입할 때는 이유와 적용 범위를 문서화합니다.
- reference 구현을 그대로 복제하지 말고, 현재 저장소 구조에 맞게 재해석합니다.

