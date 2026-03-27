---
title: Tmux Harness Architecture
description: AI 협업 자동화를 위한 tmux 세션, window, worker, review 구조를 정의하는 문서
doc_type: automation
status: active
source_of_truth: true
priority: 10
when_to_use:
  - tmux 기반 AI 협업 환경을 설계할 때
  - 새 프로젝트의 세션 구조를 정할 때
owners:
  - ukihwa
scope:
  - cross-project
tags:
  - tmux
  - harness
  - automation
related:
  - ../01-principles/ai-collaboration-playbook.md
  - ../06-checklists/new-project-checklist.md
last_reviewed: 2026-03-27
---

# Tmux Harness Architecture

## Goal

메인 triage, runtime, 구현, 리뷰를 분리해 멀티세션 협업을 안정적으로 운영한다.

## Session Model

- 제품 또는 프로젝트 단위로 tmux session 1개
- 세션/경로 정보는 `config/*.env`에서 주입한다

## Recommended Windows

- `triage`
  - 요구사항 정리
  - 작업 분류
  - handoff 준비
- `fe-run` / `be-run` / `app-run`
  - dev server
  - logs
  - build/test/watch
- `claude-fe` / `claude-be` / `claude-app`
  - 구현 세션
- `review-*`
  - 리뷰 전용 세션

## Worktree Rule

- task 단위로 worktree를 생성한다
- 구현 세션은 가능하면 task 전용 worktree에서 실행한다
- run window는 고정 repo 또는 대표 worktree를 기준으로 사용한다
- 기본 브랜치 규칙은 `codex/<target>/<slug>`를 사용한다

## Handoff Rule

메인 triage는 worker에 아래 정보를 넘긴다.

- 목표
- 범위
- 제외 범위
- 완료 조건
- 관련 문서
- 리뷰 포인트

## Review Rule

- 구현과 리뷰는 분리한다
- 리뷰는 finding 중심으로 진행한다
- 중요 변경은 교차검증을 고려한다
- handoff는 worker가 셸 pane인지 AI 프롬프트 pane인지에 따라 안전 모드를 구분한다

## Rollover Rule

- 메인 세션이 무거워지면 `/compact`
- 그래도 길어지면 새 메인 세션으로 넘긴다
- 상태 복구는 `CLAUDE.md`, `triage-status`, `backlog` 기준으로 한다

## Baseline Commands

- `soullink up`
- `soullink up-bootstrap`
- `soullink status`
- `soullink start-task ...`
- `soullink task-from-spec ...`
- `soullink start-review ...`
- `scripts/tmux/init-product.sh --config config/<product>.env`
- `scripts/tmux/init-product.sh --config config/<product>.env --bootstrap-defaults`
- `scripts/tmux/bootstrap-agent.sh --config config/<product>.env --agent claude <window>`
- `scripts/tmux/new-task.sh --config config/<product>.env --agent claude <target> <slug>`
- `scripts/tmux/start-task.sh --config config/<product>.env --agent codex --mode prompt <target> <slug>`
- `scripts/tmux/start-task-from-spec.sh --config config/<product>.env --agent codex <target> <slug> /path/to/spec.md`
- `scripts/tmux/handoff.sh --config config/<product>.env <window> <ticket-file>`
- `scripts/tmux/review-task.sh --config config/<product>.env --agent codex <target> <slug>`
- `scripts/tmux/start-review.sh --config config/<product>.env --agent gemini --mode prompt <target> <slug>`
- `scripts/tmux/status.sh --config config/<product>.env`
- `scripts/tmux/cleanup-task.sh --config config/<product>.env --delete-worktree <target> <slug>`
