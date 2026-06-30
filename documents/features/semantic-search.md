# Semantic Search

## Non-Technical View

### What this feature does

It finds relevant code and documentation chunks by meaning, not only by exact keyword match.

### What the user does

- opens `Search Chunks`
- enters a question, concept, component name, or workflow phrase

### What the user gets back

- ranked repository chunks
- file paths and content snippets
- repository-scoped results only

### Why it matters

This provides fast codebase discovery and also acts as a retrieval primitive for the assistant and impact workflows.

## Technical View

### Request path

`RepositoriesController#search` → `Retrieval::SemanticSearchService`

### Processing stages

1. embed the query with the configured embedding provider/model
2. compare the query vector against stored chunk vectors
3. rank by semantic similarity
4. return compact result rows for UI rendering

### Constraints

- retrieval is repository-scoped
- embedding config must match the stored vector baseline
- current storage baseline is fixed-dimension for the active embedding table
