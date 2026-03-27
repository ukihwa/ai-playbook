---
title: Doc Update Policy
description: 작업 흐름에서 언제 어떤 문서를 업데이트해야 하는지 정리한 정책 문서
doc_type: workflow
status: active
source_of_truth: true
priority: 20
when_to_use:
  - 작업 중 어떤 문서를 업데이트해야 할지 판단할 때
  - 문서와 코드의 정합성을 유지하고 싶을 때
  - 새 프로젝트에 문서 운영 규칙을 적용할 때
owners:
  - ukihwa
scope:
  - cross-project
tags:
  - docs
  - workflow
  - policy
related:
  - ../02-docs/docs-structure-guide.md
  - ../02-docs/docs-metadata-schema.md
  - ./code-review-harness-workflow.md
last_reviewed: 2026-03-27
---

# Doc Update Policy

## Why This Exists

- Anthropic 공식 문서는 `CLAUDE.md`를 세션 시작 시 반복 로드되는 프로젝트 기억으로 설명하고, 프로젝트 구조, 코딩 기준, 워크플로를 여기에 두라고 권장한다. 따라서 반복적으로 필요한 기준은 대화가 아니라 문서에 반영해야 한다. [Anthropic Memory](https://code.claude.com/docs/en/memory)
- GitHub Docs는 frontmatter와 일관된 콘텐츠 구조를 통해 문서를 메타데이터와 계층으로 관리한다. 이는 문서를 코드처럼 유지·업데이트하는 docs-as-code 방식의 근거가 된다. [GitHub YAML frontmatter](https://docs.github.com/en/contributing/writing-for-github-docs/using-yaml-frontmatter), [GitHub content model](https://docs.github.com/en/contributing/style-guide-and-content-model/about-the-content-model)
- AWS ADR 가이드는 ADR를 코드 리뷰와 아키텍처 리뷰에서 참조하라고 설명한다. 즉 기술적 결정은 구현 후 기억에 맡기지 말고, 승인된 기록으로 남겨야 한다. [AWS ADR process](https://docs.aws.amazon.com/prescriptive-guidance/latest/architectural-decision-records/adr-process.html)

## Core Rule

문서는 작업이 끝난 뒤 한꺼번에 몰아서 쓰지 않는다. `기준이 바뀌는 순간` 해당 문서를 바로 갱신한다.

## Update Matrix

| Trigger | Update document | Timing |
|---|---|---|
| 새 작업을 시작하거나 범위를 재정의함 | `docs/tasks/triage-status.md` | 작업 시작 전 또는 범위 변경 즉시 |
| 구현 전 의도와 제약을 확정함 | `docs/review/design-intent.md` | 구현 시작 전 |
| 성공 기준, 검증 기준을 정함 | `docs/review/evaluation-criteria.md` | 구현 시작 전 |
| 반복 가능한 새 구현 규칙을 발견함 | `docs/conventions/code-convention.md` | 구현 중 또는 리뷰 직후 |
| 구조, 경계, 데이터 흐름이 바뀜 | `docs/architecture/overview.md` 또는 관련 `docs/architecture/*` | 구조 변경이 확정되는 즉시 |
| 외부 시스템 제약이나 레거시 비교 포인트가 바뀜 | `docs/reference/*.md` | 참조 요약이 달라질 때 |
| 기술적 결정이 승인됨 | `docs/adr/*.md` | 결정 직후, 구현 전에 우선 |
| 리뷰 기준, QA 체크 기준이 바뀜 | `docs/review/code-review.md`, `docs/review/review-checklist.md` | 리뷰에서 반복 패턴이 확인된 직후 |
| 프로젝트 온보딩 진입점이 바뀜 | `CLAUDE.md`, `docs/README.md` | 읽기 순서나 기준 문서가 바뀌는 즉시 |

## Practical Rules

- `triage-status.md`는 backlog 전체보다 `지금 활성 작업과 열린 결정사항`을 우선 유지한다.
- `design-intent.md`와 `evaluation-criteria.md`는 복잡한 변경, 다중 파일 변경, 리뷰 강화가 필요한 변경에 우선 적용한다.
- `reference` 문서는 원문을 복사하지 않고, 현재 프로젝트 관점의 요약만 유지한다.
- `ADR`는 승인 후 불변 문서로 다루고, 기존 결정을 바꿀 때는 새 ADR을 만든다.

## Minimum Expectation By Phase

### Before implementation

- `docs/tasks/triage-status.md`
- 필요 시 `docs/review/design-intent.md`
- 필요 시 `docs/review/evaluation-criteria.md`

### During implementation

- 새 규칙이 생기면 `docs/conventions/*`
- 구조가 바뀌면 `docs/architecture/*`

### Before review / PR

- 리뷰 대상 기준 문서가 최신인지 확인
- 필요한 경우 `docs/review/*`와 `docs/reference/*`를 갱신

### After review

- 반복될 만한 지적은 `docs/conventions/*` 또는 `docs/review/*`에 승격
- 확정된 기술 결정은 `docs/adr/*`에 기록

## Anti-Patterns

- 코드가 이미 바뀌었는데 문서는 다음 세션으로 미루기
- 같은 기준을 여러 문서에 중복으로 적기
- `reference` 문서가 source of truth를 덮어쓰게 두기
- 대화 안에서만 합의하고 문서에 남기지 않기
