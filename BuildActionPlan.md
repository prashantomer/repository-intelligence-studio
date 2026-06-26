# Engineering Knowledge Assistant — Action Plan

## 1. Objective

Build a **Rails 8 monolith** that ingests GitHub repositories of different project types, extracts code intelligence, stores searchable metadata and embeddings, and provides AI-powered repository understanding through architecture exploration, semantic search, impact analysis, and documentation generation.

The implementation should be done in **sequential phases**, where each phase leaves the system in a usable and testable state. The plan below is structured so that later capabilities depend on stable primitives built earlier, rather than introducing AI features before repository intelligence is reliable.

---

## 2. Delivery Strategy

### Why a Rails monolith first

Use a monolith because the project needs fast iteration across:

- web UI
- ingestion workflows
- background jobs
- vector search
- AI orchestration
- reporting

Splitting into services too early would add deployment and coordination complexity without improving the MVP. The correct first architecture is:

- **Rails app** for web, domain logic, admin workflows, and orchestration
- **PostgreSQL + pgvector** for relational data and embeddings
- **Redis + Sidekiq** for background execution
- **Hotwire** for repository status, chat, and architecture pages

This keeps the system cohesive while still allowing clean modularization inside the monolith through service objects, bounded namespaces, and asynchronous pipelines.

### MVP scope decisions now locked

- support **public GitHub repositories only**
- support **multiple repositories per user**
- keep all ingestion, retrieval, and assistant behavior **strictly repository-scoped**
- support **one tracked branch per repository** in MVP
- support **manual re-ingestion first**
- treat **automatic re-ingestion** as a later enhancement
- treat **PR Review Assistant** as post-MVP, not core scope

---

## 3. Target Monolith Architecture

### Core bounded areas

Organize the application around these domains:

- `Repositories` — repository connection, clone configuration, branch tracking, ingestion lifecycle
- `Codebase` — files, chunks, entities, routes, dependency relations
- `Embeddings` — chunk embedding generation and similarity search
- `Assistant` — retrieval, prompt construction, answer generation, conversation history
- `Analysis` — dependency graph, impact analysis, architecture summaries
- `Documentation` — markdown reports and export workflows
- `Platform` — audit logging, error handling, job idempotency, observability

### Recommended internal structure

- `app/models` for persistence models only
- `app/services` for orchestration and domain operations
- `app/jobs` for async pipeline steps
- `app/queries` for retrieval and reporting queries
- `app/presenters` for UI/report shaping
- `app/lib` for parser adapters and low-level Git/code utilities
- `app/controllers` for thin HTTP entrypoints

This separation matters because the parser, embedding, and AI flows will become hard to maintain if controller/model code starts owning orchestration.

---

## 4. Sequential Build Plan

## Ingestion and Repository Scope Rules

These rules apply across all phases and should not be left to implementation-time judgment.

### Repository scope

- a user can register multiple repositories
- every persisted record must be keyed by `repository_id`
- assistant, search, impact analysis, and documentation must run against exactly one repository at a time
- no cross-repository retrieval or reasoning in MVP

### Branch policy

- each repository has one tracked branch in MVP
- default tracked branch is the repository default branch unless the user selects another branch
- every ingestion run stores both branch name and commit SHA
- indexed knowledge belongs to one repository + one tracked-branch snapshot lineage
- no multi-branch indexing in MVP

### Ingestion/re-ingestion policy

- ingestion runs asynchronously through explicit ingestion records
- only one active ingestion may run for the same repository and tracked branch at a time
- different repositories may ingest concurrently
- re-ingestion is manual first through a `Re-sync` action
- before reprocessing, the system checks the latest commit SHA for the tracked branch
- if SHA is unchanged, mark the run as `skipped`/no-op
- if SHA changed, reprocess incrementally using content hashes where possible
- failed runs must be retryable without duplicating indexed records
- temporary cloned workspaces are deleted after ingestion completes or fails cleanup

### Deferred advanced enhancement — dimension-routed embedding portability

- the current baseline uses one fixed vector dimension for chunk storage
- save-time provider/model validation should later resolve effective embedding dimension before ingestion
- vectors should later be routed into dimension-compatible storage or per-dimension tables/indexes
- portability across `Ollama`, `OpenAI`, and future providers should be implemented on top of that routing layer, not by mixing dimensions in one table

### Repository storage policy

- the repository is cloned temporarily during ingestion
- the app persists code-derived metadata, chunks, embeddings, branch, and commit snapshot data
- the app does not require a permanent local clone to answer questions after ingestion
- answers operate on the latest successful ingested snapshot, not the live GitHub state

## Phase 0 — Foundation and Engineering Guardrails

### Goal

Create a production-capable Rails baseline before feature work starts.

### Tasks

