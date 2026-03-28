# Apply Ticket

Use this command when a dispatch ticket from the queue should be executed.

## Goal

Take a queued ticket and turn it into a real task or review run.

## Steps

1. Treat `$ARGUMENTS` as a ticket id, slug, `target/slug`, or absolute ticket file path.
2. Run:

```bash
ws apply-ticket soullink "$ARGUMENTS"
```

3. Summarize briefly:
- ticket
- target
- slug
- task vs review
