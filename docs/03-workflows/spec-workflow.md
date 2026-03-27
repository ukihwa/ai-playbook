---
title: Spec Workflow
description: 요구사항정의서와 기능명세서를 Git 정본으로 운영하고 AI로 초안·갱신하는 기본 워크플로
doc_type: workflow
status: active
source_of_truth: true
priority: 20
when_to_use:
  - 새 기능 요구사항을 구조화할 때
  - 구현 전에 요구사항정의서나 기능명세서를 만들 때
  - 코드 변경에 맞춰 spec 문서를 갱신해야 할 때
owners:
  - ukihwa
scope:
  - cross-project
tags:
  - spec
  - requirements
  - functional-spec
related:
  - ./doc-update-policy.md
  - ../02-docs/docs-structure-guide.md
  - ../06-checklists/new-project-checklist.md
last_reviewed: 2026-03-27
---

# Spec Workflow

코드와 함께 반복 참조되는 요구사항 문서는 Git을 정본으로 둔다.

권장 문서:

- `docs/specs/<slug>.md`
- `docs/features/<slug>.md`

## Why

- Anthropic는 프로젝트 규칙과 지속 문맥을 repo 문서로 유지하라고 권장한다.  
  Source: [Anthropic Memory](https://docs.anthropic.com/en/docs/claude-code/memory)
- GitHub는 issue forms, frontmatter, docs-as-code 구조를 공식 지원한다.  
  Sources: [Issue forms](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms), [YAML frontmatter](https://docs.github.com/en/contributing/writing-for-github-docs/using-yaml-frontmatter)

## Document Split

- `spec`: 문제, 목표, 범위, 사용자, 성공 기준
- `functional spec`: 화면, 상태 전이, API, 예외 흐름, 검증 포인트

## Workflow

1. triage 결과를 정리한다.
2. AI가 `spec` 초안을 만든다.
3. 사람이 범위와 성공 기준을 검토한다.
4. AI가 필요 시 `functional spec`으로 세분화한다.
5. 구현 중 범위나 계약이 바뀌면 관련 섹션만 갱신한다.
6. PR 전 문서와 코드 정합성을 확인한다.

## Automation Points

- 새 task 생성 시 spec 초안 생성
- `design-intent`, `evaluation-criteria`와 spec 연결
- 구조 변경 시 `functional spec` 섹션 업데이트
- 리뷰에서 문서 업데이트 누락을 finding으로 처리

## Practical Rule

- 구현자가 반복해서 읽어야 하는 문서는 Git에 둔다.
- source of truth가 아닌 외부 자료는 `docs/reference/*`로 요약만 남긴다.

