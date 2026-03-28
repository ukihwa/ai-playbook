# Request Triage

Use this command when a worker or reviewer has reached a point that needs triage approval before continuing.

## Steps

1. Treat `$ARGUMENTS` as a ticket id, slug, `target/slug`, or absolute ticket path.
2. Run:

```bash
ws request-triage soullink "$ARGUMENTS"
```

3. Summarize briefly:
- ticket
- why triage approval is needed
- next expected decision
