# Dispatch Task

Use this command from the triage pane when the user gives a new requirement in natural language and you want to turn it into a structured task proposal.

## Goal

Interpret the user's request, store it in the dispatch inbox, and guide the operator to review the proposal produced by the watcher/dispatcher before execution.

## Steps

1. Treat `$ARGUMENTS` as the raw requirement text.
2. Run:

```bash
ws enqueue-dispatch soullink --text "$ARGUMENTS"
```

3. Tell the operator:
- the inbox file path that was created
- to run `ws dispatch-watch soullink --once` for a one-shot proposal, or keep `ws dispatch-watch soullink` running in a watcher pane

4. Do not apply automatically.

## Notes

- Use this as the default entry from triage.
- If the user already gave a markdown spec path, prefer:

```bash
ws enqueue-dispatch soullink /absolute/path/to/request.md
```

- If the proposal looks wrong after watcher processing, refine the wording or use `ws dispatch ... --target ... --slug ...` explicitly.
