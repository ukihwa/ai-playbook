---
title: Git Workflow
description: AI와 사람이 프로젝트를 진행할 때 따라야 하는 브랜치, 커밋, PR, 머지 규칙
doc_type: workflow
status: active
source_of_truth: true
priority: 20
when_to_use:
  - 새 브랜치를 만들 때
  - 커밋 메시지를 작성할 때
  - PR 제목과 설명을 작성할 때
owners:
  - ukihwa
scope:
  - cross-project
tags:
  - git
  - commit
  - pr
  - workflow
related:
  - ../01-principles/ai-collaboration-playbook.md
  - ../06-checklists/new-project-checklist.md
last_reviewed: 2026-03-27
---

# Git Workflow

## Goal

AI와 사람이 함께 작업해도 커밋 히스토리와 PR 로그가 읽기 쉽고, 나중에 추적 가능한 상태를 유지한다.

## Core Rules

- 브랜치는 짧고 명확하게 만든다.
- 커밋 메시지는 타입이 보이게 쓴다.
- PR 제목은 최종 변경 로그처럼 관리한다.
- 협업 프로젝트에서는 squash merge를 기본으로 본다.
- AI가 만든 커밋 메시지와 PR 제목도 사람이 검토한다.

## Branch Naming

브랜치 이름은 소문자, 하이픈, 슬래시 중심으로 단순하게 유지한다.

### Recommended Format

```text
<type>/<short-description>
```

### Examples

- `feat/auth-refresh`
- `fix/login-toast`
- `docs/ai-playbook`
- `refactor/table-toolbar`
- `chore/omc-update`

## Commit Message Convention

기본 형식:

```text
<type>: <summary>
```

### Recommended Types

- `feat`: 사용자 기능 추가
- `fix`: 버그 수정
- `docs`: 문서 추가/수정
- `refactor`: 동작 변화 없는 구조 개선
- `test`: 테스트 추가/수정
- `chore`: 설정, 의존성, 보조 작업
- `style`: 포맷/스타일 수정
- `perf`: 성능 개선

### Examples

- `feat: add kiosk registration filter`
- `fix: handle refresh token retry race`
- `docs: add onboarding templates`
- `refactor: simplify mobile card layout`
- `test: add auth guard coverage`
- `chore: update omc setup guidance`

## Commit Writing Rules For AI

- AI는 가능한 한 작업 단위가 드러나는 커밋 메시지를 사용한다.
- vague한 메시지는 피한다.
  - 피할 것: `update files`, `fix stuff`, `changes`
- 하나의 커밋에는 하나의 의도를 담는다.
- 의미 없는 WIP 커밋은 공유 브랜치에 남기지 않는 것을 기본으로 한다.

## PR Title Convention

PR 제목도 커밋과 비슷한 타입 기반 형식을 권장한다.

```text
<type>: <summary>
```

### Examples

- `feat: add pro-web onboarding docs`
- `fix: preserve session state during token refresh`
- `docs: define ai collaboration playbook`

## PR Description Minimum

- 변경 목적
- 주요 변경 내용
- 검증 방법
- 관련 문서 또는 reference
- 남은 위험/후속 작업

## Merge Strategy

- 협업 프로젝트에서는 `squash merge`를 기본으로 본다.
- feature 브랜치의 잔커밋은 PR 단위로 정리한다.
- 최종 main 히스토리는 읽기 쉬운 단위로 남긴다.

## Human Review Rule

- AI가 만든 브랜치 이름, 커밋 메시지, PR 제목은 사람이 최종 확인한다.
- 사람이 의미를 설명할 수 없는 메시지는 머지 전에 수정한다.

## Suggested Default For AI Agents

앞으로 AI가 커밋을 만들 때 우선 아래 규칙을 따른다.

1. 브랜치 이름은 `<type>/<short-description>`
2. 커밋 메시지는 `<type>: <summary>`
3. docs 변경은 `docs:`
4. 설정/자동화는 `chore:`
5. 기능 추가는 `feat:`
6. 버그 수정은 `fix:`

