---
title: Google Drive Migration Plan
description: 개인 GoogleDrive_Mirror를 생활, 업무, 지식 시스템, 자산, 보관 구조로 재정리하기 위한 실행 계획
doc_type: operations
status: active
source_of_truth: true
priority: 20
when_to_use:
  - 개인 Google Drive 구조를 재설계할 때
  - 상위 폴더를 정리하면서 Ideaverse 볼트를 보존해야 할 때
owners:
  - ukihwa
scope:
  - personal-drive
tags:
  - google-drive
  - migration
  - ideaverse
related: []
last_reviewed: 2026-03-27
---

# Google Drive Migration Plan

이 문서는 개인 Google Drive 미러를 재정리하기 위한 실행 계획입니다.

## Goals

- 일상생활, 업무, 지식 시스템, 자산, 보관 영역을 분리한다.
- Google Drive 상위 구조만 재설계한다.
- Ideaverse 기반 Obsidian vault 내부 구조는 변경하지 않는다.
- 한 번에 대규모 변경하지 않고 영역별로 순차 이동한다.

## Non-Goals

- Ideaverse vault 내부 폴더 재설계
- `.obsidian`, `.claude`, `.omc`, `CLAUDE.md` 같은 vault 내부 운영 파일 수정
- 회사 Google Drive 구조 설계

## Target Structure

```text
GoogleDrive_Mirror/
  00_Inbox
  01_Admin_Life
    Family
    Health
    ID_Docs
    Certificates
  02_Work
    00_Inbox
    01_Projects
    02_Reference
    03_Resume
    04_Sharing
    05_Assets
  03_Knowledge
    Vaults
      Ideaverse
    Learning_Materials
    Resources
  05_Assets
    Images
    Slides
    PDFs
    Screenshots
    Branding
  08_Archive
    2025
    Completed_Projects
```

## Design Rules

- `00_Inbox`는 분류 전 임시 수집함이다.
- `01_Admin_Life`는 가족, 건강, 증명서, 생활 행정 문서를 담는다.
- `02_Work`는 회사 업무 문서를 담는다.
- `03_Knowledge`는 지식 시스템과 학습 자료를 담는다.
- `05_Assets`는 프로젝트를 가로지르는 공용 자산을 담는다.
- `08_Archive`는 오래된 문서와 종료된 프로젝트를 보관한다.

## Critical Constraint: Ideaverse Preservation

`03_Study/Notes`는 일반 폴더가 아니라 Ideaverse 기반 Obsidian vault다.

따라서 다음 항목은 **통째로 유지**한다.

- `Atlas`
- `Calendar`
- `Efforts`
- 기타 Ideaverse 내부 폴더
- `.obsidian`
- `.claude`
- `.omc`
- `CLAUDE.md`

허용되는 변경은 오직 상위 경로 이동뿐이다.

### Allowed

- `03_Study/Notes` → `03_Knowledge/Vaults/Ideaverse`

### Not Allowed

- `Notes` 내부 폴더명 변경
- `Atlas`, `Calendar`, `Efforts` 재배치
- `.obsidian` 내부 파일 정리

## Migration Phases

### Phase 1: Create New Containers

먼저 아래 폴더를 만든다.

- `00_Inbox`
- `01_Admin_Life`
- `02_Work/00_Inbox`
- `02_Work/01_Projects`
- `02_Work/02_Reference`
- `02_Work/03_Resume`
- `02_Work/04_Sharing`
- `02_Work/05_Assets`
- `03_Knowledge/Vaults`
- `03_Knowledge/Learning_Materials`
- `03_Knowledge/Resources`
- `05_Assets/Images`
- `05_Assets/Slides`
- `05_Assets/PDFs`
- `05_Assets/Screenshots`
- `05_Assets/Branding`
- `08_Archive/2025`
- `08_Archive/Completed_Projects`

### Phase 2: Personal → Admin_Life

현재:

- `01_Personal/Certificates`
- `01_Personal/Family`
- `01_Personal/Health`
- `01_Personal/ID_Docs`

이동:

- `01_Personal/Certificates` → `01_Admin_Life/Certificates`
- `01_Personal/Family` → `01_Admin_Life/Family`
- `01_Personal/Health` → `01_Admin_Life/Health`
- `01_Personal/ID_Docs` → `01_Admin_Life/ID_Docs`

### Phase 3: Work Structure Cleanup

현재:

- `02_Work/Projects`
- `02_Work/Reference`
- `02_Work/Resume`
- `02_Work` 루트의 이미지 파일들

이동:

- `Projects` → `02_Work/01_Projects`
- `Reference` → `02_Work/02_Reference`
- `Resume` → `02_Work/03_Resume`

루트 PNG 이동:

- `dribbble-*` → `02_Work/05_Assets/Design_Refs` 또는 `02_Work/05_Assets/Slides`
- `plastly-slide*` → `02_Work/05_Assets/Slides`

### Phase 4: Study → Knowledge

현재:

- `03_Study/Notes`
- `03_Study/Learning_Materials`
- `03_Study/Resources`

이동:

- `03_Study/Notes` → `03_Knowledge/Vaults/Ideaverse`
- `03_Study/Learning_Materials` → `03_Knowledge/Learning_Materials`
- `03_Study/Resources` → `03_Knowledge/Resources`

이 단계에서는 vault 내부를 열어서 정리하지 않는다.

### Phase 5: Archive Renaming

현재:

- `04_Archive/2025_Old`
- `04_Archive/Completed_Projects`

이동:

- `2025_Old` → `08_Archive/2025`
- `Completed_Projects` → `08_Archive/Completed_Projects`

### Phase 6: Root Cleanup

루트 단일 파일은 성격에 따라 이동한다.

- 개인 행정/생활 문서 → `01_Admin_Life`
- 업무 문서 → `02_Work`
- 학습/참고 문서 → `03_Knowledge/Resources`
- 원본 PDF/이미지 → `05_Assets/PDFs` 또는 `05_Assets/Images`
- 애매한 경우 → `00_Inbox`

## Validation Checklist

각 단계 후 아래를 확인한다.

- 이동 전후 파일 수가 크게 달라지지 않았는가
- PDF, PNG, 문서가 누락되지 않았는가
- `02_Work` 루트가 단순해졌는가
- `03_Knowledge/Vaults/Ideaverse`가 정상 열리는가
- `.obsidian`, `.claude`, `.omc`가 그대로 유지되는가
- 캘린더/링크/대시보드가 깨지지 않는가

## Safe Execution Rules

- 하루에 하나의 영역만 이동한다.
- 이동 후 바로 검증한다.
- 문제가 생기면 다음 영역으로 넘어가지 않는다.
- vault 관련 이동은 항상 마지막에 검증을 가장 많이 한다.

## Suggested Timeline

### Day 1

- Phase 1
- Phase 2

### Day 2

- Phase 3

### Day 3

- Phase 4

### Day 4

- Phase 5
- Phase 6

## Notes

- 루트의 `.claude`, `.omc`는 당장 제거하지 않는다.
- 먼저 새 상위 구조를 안정화한 후, 해당 숨김 폴더가 실제로 필요한지 별도로 판단한다.
- 회사 Drive는 웹 중심으로 사용하고, 이 문서는 개인 Drive에만 적용한다.
