---
title: Reference Resource Policy
description: 레퍼런스 리소스를 Git 저장소와 Google Drive 중 어디에 두어야 하는지 판단하는 기준을 정리한 문서
doc_type: convention
status: active
source_of_truth: true
priority: 30
when_to_use:
  - 레퍼런스 문서나 외부 자료를 어디에 저장할지 결정할 때
  - 프로젝트 온보딩 자료를 정리할 때
owners:
  - ukihwa
scope:
  - cross-project
tags:
  - reference
  - docs
  - storage
related:
  - ./docs-structure-guide.md
  - ../operations/google-drive-operating-rules.md
last_reviewed: 2026-03-27
---

# Reference Resource Policy

## Default Rule

정본으로 계속 읽히고, AI와 사람이 반복해서 참고해야 하는 텍스트 기반 레퍼런스는 Git 저장소에 둔다.

## Store In Git

- 프로젝트 기준 문서
- 요약된 reference 문서
- 구현/리뷰 시 반복적으로 읽는 텍스트 자료
- 에이전트 정의, 스킬, 템플릿
- diff와 리뷰 이력이 중요한 자료

## Store In Google Drive

- 원본 슬라이드, 이미지, PDF, 스캔본
- 외부 공유용 자료
- 회의 산출물, 초안, 발표자료
- 용량이 크거나 버전 diff 가치가 낮은 자료

## Recommended Pattern

- 원문이 크거나 외부 자료인 경우 Drive에 저장한다.
- 프로젝트에서 실제로 쓰는 요약과 해석은 Git의 `docs/reference/`에 정리한다.
- Git 문서에는 원문 위치를 링크나 경로로 남기되, 원문 자체를 복제하지 않는다.

## Anti-Patterns

- 같은 텍스트 기준 문서를 Git과 Drive 양쪽에서 동시에 정본처럼 운영하지 않는다.
- 프로젝트 기준 문서를 Drive에만 두지 않는다.
- AI가 반복해서 읽어야 하는 핵심 reference를 Drive 링크만으로 처리하지 않는다.
