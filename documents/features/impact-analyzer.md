# Impact Analyzer

## Non-Technical View

### What this feature does

It estimates what may be affected if a class, module, controller, job, route, service, or other code target changes.

### What the user does

- enters either a direct entity name or a natural-language impact question
- reviews the generated impact report
- reopens previous saved reports from history

### Good input examples

- `What breaks if ApplicationController changes?`
- `Which files depend on RepositoryIngestion?`
- `What APIs use SettingsController?`
- `What jobs depend on AssistantResponseJob?`

### Weak input examples

- `Impact of rework on design?`
- `How risky is refactoring this app?`

### What the user gets back

- resolved target entity
- upstream and downstream dependency evidence
- impacted files, routes, and jobs
- risk classification
- review guidance and checklist
- saved report history

### Why it matters

This makes repository intelligence operational, not just descriptive. It helps evaluate change blast radius before editing code.

## Technical View

### Request path

`GET /repositories/:id/impact` → impact query interpreter → target resolution → dependency traversal query → semantic retrieval → impact analysis service → optional provider narration → Turbo frame result render

### Processing stages

1. interpret direct identifier or natural-language query
2. resolve likely entity inside the selected repository
3. fetch upstream and downstream graph neighbors
4. collect related jobs, routes, and files
5. retrieve top supporting chunks
6. calculate deterministic risk level
7. generate provider-backed narration with deterministic fallback
8. persist report for history and drill-down reuse

### Important limitation

The current analyzer is still entity-centric. Broad conceptual prompts need a resolvable code target to produce useful results.
