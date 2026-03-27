---
title: OMC Usage Guide
description: Claude Code와 OMC를 함께 사용할 때 역할 분리와 운영 원칙을 정리한 문서
doc_type: automation
status: active
source_of_truth: true
priority: 20
when_to_use:
  - 새 프로젝트에서 OMC를 설정할 때
  - OMC와 CLAUDE.md의 역할이 헷갈릴 때
owners:
  - ukihwa
scope:
  - cross-project
tags:
  - omc
  - claude
  - automation
related:
  - ./tmux-harness-architecture.md
  - ../01-principles/ai-collaboration-playbook.md
last_reviewed: 2026-03-27
---

# OMC Usage Guide

## Core Principle

OMC는 오케스트레이션 레이어이고, 프로젝트 기준 문서는 `CLAUDE.md`와 `docs/`에 둔다.

## Recommended Split

- `CLAUDE.md`
  - 프로젝트 운영 규칙
  - 읽기 순서
  - source of truth
- `.claude/commands` 또는 skills
  - 반복 작업 진입점
- `.omc`
  - 팀 오케스트레이션
  - plans
  - project memory
  - session state

## Setup Rules

- 기본적으로 `/omc-setup`은 `Local`을 사용한다.
- 글로벌 설정은 아주 얇은 공통 습관만 담을 때만 고려한다.
- 프로젝트별 문맥은 각 프로젝트 안에서 유지한다.

## Team Rules

- triage는 메인 Claude 세션에서 수행한다.
- 구현은 worker 세션에서 수행한다.
- 리뷰는 별도 세션으로 분리한다.
- 기본 teammate는 `executor`로 시작하고, 필요 시 reviewer/architect를 추가한다.
- `cross-verify` 같은 멀티모델 비교 스킬은 상시 기본값이 아니라 선택적 검증 단계로 둔다.

## Optional Cross-Verification

- `cross-verify`는 reviewer/qa 이후의 second opinion 용도로 붙인다.
- `Codex CLI`가 설치되어 있으면 `Claude + Codex` 2축 검증부터 도입할 수 있다.
- `Gemini CLI`까지 설치된 경우에만 3모델 교차검증을 고려한다.
- Team orchestration과 충돌하지 않도록, 무조건 병렬 실행을 강제하지 않고 순차 fallback을 허용한다.

## Update Rules

- OMC 플러그인 업데이트 후에는 설정과 `CLAUDE.md` 반영 상태를 다시 확인한다.
- 프로젝트별 `CLAUDE.md`, `docs`, `.omc/project-memory.json`이 현재 구조와 맞는지 점검한다.

## Cautions

- OMC의 범용 블록을 프로젝트 규칙의 전부로 착각하지 않는다.
- project memory 자동 스캔 결과를 source of truth로 쓰지 않는다.
- reference 문서와 운영 문서를 섞지 않는다.
