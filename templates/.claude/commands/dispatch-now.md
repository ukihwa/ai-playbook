# Dispatch Now

Use this command when the user gives a natural-language request from triage and you want the system to create a proposal and auto-apply it only if it matches the project auto-apply policy.

## Goal

Interpret the request, enqueue it, process it once, and let the watcher decide whether it is safe enough to auto-apply.

## Steps

1. Treat `$ARGUMENTS` as the raw requirement text.
2. Run:

```bash
ws enqueue-dispatch soullink --text "$ARGUMENTS"
ws dispatch-watch soullink --auto-apply --once
```

3. Summarize briefly:
- target
- slug
- whether it was auto-applied or escalated to `needs-triage`
- doc_updates

## Notes

- Low-confidence or high-risk requests should be escalated to `needs-triage` unless project policy says otherwise.
- Requests that imply review-only or cross-verify should not be auto-applied unless project policy explicitly allows it.
