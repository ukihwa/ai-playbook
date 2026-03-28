# Reject Ticket

Use this command when triage has decided that a `needs-triage` ticket should not proceed as-is.

## Steps

1. Treat `$ARGUMENTS` as a ticket id, slug, `target/slug`, or absolute ticket path.
2. Run:

```bash
ws reject-ticket soullink "$ARGUMENTS"
```

3. Summarize briefly:
- ticket
- reason for rejection or rework