1. Initialize Rails 8 app with PostgreSQL.
2. Add and configure:
   - `sidekiq`
   - `redis`
   - `pgvector`
   - `rspec-rails`
   - `rubocop`
   - `dotenv` or Rails credentials strategy
   - `omniauth-github` or GitHub App integration path
3. Configure Sidekiq, Active Job adapter, Redis connection, and job retry policies.
4. Add shared application concerns:
   - structured logging
   - audit logging
   - error wrapper/result objects
   - service base class
   - idempotency support for jobs
5. Establish environment variables and secrets strategy for:
   - GitHub credentials
   - OpenAI API key
   - database/redis configuration
6. Set up CI baseline:
   - test
   - lint
   - security checks if time permits

### Why this comes first

Repository ingestion and AI pipelines are asynchronous and failure-prone. Without job discipline, logging, and test conventions at the start, the project will degrade quickly once multi-step ingestion begins.

### Deliverables

- bootable Rails monolith
- Sidekiq worker process
- pgvector enabled
- RSpec and Rubocop configured
- base service/job patterns defined

---

## Phase 1 — Core Domain and Repository Ingestion

### Goal

Allow a user to register a repository and trigger a reliable ingestion workflow.

### Data model

Create the initial schema for:

- `users`
- `repositories`
  - name
  - github_url
  - default_branch
  - tracked_branch
  - status
  - visibility
  - provider
  - last_ingested_at
  - last_commit_sha
- `repository_ingestions`
  - repository_id
  - branch_name
  - commit_sha
  - status
  - started_at
  - finished_at
  - error_message
  - triggered_by_id
- `audit_logs`

### Tasks

1. Implement repository creation flow.
2. Support public repository URL input only for MVP.
3. Detect repository default branch and allow optional tracked-branch override.
4. Build ingestion state machine:
   - pending
   - cloning
   - parsing
   - chunking
   - embedding
   - completed
   - failed
   - skipped
5. Implement clone service using a local workspace directory outside persisted app data.
6. Create `RepositoryIngestionJob` as orchestration entrypoint with same-repo/branch concurrency protection.
7. Add repository detail page showing:
   - current status
   - last ingestion result
   - tracked branch
   - last commit SHA
   - files/entities counts once available
8. Add manual `Re-sync` action for re-ingestion.
9. Add audit logs for ingestion start, success, failure, skip, and re-run.

### Why this phase matters

Every later feature assumes repository acquisition is reliable. If clone and ingestion lifecycle are weak, parsing, embeddings, and AI answer quality will all become untrustworthy.

### Acceptance criteria

- user can submit a GitHub repository URL
- user can manage multiple repositories independently
- user can ingest one tracked branch per repository
- system queues ingestion asynchronously
- UI shows ingestion progress
- failure states are visible and persisted
- unchanged tracked branch snapshots are detected and skipped cleanly
- ingestion can be retried safely

---

## Phase 2 — Parsing Pipeline and Metadata Extraction

### Goal

Convert raw repository files from different project types into structured engineering metadata.

### Data model

Add:

- `code_files`
  - repository_id
  - path
  - language
  - content_hash
  - size_bytes
- `entities`
  - repository_id
  - code_file_id
  - entity_type
  - name
  - namespace
  - signature
  - metadata_json
- `entity_relationships`
  - repository_id
  - source_entity_id
  - target_entity_id
  - relationship_type
- `repository_routes`
  - repository_id
  - http_method
  - path
  - controller_name
  - action_name

### Tasks

1. Define file selection policy:
   - parse Ruby, JavaScript, TypeScript first
   - ignore binaries, vendor, node_modules, tmp, log, coverage
2. Build file scanner that records repository files and hashes.
3. Implement parser adapters:
   - Ruby parser adapter
   - JS/TS parser adapter
   - adapter interface that allows adding more ecosystems later
4. Add framework-aware extraction rules as adapters, not as global assumptions:
   - Rails conventions where applicable
   - generic Ruby modules/classes where Rails is absent
   - generic JS/TS exports/classes/modules where framework is unknown
5. Build relationship extraction for:
   - generic symbol/reference relationships where confidence is acceptable
   - framework-specific relationships only when an adapter supports them
6. Persist all extracted metadata under a single ingestion transaction boundary per stage where practical.
7. Remove stale entities/chunks/relationships for changed or deleted files during re-ingestion.
8. Produce ingestion summary metrics for the UI.

### Why this phase matters

This is the system’s factual layer. Semantic search and AI answers should not rely only on raw chunks; they need structured entities and relationships to answer architecture and impact questions correctly.

### Acceptance criteria

- repository files are indexed
- language/framework-specific entities are extracted with useful accuracy for supported adapters
- routes are discoverable where the repository framework exposes them clearly
- relationships are stored for later graph analysis
- ingestion summary reports counts by entity type

