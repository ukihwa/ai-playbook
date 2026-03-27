---
title: Docs Metadata Schema
description: AI와 사람이 문서를 더 쉽게 선택하고 해석할 수 있도록 사용하는 frontmatter 규약
doc_type: docs
status: active
source_of_truth: true
priority: 20
when_to_use:
  - 새 문서를 만들 때
  - 문서에 frontmatter를 추가하거나 정비할 때
owners:
  - ukihwa
scope:
  - cross-project
tags:
  - docs
  - frontmatter
  - metadata
related:
  - ./docs-structure-guide.md
last_reviewed: 2026-03-27
---

# Docs Metadata Schema

## Goal

문서가 무엇을 위한 것인지, 언제 읽어야 하는지, 기준 문서인지 참고 문서인지 빠르게 판단할 수 있도록 한다.

## Recommended Frontmatter

```md
---
title: Document Title
description: 이 문서가 무엇을 설명하는지 한 줄 요약
doc_type: architecture
status: active
source_of_truth: true
priority: 20
when_to_use:
  - 언제 이 문서를 읽어야 하는지
owners:
  - frontend
scope:
  - pro-web
tags:
  - auth
  - api
related:
  - ../tasks/triage-status.md
last_reviewed: 2026-03-27
---
```

## Field Definitions

- `title`: 문서 제목
- `description`: 문서 용도 요약
- `doc_type`: 문서 분류
- `status`: 현재 상태
- `source_of_truth`: 기준 문서 여부
- `priority`: 읽기 우선순위
- `when_to_use`: 읽어야 하는 상황
- `owners`: 책임 영역
- `scope`: 적용 범위
- `tags`: 검색용 키워드
- `related`: 같이 읽을 문서
- `last_reviewed`: 마지막 검토일

## Recommended Values

### `doc_type`

- `onboarding`
- `triage`
- `convention`
- `architecture`
- `adr`
- `review`
- `reference`
- `operations`
- `checklist`

### `status`

- `active`
- `draft`
- `reference`
- `archived`
- `deprecated`

### `source_of_truth`

- `true`: 현재 기준 문서
- `false`: 참고용 또는 과거 문서

## Priority Guide

- `10`: 가장 먼저 읽는 핵심 문서
- `20`: 현재 작업 기준 문서
- `30`: 구현 보조 문서
- `40`: 참고 문서
- `60+`: 흡수 중인 원본 또는 보조 자료

## Rules

- reference 문서는 반드시 `source_of_truth: false`
- archive 문서는 현재 기준처럼 보이지 않도록 표시
- 같은 역할의 문서는 가능한 한 같은 frontmatter 규칙을 유지

