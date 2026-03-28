# Triage Intake

Use this command when the user says a plain natural-language implementation request in the triage session and you want the system to decide whether it should be ignored, auto-applied, or escalated to triage approval.

## Goal

Run the default triage intake flow with the raw request.

## Steps

1. Treat `$ARGUMENTS` as the original user request.
2. Run:

```bash
ws intake soullink --text "$ARGUMENTS"
```

3. Summarize briefly:
- whether it was ignored or classified as actionable
- if actionable, whether it was auto-applied or escalated to `needs-triage`
- target
- slug if one was created

## Notes

- Use this as the default internal triage action for plain implementation requests.
- Do not use it for greetings, thanks, or casual chat.
