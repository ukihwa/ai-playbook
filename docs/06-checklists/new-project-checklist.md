---
title: New Project Checklist
description: 새 프로젝트에 AI 협업 구조를 적용할 때 따라가는 기본 체크리스트
doc_type: checklist
status: active
source_of_truth: true
priority: 10
when_to_use:
  - 새 프로젝트를 시작할 때
  - 기존 프로젝트에 AI 협업 구조를 도입할 때
owners:
  - ukihwa
scope:
  - cross-project
tags:
  - checklist
  - onboarding
  - project
related:
  - ../02-docs/docs-structure-guide.md
  - ../03-workflows/doc-update-policy.md
  - ../03-workflows/spec-workflow.md
  - ../04-automation/skill-evaluation-policy.md
  - ../04-automation/tmux-harness-architecture.md
last_reviewed: 2026-03-27
---

# New Project Checklist

## Setup

- [ ] 프로젝트 루트 확인
- [ ] `OMC`를 로컬 프로젝트 기준으로 설정
- [ ] `CLAUDE.md` 생성 또는 정리

## Docs

- [ ] `docs/README.md` 생성
- [ ] `docs/tasks/triage-status.md` 생성
- [ ] `docs/conventions/code-convention.md` 생성
- [ ] `docs/architecture/overview.md` 생성
- [ ] `docs/review/` 생성
- [ ] 필요 시 `docs/review/design-intent.md` 생성
- [ ] 필요 시 `docs/review/evaluation-criteria.md` 생성
- [ ] `docs/reference/` 생성
- [ ] 필요 시 `docs/adr/` 생성
- [ ] 필요 시 `docs/specs/` 생성
- [ ] 필요 시 `docs/features/` 생성

## Metadata

- [ ] 핵심 문서에 frontmatter 적용
- [ ] `source_of_truth`와 `reference` 문서를 구분
- [ ] 읽기 순서를 `CLAUDE.md`에 명시

## Sessions

- [ ] 메인 triage 세션 구조 결정
- [ ] runtime window 구조 결정
- [ ] worker/review 세션 구조 결정
- [ ] worktree 전략 결정

## Workflow

- [ ] triage 규칙 정의
- [ ] 구현 규칙 정의
- [ ] 리뷰 규칙 정의
- [ ] worker handoff 템플릿과 전달 방식 정의
- [ ] spec과 functional spec 정본 위치 정의
- [ ] business docs의 Google Docs 정본 위치 정의
- [ ] PR 최소 규칙 정의
- [ ] 복잡한 변경이면 code review harness 도입 여부 결정
- [ ] review artifacts 저장 경로(`.review-artifacts/`) 결정

## Agents

- [ ] 필요 시 `.claude/agents/reviewer.md` 생성
- [ ] 필요 시 `.claude/agents/qa-inspector.md` 생성
- [ ] 필요 시 `.claude/skills/review-orchestrator/` 생성
- [ ] 필요 시 `cross-verify`를 선택적 검증 스킬로 도입할지 판단

## Skill Governance

- [ ] 새 skill은 `experimental` 상태로 시작
- [ ] 도입 전 evaluation 기준 정의
- [ ] 필요 시 A/B 테스트 설계
- [ ] 채택 전 false positive / 누락 사례 점검
- [ ] project-scoped와 user-scoped 중 어디에 둘지 결정
