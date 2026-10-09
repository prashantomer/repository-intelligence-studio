# Provider Logs

## Non-Technical View

### What this feature does

It records model and embedding calls so the user can inspect usage, cost, latency, and provider behavior.

### What the user sees

- operation type
- provider and model
- status
- prompt/completion/total usage
- latency
- estimated cost
- request/response detail drill-down

### Why it matters

This makes AI behavior observable and easier to debug, especially during ingestion, assistant usage, and impact narration.

## Technical View

### Request path

provider execution → call log recorder → `provider_call_logs` persistence → logs UI table

### Captured operations

- assistant completions
- embedding generation
- impact narration calls

### Current UI behavior

- tabular view
- sticky filters
- inner scroll for long history