---

## Phase 3 — Chunking, Embeddings, and Semantic Retrieval

### Goal

Make repository knowledge retrievable by meaning, not only exact text match.

### Data model

Add:

- `code_chunks`
  - repository_id
  - code_file_id
  - entity_id nullable
  - chunk_type
  - chunk_text
  - start_line
  - end_line
  - token_count
  - embedding

### Tasks

1. Define chunking rules:
   - structure-aware chunks for supported languages
   - method/function-level chunks when routines are large
   - file-level fallback for unsupported structures
   - route/config chunks where relevant
2. Store chunk provenance:
   - file path
   - line range
   - linked entity
3. Implement embedding generation job pipeline.
4. Add pgvector similarity search service.
5. Combine vector retrieval with metadata filters:
   - repository scope
   - language
   - entity type
6. Re-embed only changed files using content hash comparison.
7. Expose a retrieval query object reusable by assistant, impact analysis, and docs generation.

### Why this phase matters

RAG quality depends more on chunk design and retrieval discipline than on the LLM itself. Good chunk provenance also makes answers explainable and defensible in a capstone review.

### Acceptance criteria

- chunks are generated from indexed files
- embeddings are stored in pgvector
- similarity search returns repository-scoped relevant results
- unchanged files do not re-embed unnecessarily

---

## Phase 4 — AI Assistant and Conversation Layer

### Goal

Answer repository questions using retrieved code context and structured metadata.

### Data model

Add:

- `conversations`
  - repository_id
  - user_id
  - title
- `messages`
  - conversation_id
  - role
  - content
  - citations_json
  - prompt_tokens
  - completion_tokens

### Tasks

1. Build assistant workflow:
   - classify question
   - retrieve relevant chunks
   - fetch related entities/routes if needed
   - construct prompt context
   - generate answer
   - persist interaction
2. Support question types:
   - architecture explanation
   - ownership/dependency lookup
   - flow tracing
   - Sidekiq/background usage
   - API usage
3. Require answer grounding:
   - file references
   - entity names
   - confidence-aware phrasing where evidence is weak
4. Add conversation UI inside repository detail page.
5. Stream responses if implementation cost is reasonable; otherwise return completed messages first.
6. Add token/accounting logs for future cost visibility.
7. Add provider call audit logging stored in the database:
   - provider
   - operation type (`assistant`, `embedding`)
   - model
   - repository_id
   - user_id
   - request metadata
   - response metadata
   - token usage
   - latency
   - estimated cost
   - success/failure
8. Add an internal provider call log page with filtering and history review.
9. Defer realtime streaming/tailing of provider logs to a later enhancement after the database-backed audit view is stable.
10. Enforce repository-scoped retrieval on every assistant query.
11. Answer from the latest successful ingested snapshot for the selected tracked branch.

### Why this phase comes after retrieval

The assistant should be the consumer of repository intelligence, not the producer of it. If built earlier, it becomes a thin chatbot over incomplete data and will underperform.

### Acceptance criteria

- user can ask repository-specific questions
- answers cite relevant files/entities
- conversations are stored and reviewable
- provider calls are auditable in the database with usage and estimated cost details
- assistant stays scoped to a selected repository
- assistant does not require a live local clone after ingestion completes

---

## Phase 5 — Dependency Graph and Impact Analysis

### Goal

Move beyond Q&A into engineering reasoning about change impact.

### Data model

Add:

- `dependency_edges`
  - repository_id
  - source_type
  - source_id
  - target_type
  - target_id
  - edge_type
  - confidence
- `impact_reports`
  - repository_id
  - query
  - result_json
  - generated_at

### Tasks

1. Normalize extracted relationships into graph edges.
2. Implement graph traversal queries:
   - upstream dependencies
   - downstream dependents
   - related files
   - routes touching entity
   - jobs touching entity
3. Build impact analysis service that combines:
   - dependency graph evidence
   - retrieved code chunks
   - LLM risk summarization
4. Support core prompts:
   - what breaks if X changes
   - which files depend on Y
   - which APIs use Z
5. Add architecture explorer page:
   - entity summary
   - linked services/models/jobs/routes
   - impact analysis panel

### Why this phase is the differentiator

This is where the project stops being a generic repository chatbot and becomes an engineering intelligence tool. The graph-backed impact flow is one of the strongest business-value features in the proposal.

### Acceptance criteria

- graph relationships are queryable
- impact reports list affected entities/files
- summaries include concrete evidence and risk explanation

---

## Phase 6 — Documentation Generation

### Goal

Turn repository intelligence into shareable engineering documentation.

### Tasks

1. Build documentation generators for:
   - repository overview
   - architecture summary
   - API/routes summary
   - domain/module summary
