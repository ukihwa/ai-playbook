---
title: Google Drive Operating Rules
description: 개인 Google Drive를 장기적으로 안정적으로 운영하기 위한 구조와 사용 원칙
doc_type: operations
status: active
source_of_truth: true
priority: 20
when_to_use:
  - 개인 Google Drive의 새 폴더 구조를 운영할 때
  - 새 파일을 어디에 둘지 판단할 때
owners:
  - ukihwa
scope:
  - personal-drive
tags:
  - google-drive
  - organization
  - operations
related:
  - ./google-drive-migration-plan.md
  - ../checklists/google-drive-migration-checklist.md
last_reviewed: 2026-03-27
---

# Google Drive Operating Rules

이 문서는 개인 Google Drive를 장기적으로 운영할 때 따르는 기준 문서입니다.

## Core Principle

Drive는 `실행 기준 저장소`가 아니라 `개인 문서와 자료의 운영 공간`이다.

- 실행 기준 문서와 자동화 규칙은 Git 저장소를 우선한다.
- Google Drive는 초안, 참고자료, 생활 문서, 업무 문서, 자산, 지식 시스템 보관에 집중한다.

## Top-Level Areas

최상위는 아래 역할만 가진다.

- `00_Inbox`: 미분류 수집함
- `01_Admin_Life`: 가족, 건강, 신분/행정 문서
- `02_Work`: 회사 업무 문서
- `03_Knowledge`: Obsidian vault와 학습 자료
- `05_Assets`: 프로젝트를 가로지르는 공용 자산
- `08_Archive`: 오래된 자료 보관

## Placement Rules

새 파일이 생기면 아래 기준으로 둔다.

- 생활 증빙, 가족, 건강, 공문서 → `01_Admin_Life`
- 회사 프로젝트 문서, 회의 자료, 이력서, 제안서 → `02_Work`
- 학습 자료, 노트 시스템, 지식 축적 자료 → `03_Knowledge`
- 이미지, 스크린샷, 슬라이드, PDF 원본 → `05_Assets`
- 애매하거나 바로 정리할 수 없으면 → `00_Inbox`

## Inbox Rules

- `00_Inbox`는 임시함이다.
- 주 1회 이상 비운다.
- 2주 이상 머무는 파일이 생기지 않게 한다.

## Work Rules

- `02_Work` 루트에는 파일을 직접 쌓지 않는다.
- 프로젝트 문서는 `01_Projects`
- 참고 자료는 `02_Reference`
- 이력서 관련은 `03_Resume`
- 외부 전달 자료는 `04_Sharing`
- 업무 이미지/슬라이드는 `05_Assets`

## Knowledge Rules

- Obsidian vault는 `03_Knowledge/Vaults/Ideaverse`에 둔다.
- Ideaverse 내부 구조는 Drive 정리를 이유로 수정하지 않는다.
- 학습 자료와 일반 참고 자료는 vault 밖에 둔다.

## Vault Preservation Rules

다음 항목은 vault의 일부로 간주하고 보존한다.

- `Atlas`
- `Calendar`
- `Efforts`
- `.obsidian`
- `.claude`
- `.omc`
- `CLAUDE.md`

허용되는 작업은 상위 경로 이동뿐이다.

## Asset Rules

- 업무 전용 자산은 `02_Work/05_Assets`
- 개인 공용 자산은 `05_Assets`
- 같은 파일을 여러 폴더에 복사하지 않고, 필요하면 shortcut 개념으로만 관리한다

## Archive Rules

- 더 이상 활발히 쓰지 않는 자료만 `08_Archive`로 보낸다.
- archive에 들어간 자료는 다시 활성 구조로 올리지 않는 것을 기본으로 한다.
- 연도별 폴더 또는 완료 프로젝트 단위로만 단순하게 보관한다.

## Tooling Files

- Drive 루트의 `.claude`, `.omc`는 당장 제거하지 않는다.
- 다만 Drive 문서 운영과 도구 상태 파일을 혼동하지 않도록 별도 판단 대상으로 둔다.
- 향후 필요성이 확인되면 유지, 아니면 루트에서 분리한다.

## Search And Retrieval

- 깊은 폴더 구조보다 얕은 구조를 유지한다.
- 자주 찾는 파일은 Starred와 검색을 우선 활용한다.
- 폴더를 늘리기 전에 이름, 위치, 성격이 명확한지 먼저 확인한다.

## Review Cadence

- 주 1회: `00_Inbox`
- 월 1회: `02_Work` 루트 정리
- 월 1회: `05_Assets` 정리
- 분기 1회: `08_Archive` 점검
