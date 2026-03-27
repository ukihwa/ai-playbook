---
title: Skill Evaluation Policy
description: 모든 AI 스킬은 도입, 변경, 채택 전에 evaluation과 A/B 테스트를 거쳐야 한다는 공통 운영 정책
doc_type: automation
status: active
source_of_truth: true
priority: 15
when_to_use:
  - 새 skill을 도입할 때
  - 기존 skill을 수정하거나 버전업할 때
  - skill을 정식 채택할지 판단할 때
owners:
  - ukihwa
scope:
  - cross-project
tags:
  - skills
  - evaluation
  - ab-test
  - automation
related:
  - ./omc-usage-guide.md
  - ../03-workflows/code-review-harness-workflow.md
  - ../06-checklists/new-project-checklist.md
last_reviewed: 2026-03-27
---

# Skill Evaluation Policy

모든 skill은 기본적으로 평가 대상이다.

`유용해 보인다`는 이유만으로 기본 워크플로에 넣지 않는다. 실제 입력과 실제 산출물 기준으로 검증한 뒤 채택한다.

## Why

- Anthropic의 Skill Creator는 `Executor`, `Grader`, `Comparator`, `Analyzer`를 조합해 eval과 비교 실험을 수행하는 구조를 설명한다.  
  Source: [Skill Creator](https://claude.com/plugins/skill-creator)
- Anthropic 엔지니어링 글도 AI agent 품질 평가는 단순 점수 하나가 아니라 production monitoring, user feedback, manual review, systematic human evaluation, A/B testing을 함께 봐야 한다고 설명한다.  
  Source: [Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)

즉 evaluation과 A/B 테스트는 특정 skill의 옵션이 아니라, skill 운영 전반의 기본 원칙으로 보는 편이 맞다.

## Applies To

- `.claude/skills/*`
- `.claude/agents/*`
- OMC에 연결되는 custom workflow skill
- review, planning, documentation, orchestration용 커스텀 프롬프트/명령

## Required Stages

### 1. Evaluation

새 skill을 만들거나 외부 skill을 가져왔을 때 먼저 확인한다.

- 의도한 출력 형식을 지키는가
- 필요한 문서를 올바른 순서로 읽는가
- source of truth와 reference를 구분하는가
- 근거가 필요한 작업에서 실제 근거를 남기는가
- 사소한 작업에 과도하게 개입하지 않는가

### 2. A/B Test

기존 방식과 비교해서 실제 이득이 있는지 본다.

예:

- A: 기본 workflow
- B: 기본 workflow + 새 skill

또는:

- A: skill v1
- B: skill v2

비교할 때는 같은 입력 세트를 사용한다.

### 3. Adoption Decision

평가 결과를 바탕으로 아래 중 하나로 분류한다.

- `experimental`
- `candidate`
- `adopted`
- `deprecated`

## Evaluation Criteria

모든 skill에 공통으로 아래 항목을 본다.

- `precision`: 쓸모없는 개입이나 거짓 양성이 과도하지 않은가
- `recall`: 중요한 리스크나 작업을 놓치지 않는가
- `evidence quality`: 코드, 테스트, docs, 공식 문서 근거를 제대로 남기는가
- `clarity`: 사람이 후속 판단을 내리기 쉽게 결과를 정리하는가
- `latency`: 얻는 가치 대비 너무 느리지 않은가
- `cost`: 모델 호출 수나 운영 비용이 과도하지 않은가
- `fit`: 현재 프로젝트 문서 구조와 워크플로에 자연스럽게 맞는가

## When Re-Evaluation Is Required

아래 중 하나가 있으면 다시 평가한다.

- 프롬프트/설명/출력 형식 변경
- 읽는 문서 순서 변경
- 모델 조합 변경
- 외부 CLI나 MCP 의존성 변경
- 사용 범위가 확대됨
- false positive / false negative가 반복 보고됨

## Recommended Test Set

처음에는 5~10개의 실제 task 또는 PR을 샘플로 고른다.

- 작은 변경
- 중간 복잡도 변경
- 외부 사실 검증이 필요한 변경
- 리뷰가 어려운 변경
- 문서 업데이트가 필요한 변경

이렇게 섞어야 skill의 편향을 빨리 볼 수 있다.

## Output Expectations

평가 결과는 최소한 아래를 남긴다.

- 테스트한 입력 목록
- A/B 비교 방식
- 유효했던 finding 또는 산출물 예시
- false positive / 누락 사례
- 채택 여부와 이유

## Adoption Rules

- 기본 workflow에 넣기 전에는 최소한 1회 이상의 evaluation을 통과해야 한다.
- 리뷰나 오케스트레이션처럼 비용이 큰 skill은 A/B 테스트를 거친 뒤 채택한다.
- 외부에서 가져온 skill은 upstream을 그대로 신뢰하지 않고 현재 환경에 맞게 수정/고정한다.
- project-scoped가 적합한 skill은 전역 설치보다 프로젝트 로컬 설치를 우선한다.

## Retirement And Pruning

스킬은 한 번 추가하고 끝나는 자산이 아니다.

정기적으로 아래 질문으로 점검한다.

- 아직도 실제 사용 빈도가 있는가
- 기본 모델/기본 workflow만으로 충분해지지 않았는가
- false positive가 반복되지 않는가
- 유지 비용이나 실행 시간이 과도하지 않은가
- 다른 skill과 역할이 중복되지 않는가

아래 조건이면 `deprecated` 또는 제거를 검토한다.

- 최근 사용 사례가 거의 없음
- 더 단순한 기본 workflow가 같은 역할을 수행함
- 프로젝트 문서 구조와 자주 충돌함
- 외부 의존성 실패가 잦음
- 팀이 결과를 거의 신뢰하지 않음

pruning은 failure가 아니라 건강한 유지보수 활동으로 본다.

## Practical Default

현재 기본 권장 흐름은 다음과 같다.

1. `experimental` 상태로 도입
2. evaluation 수행
3. 필요하면 A/B 테스트 수행
4. 결과가 좋으면 `candidate`
5. 반복 사용 후 안정적이면 `adopted`

이 규칙은 `cross-verify` 같은 리뷰 스킬뿐 아니라 모든 skill에 공통 적용한다.

## Notes On Current Ecosystem Patterns

공식 문서와 공개 예시를 보면 스킬 자산은 보통 아래 원칙으로 관리한다.

- Anthropic은 user-level과 project-level subagent/plugin 설정을 분리한다.  
  Sources: [Claude Code settings](https://code.claude.com/docs/en/settings), [Subagents](https://code.claude.com/docs/en/sub-agents)
- Gemini CLI도 workspace/user/extension tiers를 나누고, `list`, `enable`, `disable`, `install`, `uninstall` 명령으로 skill을 관리한다.  
  Source: [Gemini CLI skills](https://geminicli.com/docs/cli/skills/)
- 공개 예시 저장소도 전체 묶음 설치보다 필요한 플러그인만 개별 설치하거나, 프로젝트 공유용 구조를 별도로 둔다.  
  Sources: [claude-code-showcase](https://github.com/ChrisWiles/claude-code-showcase), [claude-code-skills](https://github.com/levnikolaevich/claude-code-skills)

즉 실무적으로는 `많이 모으기`보다 `스코프를 나누고, 필요할 때 켜고, 평가 후 남길 것만 유지`하는 쪽이 더 일반적이다.