2. Generate markdown first.
3. Add PDF export only after markdown output is stable.
4. Reuse the same retrieval and entity graph services rather than building a parallel pipeline.
5. Add UI actions to generate and download docs from repository pages.

### Why markdown first

Markdown is simple, reviewable, versionable, and enough to demonstrate the capability. PDF is presentation format, not core intelligence.

### Acceptance criteria

- system generates repository markdown docs
- architecture and route summaries are readable and grounded
- export is tied to a specific repository snapshot

---

## Phase 7 — Hardening and Capstone Polish

### Goal

Make the project review-ready and operationally credible.

### Tasks

1. Add authorization boundaries per repository.
2. Improve ingestion resilience:
   - retries
   - deduplication
   - stale run detection
   - same-repo/branch ingestion locking
3. Add admin/ops visibility:
   - failed ingestions
   - job history
   - token usage
   - API failures
   - skipped/no-op syncs
4. Add benchmark seed repositories for demos.
5. Prepare capstone walkthrough scenarios:
   - explain payment flow
   - find Sidekiq usage
   - analyze Order model change impact
   - generate architecture summary
6. If time remains, add PR Review Assistant as an extension phase, not part of critical path.

### Acceptance criteria

- demo flows run consistently
- operational failures are diagnosable
- core claims can be demonstrated live

---

## 5. Recommended Sequential Task Breakdown

Use this execution order at the ticket level.

1. Rails app bootstrap and dependencies
2. RSpec/Rubocop/Sidekiq/pgvector setup
3. Base service/job/logging patterns
4. Repository and ingestion schema
5. Repository creation UI and tracked-branch flow
6. Clone service and ingestion job orchestration
7. Ingestion status, retry, and re-sync flow
8. File scanner and file indexing
9. Ruby parser and Rails entity extraction
10. JS/TS parser support
11. Route extraction
12. Relationship extraction
13. Chunking engine
14. Embedding generation jobs
15. Vector similarity search
16. Assistant retrieval/context builder
17. Conversation UI and answer persistence
18. Dependency graph normalization
19. Impact analysis engine
20. Architecture explorer UI
21. Documentation generation
22. Export/download support
23. Observability and hardening pass
24. Demo data and capstone script

This order is intentional. It prevents building UI-heavy or AI-heavy features on top of unstable ingestion and weak repository facts.

---

## 6. Suggested Ticket Groups

### Group A — Platform Setup

- app bootstrap
- infra dependencies
- quality tooling
- base patterns

### Group B — Repository Intelligence

- ingestion
- branch tracking
- multi-repo isolation
- parsing
- entities
- routes
- relationships

### Group C — Retrieval and AI

- chunking
- embeddings
- vector search
- assistant orchestration

### Group D — Analysis and Reporting

- dependency graph
- impact analysis
- architecture explorer
- documentation generation

### Group E — Production Readiness

- auditability
- resilience
- observability
- demo readiness

---

## 7. Test Strategy

### Unit tests

- service objects
- parser adapters
- chunking rules
- retrieval ranking logic
- impact analysis logic

### Job tests

- ingestion orchestration
- retry/idempotency behavior
- embedding pipeline

### Request/system tests

- repository submission flow
- ingestion status page
- assistant Q&A flow
- architecture explorer
- documentation generation

### Contract tests

- OpenAI client wrapper
- GitHub integration wrapper
- parser adapter interfaces

### Critical edge cases

- invalid GitHub URL
- clone failure
- empty repository
- very large repository
- unsupported file types
- duplicate ingestion request
- overlapping ingestion for same repo/branch
- branch changed with deleted files
- unchanged branch SHA producing no-op sync
- partially failed embedding run
- ambiguous dependency detection

---

## 8. Technical Standards

The implementation should follow these rules throughout:

- keep controllers thin
- keep models persistence-focused
- use explicit service objects for workflows
- isolate external APIs behind adapters/clients
- make jobs idempotent and restart-safe
- prefer append-only audit events for lifecycle tracking
- persist enough metadata to explain AI outputs
- never let LLM output be the only source of truth for architecture claims
- keep assistant retrieval strictly filtered by `repository_id` and tracked branch snapshot context

---

## 9. Explicitly Deferred From MVP

- private repository authentication
- GitHub App installation flow
- webhook-based automatic re-ingestion
- polling-based sync automation
- multi-branch indexing
- cross-repository search or assistant queries
- PR Review Assistant

These are valid follow-up features, but they should not dilute the quality of the first implementation.

---

## 10. Final Build Recommendation

For the capstone, the strongest deliverable is not “chat with code”. It is:

1. ingest repository reliably
2. extract architecture facts
3. retrieve relevant code semantically
4. answer questions with evidence
5. analyze change impact using a dependency graph
6. generate documentation from the same knowledge base

That is the correct build sequence for a serious Rails monolith and the most defensible implementation path for this project.
