# Repository Ingestion

## Non-Technical View

### What this feature does

It lets a user register a repository and turn it into a searchable knowledge base.

### What the user does

- enters repository name and URL
- selects or confirms the tracked branch
- submits the repository

### What the user gets back

- repository record created
- ingestion starts in the background
- status updates appear in the repository workspace
- after completion, the repository becomes usable in Search, Assistant, and Impact Analyzer

### Why it matters

This is the entry point for every other feature. If ingestion is not complete, the rest of the product has no repository context to work with.

## Technical View

### Request path

`RepositoriesController#create` → repository persistence → ingestion start service → `RepositoryIngestionJob`

### Processing stages

1. clone tracked branch into temporary workspace
2. inventory supported files
3. extract entities and relationships
4. split files into searchable chunks
5. generate embeddings
6. build dependency edges
7. persist snapshot metadata
8. clean temporary clone directory

### Main outputs

- `repositories`
- `repository_ingestions`
- `code_files`
- `code_chunks`
- `entities`
- `entity_relationships`
- `dependency_edges`

### Operational rules

- repository scope is isolated by `repository_id`
- one tracked branch per repository in MVP
- ingestion is async via Sidekiq
- temporary clone data is deleted after completion or failure
