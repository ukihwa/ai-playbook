# Watch Dispatch

Use this command when you want the triage watcher pane running continuously.

## Goal

Start the tmux dispatch watcher so new inbox requests are processed automatically.

## Steps

1. Run:

```bash
ws watch soullink
```

2. Confirm briefly:
- watcher window started
- project
- whether it is apply or propose mode

## Notes

- Use `ws watch soullink --apply` only when the operator explicitly wants automatic execution.
- Stop it with:

```bash
ws stop-watch soullink
```
