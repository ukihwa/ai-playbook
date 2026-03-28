# Dispatch Task

Use this command from the triage pane when the user gives a new requirement in natural language and you want to turn it into a structured task proposal.

## Goal

Interpret the user's request, store it in the dispatch inbox, and immediately run a one-shot watcher so the operator gets a structured proposal without manually chaining commands.

## Steps

1. Treat `$ARGUMENTS` as the raw requirement text.
2. Create the inbox request:

```bash
ws enqueue-dispatch soullink --text "$ARGUMENTS"
```

3. Then immediately run:

```bash
ws dispatch-watch soullink --once
```

4. Summarize the proposal briefly:
- target
- slug
- review_only
- cross_verify_candidate
- doc_updates

5. Do not apply automatically.

## Notes

- Use this as the default entry from triage.
- If the user already gave a markdown spec path, prefer:

```bash
ws enqueue-dispatch soullink /absolute/path/to/request.md
ws dispatch-watch soullink --once
```

- If the proposal looks wrong after watcher processing, refine the wording or use `ws dispatch ... --target ... --slug ...` explicitly.
