# Manual Re-Sync

## Non-Technical View

### What this feature does

It refreshes a repository when the tracked branch changes or when the indexed knowledge needs to be rebuilt.

### What the user does

- opens a repository
- clicks `Re-sync`

### What the user gets back

- a new ingestion run starts immediately
- the repository snapshot, chunks, entities, and embeddings are rebuilt
- ingestion history records the new run

### Why it matters

Repository intelligence becomes stale if the tracked branch changes. Re-sync keeps the indexed snapshot aligned with the source repository.

## Technical View

### Request path

`RepositoriesController#resync` → repository ingestion start service with force behavior → `RepositoryIngestionJob`

### Runtime behavior

- creates a new ingestion record
- rebuilds repository-derived metadata and vectors
- updates repository status and latest snapshot markers
- writes audit and provider-call history where applicable

### Current MVP rule

Re-sync is manual-first. Automatic re-ingestion is intentionally deferred.
