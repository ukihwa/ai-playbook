# Project Operating Guide

## Project Purpose

- This repository is the active implementation target for the current project.
- Prefer this repository over legacy repositories for new work.

## Read Order

When starting work in this repository, read documents in this order:

1. `docs/tasks/triage-status.md`
2. `docs/conventions/code-convention.md`
3. `docs/architecture/overview.md`
4. Relevant files in `docs/architecture/`
5. Relevant files in `docs/adr/`
6. `docs/reference/*` only if needed

If a required document does not exist yet, say so briefly and continue with the best available source.

## Source Of Truth

- Current implementation rules live in `docs/conventions/*` and `docs/architecture/*`.
- Current task status lives in `docs/tasks/triage-status.md`.
- Architecture decisions live in `docs/adr/*`.
- `docs/reference/*` is reference-only and must not override active project docs.
- If conversation instructions conflict with repository docs, prefer repository docs unless the user explicitly says otherwise.

## Reference Policy

- Legacy repositories are behavior references only.
- Backend or external repositories are read-only contract references only.
- Do not treat reference material as the primary source of truth for new structure.

## Working Rules

- Start with the lightest-weight path that preserves quality.
- For ambiguous requests, clarify scope through triage before broad implementation.
- In the triage session, plain natural-language implementation requests should be treated as dispatch candidates even if the user does not explicitly call a slash command.
- The default internal action for a plain implementation request is `ws intake <project> --text "<original request>"`.
- Do not turn greetings, thanks, or general chat into tickets.
- If a request is low-risk and matches project auto-apply policy, let the intake flow auto-apply it.
- If the request is ambiguous, high-risk, review-only, or blocked by policy, let the intake flow escalate it to `needs-triage`.
- Separate authoring from approval: implementation first, review second.
- For substantial changes, update docs that materially affect onboarding or future implementation.
- Keep this file short. Put detailed guidance in `docs/` rather than expanding this file aggressively.
- When creating commits or PR titles, follow the repository git workflow convention.
