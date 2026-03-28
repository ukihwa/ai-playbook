# Apply Dispatch

Use this command when the request should be executed immediately through the inbox watcher flow.

## Goal

Turn a natural-language requirement or spec path into a real task or review window by enqueueing it and running the watcher with `--apply`.

## Steps

1. Treat `$ARGUMENTS` as either:
- raw requirement text, or
- an absolute path to a markdown request/spec file

2. If `$ARGUMENTS` starts with `/`, treat it as a file path and run:

```bash
ws enqueue-dispatch soullink "$ARGUMENTS"
ws dispatch-watch soullink --apply --once
```

3. Otherwise run:

```bash
ws enqueue-dispatch soullink --text "$ARGUMENTS"
ws dispatch-watch soullink --apply --once
```

4. Summarize the actual execution result:
- target
- slug
- task vs review
- handoff or review artifact path

## Safety

- If the request is obviously ambiguous about `target`, stop and recommend using `/dispatch-task` first.
- Do not silently change project scope.
