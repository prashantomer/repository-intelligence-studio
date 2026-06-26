# Repository Intelligence Studio

An engineering knowledge assistant that ingests repositories, builds searchable project knowledge, and enables repository-scoped semantic search and grounded AI conversations to understand architecture, workflows, dependencies, and implementation details.

## MVP Scope

- Public repository registration
- Repository-scoped ingestion and re-sync
- File, chunk, entity, route, and relationship indexing
- Semantic search over indexed repository chunks
- Repository-scoped assistant conversations
- Centralized AI provider and model settings
- Async assistant replies with typing-state UI

## Current Stack

- Ruby `3.3.4`
- Rails `8.1.3`
- PostgreSQL
- Redis
- Sidekiq
- Hotwire + Turbo

## Core Capabilities

### Repository ingestion

- Register a repository URL
- Detect and track a target branch
- Queue ingestion asynchronously
- Force re-sync even when commit SHA is unchanged
- Clean cloned workspaces after ingestion completes or fails

### Retrieval and assistant

- Chunk indexed repository content
- Generate and store embeddings
- Run repository-scoped semantic retrieval
- Ask grounded questions against one repository at a time
- Receive async assistant responses through Turbo-driven UI updates

### AI configuration

- Centralized per-user assistant settings
- Centralized per-user embedding settings
- Current embedding storage baseline is `1024` dimensions
- Current supported embedding providers for the active storage baseline:
  - `local`
  - `ollama`

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
6. Update centralized AI settings and re-sync if embedding settings changed

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
