---
title: Business Document Workflow
description: 사업계획서, 제안서, 대외 공유 문서는 Google Docs를 정본으로 두고 AI가 초안과 업데이트를 보조하는 워크플로
doc_type: workflow
status: active
source_of_truth: true
priority: 25
when_to_use:
  - 사업계획서나 제안서를 작성할 때
  - 외부 공유용 문서를 준비할 때
  - Git spec과 공유 문서를 연결해야 할 때
owners:
  - ukihwa
scope:
  - cross-project
tags:
  - business-doc
  - google-docs
  - planning
related:
  - ./spec-workflow.md
  - ../02-docs/reference-resource-policy.md
last_reviewed: 2026-03-27
---

# Business Document Workflow

사업계획서, 제안서, 발표자료 같은 사람 협업/공유 중심 문서는 Google Docs를 정본으로 두고 AI는 초안과 섹션 업데이트를 보조한다.

## Why

- Google Docs는 버전 히스토리와 공동 편집이 강하다.  
  Source: [Google Docs version history](https://support.google.com/docs/answer/190843?hl=en)
- Drive는 shortcut 기반으로 원본 하나를 여러 맥락에 연결하기 좋다.  
  Source: [Drive shortcuts](https://support.google.com/drive/answer/9700156?hl=en)

## Recommended Split

- Git:
  - spec
  - functional spec
  - ADR
  - reference summary
- Google Docs:
  - 사업계획서
  - 제안서
  - 외부 공유용 설명 문서
  - 발표자료 초안

## Workflow

1. Git의 `spec`과 `reference`를 기준 입력으로 모은다.
2. AI가 Google Docs용 개요 또는 섹션 초안을 만든다.
3. 사람이 Google Docs에서 편집과 코멘트를 진행한다.
4. 구현에 영향을 주는 핵심 가정만 다시 Git 문서로 승격한다.

## Automation Points

- 기획 PDF, 회의 메모, spec을 묶어 초안 생성
- 기존 사업계획서 문서에 맞춰 특정 섹션만 업데이트
- 발표용 요약/1페이지 버전 자동 생성
- Git 정본 링크와 Drive 문서를 상호 연결

## Practical Rule

- 공유 문서의 정본을 Git과 Drive 양쪽에 중복 유지하지 않는다.
- 구현 기준은 Git에, 공유용 정본은 Google Docs에 둔다.

