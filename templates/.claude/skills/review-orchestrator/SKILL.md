---
name: review-orchestrator
description: "설계의도 작성, 평가기준 생성, 리뷰/QA 에이전트 실행, 리뷰 산출물 저장까지 코드리뷰 하네스를 조율한다. 리뷰 하네스, 평가기준, design intent, QA inspector, review artifacts가 필요할 때 사용한다."
---

# Review Orchestrator

코드리뷰 하네스를 조율하는 상위 스킬이다.

## Goal

- 구현 전에 `design intent`와 `evaluation criteria`를 만든다.
- 구현 후 `reviewer`와 `qa-inspector`가 같은 기준으로 검토하게 한다.
- 결과를 `.review-artifacts/{branch-or-task}/`에 정리한다.

## Workflow

1. 현재 task 범위를 `docs/tasks/triage-status.md`에서 확인한다.
2. `docs/review/design-intent.md`를 작성하거나 갱신한다.
3. `docs/review/evaluation-criteria.md`를 작성하거나 갱신한다.
4. `reviewer`와 `qa-inspector`가 읽어야 할 문서를 명시한다.
5. 리뷰 결과를 `.review-artifacts/{branch-or-task}/`에 저장한다.

## Required Inputs

- 현재 task 식별자 또는 branch 이름
- 관련 코드 경로
- 관련 기준 문서 경로

## Output

- `design-intent.md`
- `evaluation-criteria.md`
- `review-findings.md`
- `qa-findings.md`

## Evidence Rules

- 프로젝트 내부 변경은 코드, 테스트, 현재 기준 문서를 우선 근거로 쓴다.
- 외부 SDK, framework, API, 보안/인증, 플랫폼 제약이 걸린 변경은 공식 문서 또는 신뢰 가능한 웹 근거를 함께 확인한다.
