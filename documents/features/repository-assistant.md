# Repository Assistant

## Non-Technical View

### What this feature does

It answers repository questions using the indexed codebase instead of general-purpose guessing.

### What the user does

- opens a single repository assistant workspace
- asks a question in plain language
- asks follow-up questions in the same thread

### What the user gets back

- grounded answers about the selected repository only
- thread-aware follow-up handling
- evidence-backed responses based on the latest indexed snapshot

### Why it matters

This is the main repository understanding surface. It reduces time spent searching files manually and helps explain architecture, flows, jobs, routes, and dependencies.

## Technical View

### Request path

`POST /repositories/:id/ask` → queue question service → `AssistantResponseJob` → answer generation service → retrieval service → provider/local response → Turbo message update

### Processing stages

1. save user message
2. create pending assistant message
3. enqueue background job
4. build thread-aware retrieval query from recent messages
5. retrieve top repository-scoped chunks
6. construct grounded provider prompt
7. generate answer and persist usage metadata
8. replace pending message with final content

### Current grounding model

- one repository at a time
- one latest successful indexed snapshot
- recent thread context improves follow-up resolution
- provider output is constrained by retrieved repository evidence
