---
title: Triage Intake Policy
description: triage 세션에서 일반 자연어 요청을 언제 intake로 넘기고 언제 일반 응답으로 처리할지 정의한다
doc_type: workflow
status: active
source_of_truth: true
priority: 18
when_to_use:
  - triage 세션의 기본 행동을 설계할 때
  - 자연어 요청을 dispatch ticket으로 만들지 판단할 때
  - 새 프로젝트에 triage 규칙을 적용할 때
owners:
  - ukihwa
scope:
  - cross-project
tags:
  - triage
  - intake
  - dispatch
related:
  - ./doc-update-policy.md
  - ../04-automation/orchestrator-dispatch-spec.md
last_reviewed: 2026-03-28
---

# Triage Intake Policy

## Goal

triage 세션에서 사용자의 일반 자연어 입력을 받았을 때, 이를 자동화 가능한 개발 요청으로 볼지 아니면 그냥 대화/설명으로 응답할지를 일관되게 판단한다.

## Why This Exists

- Anthropic는 `CLAUDE.md`를 반복 로드되는 프로젝트 메모리로 두고, slash command를 반복 워크플로 캡슐화 수단으로 제공한다. 따라서 triage 기본 행동은 대화에만 두지 말고 문서와 command로 명시해야 한다. [Anthropic Memory](https://code.claude.com/docs/en/memory), [Anthropic Slash Commands](https://docs.anthropic.com/en/docs/claude-code/slash-commands)
- 실무 자동화는 보통 단일 명령 진입점과 승인 게이트를 둔다. 따라서 triage도 “모든 입력을 실행”하지 말고, actionable 입력만 `intake`로 넘기는 것이 안정적이다.

## Default Rule

triage 세션에서 plain natural-language 입력을 받으면 먼저 아래 둘 중 하나로 분류한다.

- `actionable`
  - 구현, 수정, 정리, 개선, 검토, 리뷰, 조사, 설계처럼 실제 작업 생성이 필요한 요청
- `ignore`
  - 인사, 감사, 잡담, 실행 지시가 없는 일반 질문

`actionable`이면 기본 내부 동작은 아래다.

```bash
ws intake <project> --text "<original request>"
```

## Actionable Examples

- `로그인 버튼 문구를 더 명확하게 정리해줘`
- `주문 취소 권한 흐름을 검토해줘`
- `모바일 첫 진입 UX를 개선해줘`
- `API 계약 변경 영향이 있는지 리뷰해줘`

## Ignore Examples

- `안녕하세요`
- `고마워`
- `이 구조가 맞을까?`
- `왜 이렇게 했어?`

단, 일반 질문이라도 사용자가 명확히 “바꿔줘”, “정리해줘”, “검토해줘”처럼 실행을 요청하면 `actionable`로 본다.

## Execution Policy

- low-risk + high-confidence + allowed target
  - auto-apply 가능
- review-only, cross-verify candidate, target ambiguity, high-risk
  - `needs-triage`로 올린다

## Anti-Patterns

- 모든 자연어를 ticket으로 만드는 것
- 일반 질문에도 무조건 `dispatch-now`를 호출하는 것
- 위험한 변경을 triage 승인 없이 바로 실행하는 것
