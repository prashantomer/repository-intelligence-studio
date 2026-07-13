# Repository Intelligence Studio

An engineering knowledge workspace that ingests repositories, builds structured code intelligence, and enables repository-scoped search, grounded AI answers, and change-impact analysis.

## Documentation

### Planning

- [Product plan](documents/planning/ProductPlan.md)
- [Build action plan](documents/planning/BuildActionPlan.md)
- [Build progress](documents/progress/BuildProgress.md)

### Architecture and Flows

- [Feature request/response flows](documents/architecture/FeatureFlows.md)

### Feature Documentation

- [Feature index](documents/features/README.md)
- [Repository ingestion](documents/features/repository-ingestion.md#repository-ingestion)
- [Manual re-sync](documents/features/manual-resync.md#manual-re-sync)
- [Repository assistant](documents/features/repository-assistant.md#repository-assistant)
- [Semantic search](documents/features/semantic-search.md#semantic-search)
- [Impact analyzer](documents/features/impact-analyzer.md#impact-analyzer)
- [Provider logs](documents/features/provider-logs.md#provider-logs)
- [Centralized AI settings](documents/features/centralized-ai-settings.md#centralized-ai-settings)

## MVP Scope

- Public repository registration
- Repository-scoped ingestion and re-sync
- File, chunk, entity, route, and relationship indexing
- Semantic search over indexed repository chunks
- Repository-scoped assistant conversations
- Repository-scoped impact analysis
- Centralized AI provider and model settings
- Async assistant replies with typing-state UI
- Provider call logging with usage and cost visibility

## Feature Summary

### Repository ingestion

- Register a repository URL
- Detect and track a target branch
- Queue ingestion asynchronously
- Build searchable repository metadata and vectors
- Clean temporary cloned workspaces after processing

See: [Repository ingestion details](documents/features/repository-ingestion.md#repository-ingestion)

### Manual re-sync

- Trigger rebuild of the tracked repository snapshot
- Refresh chunks, entities, graph edges, and embeddings
- Maintain ingestion history and latest status

See: [Manual re-sync details](documents/features/manual-resync.md#manual-re-sync)

### Repository assistant

- Ask grounded questions against one repository at a time
- Reuse recent thread context for follow-up questions
- Render async replies into the chat workspace

See: [Repository assistant details](documents/features/repository-assistant.md#repository-assistant)

### Semantic search

- Search repository chunks by semantic similarity
- Use repository-scoped vector retrieval only
- Return practical code-oriented result rows

See: [Semantic search details](documents/features/semantic-search.md#semantic-search)

### Impact analyzer

- Analyze likely blast radius for a class, module, route, job, or service
- Accept both direct entity names and natural-language impact prompts
- Persist saved reports with graph evidence and review guidance

See: [Impact analyzer details](documents/features/impact-analyzer.md#impact-analyzer)

### Provider logs

- Inspect assistant, embedding, and narration calls
- Track usage, latency, status, and estimated cost
- Use tabular history for debugging provider behavior

See: [Provider logs details](documents/features/provider-logs.md#provider-logs)

### Centralized AI settings

- Configure assistant and embedding providers per user
- Use provider-aware model presets with free-form model override
- Keep AI behavior centralized across repository surfaces

See: [AI settings details](documents/features/centralized-ai-settings.md#centralized-ai-settings)

## Current Stack

- Ruby `3.3.4`
- Rails `8.1.3`
- PostgreSQL
- Redis
- Sidekiq
- Hotwire + Turbo

## Local Setup

### 1. Install dependencies

```bash
bundle install
```

### 2. Prepare services

Make sure these are available locally:

- PostgreSQL
- Redis
- Ollama, if using Ollama-backed models

### 3. Database setup

```bash
bin/rails db:create
bin/rails db:migrate
```

### 4. Run the app

In one terminal:

```bash
bin/rails server
```

In another terminal:

```bash
bundle exec sidekiq
```

## Recommended Demo Flow

1. Open the repositories dashboard
2. Add a public repository
3. Wait for ingestion to complete
4. Open `Search Chunks` and run a semantic query
5. Open `Assistant` and ask a repository question
6. Open `Impact Analyzer` and test a change query
7. Review provider logs and AI settings

## Cleanup Task

To remove disposable tmp workspace data and old cloned repositories:

```bash
bin/rails eka:cleanup_tmp
```

This task clears:

- `tmp/repositories`
- `tmp/cache`
- `tmp/storage`
- `tmp/sockets`
- `tmp/restart.txt`

It preserves the expected keep files and pid directory structure.

## Project Notes

- The app is intentionally repository-scoped for MVP simplicity.
- Public repositories are the current target scope.
- Provider-portable embedding storage is intentionally deferred.
- The app is kept intentionally learnable and demonstrable rather than over-engineered.
