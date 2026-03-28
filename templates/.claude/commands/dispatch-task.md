# Dispatch Task

Use this command from the triage pane when the user gives a new requirement in natural language and you want to turn it into a structured task proposal.

## Goal

Interpret the user's request, then run the shared dispatcher in propose-only mode so the operator can review the suggested target, slug, references, and document updates before execution.

## Steps

1. Treat `$ARGUMENTS` as the raw requirement text.
2. Run:

```bash
ws dispatch soullink --text "$ARGUMENTS"
```

3. Summarize the proposal briefly:
- target
- slug
- review_only
- cross_verify_candidate
- doc_updates

4. Do not apply automatically.

## Notes

- Use this as the default entry from triage.
- If the user already gave a markdown spec path, prefer:

```bash
ws dispatch soullink /absolute/path/to/request.md
```

- If the proposal looks wrong, refine the wording or override `--target` / `--slug` explicitly in a follow-up command.
