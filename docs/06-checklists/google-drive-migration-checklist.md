---
title: Google Drive Migration Checklist
description: 개인 GoogleDrive_Mirror 구조를 실제로 옮길 때 따라가는 짧은 실행 체크리스트
doc_type: checklist
status: active
source_of_truth: true
priority: 30
when_to_use:
  - Google Drive 마이그레이션 작업을 실제로 시작할 때
owners:
  - ukihwa
scope:
  - personal-drive
tags:
  - checklist
  - google-drive
  - migration
related:
  - ../operations/google-drive-migration-plan.md
  - ../operations/google-drive-operating-rules.md
last_reviewed: 2026-03-27
---

# Google Drive Migration Checklist

## Before Starting

- [ ] 목표 구조 문서를 읽었다
- [ ] Ideaverse vault 내부 구조를 건드리지 않기로 확인했다
- [ ] 오늘 옮길 영역을 하나만 정했다

## Create Containers

- [ ] `00_Inbox` 생성
- [ ] `01_Admin_Life` 생성
- [ ] `02_Work` 하위 새 구조 생성
- [ ] `03_Knowledge/Vaults` 생성
- [ ] `05_Assets` 하위 구조 생성
- [ ] `08_Archive` 하위 구조 생성

## Phase 1: Admin_Life

- [ ] `01_Personal/Certificates` 이동
- [ ] `01_Personal/Family` 이동
- [ ] `01_Personal/Health` 이동
- [ ] `01_Personal/ID_Docs` 이동
- [ ] 파일 누락 여부 확인

## Phase 2: Work

- [ ] `Projects` 이동
- [ ] `Reference` 이동
- [ ] `Resume` 이동
- [ ] 루트 이미지 파일을 `05_Assets`로 이동
- [ ] `02_Work` 루트 정리 확인

## Phase 3: Knowledge

- [ ] `03_Study/Notes`를 `03_Knowledge/Vaults/Ideaverse`로 이동
- [ ] `Learning_Materials` 이동
- [ ] `Resources` 이동
- [ ] Obsidian에서 새 경로가 정상 동작하는지 확인
- [ ] `.obsidian`, `.claude`, `.omc`, `CLAUDE.md`가 그대로 있는지 확인

## Phase 4: Archive

- [ ] `2025_Old` 이동
- [ ] `Completed_Projects` 이동

## Phase 5: Root Cleanup

- [ ] 루트 단일 파일을 적절한 위치로 이동
- [ ] 애매한 파일은 `00_Inbox`로 이동
- [ ] 루트가 단순해졌는지 확인

## After Each Phase

- [ ] 이동 전후 파일 수가 크게 다르지 않은지 확인
- [ ] 빠진 PDF/이미지/문서가 없는지 확인
- [ ] 잘못 옮긴 항목이 없는지 확인

## Final Check

- [ ] 최상위 폴더 역할이 명확해졌다
- [ ] Ideaverse vault가 정상 동작한다
- [ ] `00_Inbox` 외에는 미분류 파일이 거의 없다
- [ ] 다음부터는 운영 규칙 문서대로 유지할 수 있다
