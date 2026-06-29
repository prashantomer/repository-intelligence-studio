# Build Progress

## Project

- Name: `Engineering Knowledge Assistant`
- Build mode: step-by-step with review after each step
- Active scope: public repositories, repository-scoped assistant, single tracked branch per repository, project-agnostic repository support

## Progress Log

### Step 19 — Dependency graph edge foundation

- Status: `completed`
- Goal:
  - start Phase 5 by normalizing current extracted relationships into a dedicated graph edge layer
  - make dependency graph readiness visible on the repository workspace
- Output:
  - added `dependency_edges` persistence and `DependencyEdge` model
  - added `Codebase::DependencyEdgeBuilderService` to normalize entity relationships and route-to-controller links
  - wired dependency edge rebuilding into repository indexing
  - surfaced dependency edge totals and edge-type breakdown on the repository overview page
- Notes:
  - this is the graph foundation step, not the full impact-analysis feature yet
  - next Phase 5 step should add traversal queries and impact-oriented lookup services

### Assistant Context Upgrade — Conversation-aware repository Q&A

- Status: `completed`
- Goal:
  - make follow-up questions keep thread context instead of behaving like isolated one-off prompts
  - improve retrieval quality for short or referential questions such as `what about holdings?` or `tell me more`
- Output:
  - added `app/services/assistant/conversation_context_service.rb` to build recent thread transcript and a context-aware retrieval query
  - updated answer generation to pass recent conversation context into retrieval, provider prompting, and local fallback answers
  - updated the assistant job path so background generation excludes the pending placeholder and uses the active conversation thread
  - updated the composer hints to make thread-context reuse explicit in the UI
- Notes:
  - repository chunks remain the source of truth; prior messages are used only to resolve follow-up references
  - this improves continuity for repository conversations without turning the assistant into a generic ungrounded chat

### UI Refresh Step 7 — Repository overview tabs

- Status: `completed`
- Goal:
  - replace the long repository overview card stack with an in-page tabbed workspace
  - keep the repository page compact while still exposing details, ingestion, config, audit, and actions
- Output:
  - replaced the overview two-column stack with in-page overview tabs
  - added lightweight JavaScript tab switching for repository overview sections
  - grouped content into `Details`, `Ingestion`, `Config`, `Audit`, and `Actions`
- Notes:
  - this keeps the repository page flatter and more admin-panel-like without needing new routes
  - repository-level top navigation to `Overview`, `Assistant`, and `Search` remains unchanged

### UI Refresh Step 6 — Admin-panel polish across app

- Status: `completed`
- Goal:
  - propagate the tighter admin-panel density from the repositories index across the rest of the app
  - reduce bulky spacing, narrative copy, and oversized panels on assistant, search, settings, and forms
- Output:
  - tightened shared shell spacing, sidebar density, button scale, card padding, and form controls
  - converted assistant, search, settings, and repository setup screens to compact shared headers
  - reduced assistant panel/chat/composer density and tightened search results into slimmer result rows
  - refreshed repository new/edit and centralized settings pages to match the admin-panel style
- Notes:
  - the app now shares one denser visual system instead of the earlier mixed dashboard/workspace feel
  - the repositories page remains the strongest admin-panel surface and now sets the tone for the rest of the UI

### UI Refresh Step 5 — Repository overview

- Status: `completed`
- Goal:
  - make the repository overview the primary operational workspace screen
  - separate core repository/sync information from supporting configuration and audit context
- Output:
  - reorganized overview into a main content column and supporting side column
  - elevated latest ingestion and recent sync history into the primary reading path
  - moved assistant, embeddings, audit log, and quick actions into compact support panels
  - added overview-specific layout helpers and compact support-panel styling
- Notes:
  - repository overview now acts as the canonical repository workspace layout
  - dedicated `Ingestions` and `Logs` pages remain future enhancements; overview still surfaces that information now

### UI Refresh Step 4 — Repositories index

- Status: `completed`
- Goal:
  - replace the old hero-heavy repositories landing screen with a denser operational index
  - improve scanability of repository status, AI configuration, and ingestion footprint
- Output:
  - replaced the index hero section with shared workspace header and compact metric row
  - converted repository listing into row-based operational cards instead of large generic cards
  - added index-specific toolbar and repository row styles for denser scanning
- Notes:
  - the repositories page now behaves more like a control surface than a landing page
  - filtering and sorting controls are still deferred; this step focuses on layout and hierarchy only

### UI Refresh Step 3 — Shared page primitives

- Status: `completed`
- Goal:
  - introduce reusable workspace-level UI primitives before page-by-page screen refresh
  - establish shared repository tab navigation and compact metric/header patterns
- Output:
  - added shared partials:
    - `app/views/shared/_page_header.html.erb`
    - `app/views/shared/_repository_tabs.html.erb`
    - `app/views/shared/_metric_row.html.erb`
  - added shared CSS primitives for:
    - workspace headers
    - repository sub-navigation tabs
    - compact metric rows
    - standard panel/timeline helper classes
  - wired repository tabs and shared headers into:
    - repository overview
    - repository assistant
    - repository search
- Notes:
  - `Ingestions` and `Logs` are intentionally shown as disabled future tabs for structural consistency
  - deeper page layout refresh remains for the next screen-specific steps

### Step 1 — Rails application bootstrap

- Status: `completed`
- Goal: create the base Rails monolith in the current workspace
- Output:
  - Rails app skeleton
  - PostgreSQL configuration baseline
  - existing planning documents preserved
- Notes:
  - local shell defaults to system Ruby `2.6`, so Rails commands are being run explicitly with RVM Ruby `3.3.4`
  - app scaffold generated with `rails new . --force --database=postgresql --skip-bundle --skip-git`
  - no dependency installation or app execution has been done yet

## Current State

- Rails version in `Gemfile`: `8.1.3`
- Ruby version in `.ruby-version`: `3.3.4`
- Default frontend stack: `Hotwire` + `importmap`
- Database adapter: `PostgreSQL`
- Current embedding storage baseline: `1024` dimensions for `local` / `Ollama`
- Existing planning docs kept:
  - `Plan.md`
  - `BuildActionPlan.md`

### Step 16 — Ollama-first embedding storage alignment

- Status: `completed`
- Goal:
  - align the current fixed vector storage to `1024` dimensions
  - make `local` and `Ollama` the supported embedding providers on the present schema
  - defer provider-portable dimension routing as an advanced enhancement
- Output:
  - added migration to rebuild `code_chunks.embedding` for `vector(1024)`
  - updated deterministic local embeddings to emit `1024`-dimension vectors
  - marked `OpenAI` embeddings unsupported on the current storage baseline
  - updated model defaults and settings UI guidance toward `Ollama`
  - verified live database column type is `vector(1024)`
- Validation:
  - `ruby -c` passed for the changed Ruby files
  - `bundle exec rails db:migrate` completed successfully
  - `bundle exec rails runner` confirmed:
    - `Embeddings::TextEmbeddingService::VECTOR_SIZE == 1024`
    - deterministic local embeddings emit `1024` values
- Notes:
  - repositories must be re-synced after this migration to rebuild stored vectors
  - assistant providers remain independent from embedding storage and still support `OpenAI` / `Anthropic` / `Ollama`
  - provider-portable dimension routing remains deferred to a later enhancement

### Step 17 — Forced manual re-sync

- Status: `completed`
- Goal:
  - make manual `Re-sync` bypass SHA-based skip behavior
  - preserve normal skip optimization for automatic or initial ingestions
- Output:
  - manual `Re-sync` now queues ingestions with `force_rebuild = true`
  - ingestion processing now ignores unchanged-commit skip checks for forced runs
  - added schema support for per-ingestion force flags
- Validation:
  - `ruby -c` passed for controller, model, service, job, and migration changes
  - `bundle exec rails db:migrate` added `repository_ingestions.force_rebuild`
  - `RepositoryIngestions::StartService.call(repository:, force: true)` produced an ingestion with `force_rebuild = true`
- Notes:
  - initial/automatic ingestion keeps existing SHA skip optimization
  - manual button behavior is now explicitly forceful
  - missing ingestion records are skipped cleanly by the job to avoid noisy retries

### Step 18 — Clone workspace cleanup

- Status: `completed`
- Goal:
  - remove downloaded repository workspaces after ingestion completes or fails
  - avoid stale clone accumulation under the ingestion workspace root
- Output:
  - ingestion processing now wraps clone usage in guaranteed cleanup logic
  - successful and failed ingestion runs both remove the per-ingestion clone directory
  - empty per-repository workspace directories are removed after child cleanup

### Step 19 — Assistant typing-state and live updates

- Status: `completed`
- Goal:
  - replace blocking assistant redirects with a more realistic async chat flow
  - show immediate typing/pending state while background generation runs
- Output:
  - added repository-scoped Turbo stream subscription for assistant chat updates
  - added queued assistant question flow with pending assistant placeholder messages
  - added `AssistantResponseJob` to finalize assistant replies asynchronously
  - added message `response_state` tracking for `pending`, `completed`, and `failed`
  - enabled importmap/Turbo client loading in the application layout
  - updated assistant UI with typing shimmer, send-state handling, and live message replacement
- Validation:
  - `ruby -c` passed for the new service, job, model, controller, and migration files
  - `bundle exec rails db:migrate` added `messages.response_state`
  - `Assistant::QueueQuestionService.call(...)` created a pending assistant message successfully
- Notes:
  - this is live async replacement, not token-by-token provider streaming yet
  - true provider token streaming can be added later on top of the same chat transport

### Step 20 — Additional Turbo-driven UI updates

- Status: `completed`
- Goal:
  - reduce page reloads for common repository and settings interactions
  - move more mutations and searches to in-place async updates
- Output:
  - repository `Force Re-sync` now updates the dashboard in place via Turbo Streams
  - AI settings save now refreshes the settings screen and flash messages in place
  - semantic search now runs inside a Turbo Frame without a full page reload
  - settings model-picker behavior was moved into shared app JavaScript so Turbo replacements keep working
- Validation:
  - `ruby -c` passed for the updated controllers
  - Turbo Stream templates added for repository re-sync and settings save flows
- Notes:
  - repository create/update still use redirect-based navigation
  - search hero summary remains static while the frame updates the workspace/results area

## Next Proposed Step

### Step 2 — Foundation gem and runtime setup

- Status: `completed`
- Goal:
  - replace default queue/cable choices with project-required stack
  - add `sidekiq`, `redis`, `pgvector`, `rspec-rails`, and supporting gems
  - prepare the app for the foundation phase in `BuildActionPlan.md`
- Output:
  - removed Rails default `solid_queue` and `solid_cable` path from the base scaffold
  - added `sidekiq`, `redis`, `pgvector`, `dotenv-rails`, and `rspec-rails`
  - set `ActiveJob` adapter to `:sidekiq`
  - switched Action Cable development/production config to Redis
  - simplified production database config back to a single PostgreSQL database
- Notes:
  - no `bundle install` has been run yet
  - no generators have been executed yet, so `RSpec` files and `Sidekiq` initializer are still pending

## Next Proposed Step

### Step 3 — Dependency install and foundation generators

- Status: `completed`
- Goal:
  - install bundle dependencies under Ruby `3.3.4`
  - generate `RSpec` setup
  - generate `Sidekiq` baseline config
  - confirm the app boots cleanly at the framework level
- Output:
  - installed project gems and generated `Gemfile.lock`
  - generated `RSpec` baseline files:
    - `.rspec`
    - `spec/spec_helper.rb`
    - `spec/rails_helper.rb`
  - added `Sidekiq` runtime baseline:
    - `config/initializers/sidekiq.rb`
    - `config/sidekiq.yml`
  - confirmed framework boot with `bundle exec rails runner 'puts "boot ok"'`
- Notes:
  - network access was required for `bundle install`
  - commands continue to use explicit Ruby `3.3.4`/Bundler paths because the shell default remains system Ruby `2.6`
  - no database has been created yet
  - no application domain code has been added yet

## Next Proposed Step

### Step 4 — Base project structure and foundation initializers

- Status: `completed`
- Goal:
  - add app-level service/query/presenter structure
  - add foundation initializers for `pgvector` and environment defaults
  - add base application service pattern
  - keep changes limited to project scaffolding, not domain features yet
- Output:
  - added shared service base classes:
    - `app/services/application_service.rb`
    - `app/services/application_result.rb`
  - added app structure placeholders:
    - `app/services`
    - `app/services/concerns`
    - `app/queries`
    - `app/presenters`
    - `app/lib`
  - added app configuration initializer:
    - `config/initializers/app_config.rb`
  - added `pgvector` load initializer:
    - `config/initializers/pgvector.rb`
  - extended filtered parameters for API/token-like secrets:
    - `config/initializers/filter_parameter_logging_extra.rb`
  - set `ApplicationJob` default queue to `default`
  - replaced placeholder `README.md` content with current project foundation status
- Notes:
  - repository workspace root now defaults to `tmp/repositories`
  - this step intentionally adds no domain models, migrations, or ingestion logic
  - framework boot still succeeds after the new initializers were added

## Next Proposed Step

### Step 5 — Repository and ingestion schema foundation

- Status: `completed`
- Goal:
  - create the first domain schema for repositories and ingestion runs
  - add base models for repository tracking
  - keep the step limited to data foundation, without clone or parser behavior yet
- Output:
  - added repository schema migration:
    - `db/migrate/20260622072500_create_repositories.rb`
  - added repository ingestion schema migration:
    - `db/migrate/20260622072600_create_repository_ingestions.rb`
  - added base models:
    - `app/models/repository.rb`
    - `app/models/repository_ingestion.rb`
  - added repository-level enums and validations for:
    - status
    - visibility
    - provider
  - added ingestion-level status enum and association to repository
  - added tracked branch defaulting from `default_branch`
  - verified model boot with `rails runner`
- Notes:
  - migrations have been created but not executed yet
  - no database instance has been created/configured yet
  - user/auth tables are intentionally deferred until repository access patterns are clearer
  - clone orchestration, ingestion locking, and retry logic are not implemented in this step

## Next Proposed Step

### Step 6 — Database creation and migration execution

- Status: `completed`
- Goal:
  - create the local development and test databases
  - run the initial schema migrations
  - confirm the first domain tables exist and the app boot remains clean
- Output:
  - created local databases:
    - `engineering_knowledge_assistant_development`
    - `engineering_knowledge_assistant_test`
  - ran initial migrations successfully
  - generated `db/schema.rb`
  - verified live tables exist:
    - `repositories`
    - `repository_ingestions`
  - verified both base models can query the database with zero records
- Notes:
  - local PostgreSQL access required elevated execution from this environment
  - migrations and model queries now work against the local database
  - `pgvector` extension has not been enabled yet because vector-backed tables are not introduced in this step

## Next Proposed Step

### Step 7 — Repository web flow skeleton

- Status: `completed`
- Goal:
  - add repository controller, routes, and basic views
  - support manual creation of public repository records
  - show repository list/detail pages backed by the new schema
- Output:
  - added repository controller:
    - `app/controllers/repositories_controller.rb`
  - added routes:
    - root -> repository index
    - repository index/new/create/show
  - added repository views:
    - `app/views/repositories/index.html.erb`
    - `app/views/repositories/new.html.erb`
    - `app/views/repositories/show.html.erb`
    - `app/views/repositories/_form.html.erb`
  - updated application layout to render flash messages
  - added first application-level styling for dashboard/forms/cards in:
    - `app/assets/stylesheets/application.css`
  - added request coverage for repository index and create flow:
    - `spec/requests/repositories_spec.rb`
  - verified routes and request spec pass
- Notes:
  - repository creation currently persists metadata only
  - no ingestion job is triggered yet after repository creation
  - repository detail page is ready to host ingestion status once the orchestration layer is added

## Next Proposed Step

### Step 8 — Ingestion orchestration foundation

- Status: `completed`
- Goal:
  - add repository ingestion service and job skeleton
  - create the first manual `Re-sync`/ingestion trigger path
  - persist ingestion lifecycle status changes and complete public-repo clone flow
- Output:
  - added audit logging schema and model:
    - `db/migrate/20260622100000_create_audit_logs.rb`
    - `app/models/audit_log.rb`
  - added ingestion job:
    - `app/jobs/repository_ingestion_job.rb`
  - added repository creation, metadata, clone, and ingestion services:
    - `app/services/repositories/create_service.rb`
    - `app/services/repositories/remote_metadata_fetcher.rb`
    - `app/services/repositories/clone_service.rb`
    - `app/services/repository_ingestions/start_service.rb`
    - `app/services/repository_ingestions/process_service.rb`
    - `app/services/audit_logs/record_service.rb`
  - added repository `Re-sync` route and controller action
  - repository creation now queues an initial ingestion record automatically
  - repository detail page now shows:
    - latest ingestion
    - recent ingestion history
    - recent audit log entries
  - test environment now uses the `:test` Active Job adapter
- Verification:
  - ran audit-log migration successfully
  - reran the existing repository request spec only
  - executed one real public-repository ingestion smoke test against:
    - `https://github.com/octocat/Hello-World.git`
  - confirmed end-to-end result:
    - remote default branch detected as `master`
    - tracked branch corrected from placeholder `main` to `master`
    - repository cloned into `tmp/repositories/...`
    - repository and ingestion finished with `completed` status
- Notes:
  - this completes **Phase 1** from the action plan at the current MVP level
  - parser, chunking, embeddings, and assistant features are still intentionally untouched
  - background execution is wired through `Sidekiq`, but the direct smoke test used the service synchronously for focused verification

## Phase Status

- `Phase 1 — Project setup, database schema, repository ingestion`: `completed`
- `Phase 2 — Parsing pipeline and metadata extraction`: `completed`

## Next Proposed Step

### Step 9 — Parser engine foundation

- Status: `completed`
- Goal:
  - add file indexing and repository file inventory models
  - begin the parser pipeline with project-agnostic indexing and Ruby-first extraction adapters
- Output:
  - added indexing schema:
    - `db/migrate/20260622113000_create_code_files.rb`
    - `db/migrate/20260622113100_create_entities.rb`
    - `db/migrate/20260622113200_create_repository_routes.rb`
  - added indexing models:
    - `app/models/code_file.rb`
    - `app/models/entity.rb`
    - `app/models/repository_route.rb`
  - extended `Repository` associations for:
    - `code_files`
    - `entities`
    - `repository_routes`
  - added codebase indexing services:
    - `app/services/codebase/file_inventory_service.rb`
    - `app/services/codebase/ruby_entity_extractor_service.rb`
    - `app/services/codebase/routes_extractor_service.rb`
    - `app/services/codebase/index_repository_service.rb`
  - wired parsing into the ingestion pipeline in:
    - `app/services/repository_ingestions/process_service.rb`
  - repository detail/list pages now show indexed file/entity counts
- Verification:
  - applied the new Phase 2 schema migrations
  - ran a local indexing smoke test against the current Rails app:
    - `55` code files
    - `45` entities
    - `1` route
    - `2` controller entities
  - ran one real public Ruby-repository ingestion smoke test against:
    - `https://github.com/ruby/rake.git`
  - confirmed end-to-end parse result:
    - ingestion `completed`
    - detected remote default branch `master`
    - `95` indexed files
    - `145` extracted entities
    - `0` routes
- Notes:
  - this is the **Phase 2 foundation**, not the full parsing phase
  - repository support is intended to be project-agnostic
  - relationship extraction is not implemented yet
  - JS/TS files are inventoried, but entity extraction currently targets Ruby only
  - route extraction is currently framework-specific and minimal

## Next Proposed Step

### Step 10 — Relationship extraction and richer framework-aware metadata

- Status: `completed`
- Goal:
  - add parser adapter boundaries for non-Rails repositories
  - extract initial generic and framework-aware relationships
  - improve framework-specific route extraction where supported
- Output:
  - added relationship schema and model:
    - `db/migrate/20260622123000_create_entity_relationships.rb`
    - `app/models/entity_relationship.rb`
  - extended models for relationship associations:
    - `app/models/repository.rb`
    - `app/models/entity.rb`
  - added parser adapter registry:
    - `app/services/codebase/entity_extractor_registry.rb`
  - added JS/TS entity extraction adapter:
    - `app/services/codebase/js_ts_entity_extractor_service.rb`
  - added generic relationship extraction service:
    - `app/services/codebase/entity_relationship_extractor_service.rb`
  - updated repository indexing pipeline to:
    - dispatch by language adapter
    - persist entity relationships
    - report relationship counts
  - repository list/detail pages now show relationship counts
- Verification:
  - applied the relationship migration successfully
  - ran one focused local indexing + relationship smoke test against the current Rails app
  - confirmed result:
    - `60` indexed files
    - `53` entities
    - `1` route
    - `135` relationships
    - `121` generic `references` relationships
- Notes:
  - repository parsing is now structurally project-agnostic at the adapter boundary
  - relationship inference is intentionally simple and name/reference based
  - JS/TS extraction is still lightweight and heuristic
  - framework-aware enrichments exist only where the current adapters can infer them safely

## Next Proposed Step

### Step 11 — Parser robustness and chunking foundation

- Status: `completed`
- Goal:
  - make parsing idempotent and more accurate across re-ingestion
  - add chunking schema and chunk generation
  - prepare the retrieval layer without introducing embeddings yet
- Output:
  - wrapped `IndexRepositoryService` pipeline in `ActiveRecord::Base.transaction`
  - improved token counting from whitespace-split to character-based approximation: `(text.length / 4.0).ceil`
  - enhanced audit logging to include chunk and entity metadata
  - full purge-and-recreate strategy now has transaction safety guarantees
  - all indexing operations are atomic—partial failures roll back completely
- Verification:
  - chunking schema migration applied successfully
  - local chunking smoke test result:
    - `63` indexed files
    - `57` entities
    - `82` chunks
    - `144` relationships
    - `25` file-level fallback chunks
  - real public-repository chunking smoke test against:
    - `https://github.com/ruby/rake.git`
  - confirmed end-to-end result:
    - ingestion `completed`
    - `95` indexed files
    - `145` entities
    - `147` chunks
    - `479` relationships
- Notes:
  - chunk generation is now part of the ingestion pipeline
  - chunking is structure-aware when entities exist and file-based as fallback
  - embeddings and retrieval are still not implemented yet

## Next Proposed Step

### Step 12 — Embeddings and retrieval foundation

- Status: `pending`
- Goal:
  - enable `pgvector`
  - store embeddings on chunks
  - add repository-scoped semantic retrieval without building the assistant yet
- Output:
  - added pgvector embedding migration:
    - `db/migrate/20260625110000_enable_pgvector_and_add_chunk_embeddings.rb`
  - extended chunk model with embedding scope:
    - `app/models/code_chunk.rb`
  - added embedding services:
    - `app/services/embeddings/text_embedding_service.rb`
    - `app/services/embeddings/generate_chunk_embeddings_service.rb`
    - `app/services/embeddings/vector_literal.rb`
  - added repository-scoped retrieval service:
    - `app/services/retrieval/semantic_search_service.rb`
  - wired embedding generation into ingestion pipeline:
    - `app/services/repository_ingestions/process_service.rb`
  - added repository search route and page:
    - `config/routes.rb`
    - `app/controllers/repositories_controller.rb`
    - `app/views/repositories/search.html.erb`
  - linked search from repository detail page
- Verification:
  - applied the pgvector migration successfully
  - local retrieval smoke test result:
    - `95` embedded chunks
    - `8` retrieved results
    - top result path: `app/helpers/application_helper.rb`
  - real public-repository end-to-end smoke test against:
    - `https://github.com/ruby/rake.git`
  - confirmed result:
    - ingestion `completed`
    - `147` embedded chunks
    - retrieval returned a top chunk from `lib/rake/thread_history_display.rb`
- Notes:
  - retrieval is repository-scoped and chunk-based
  - embeddings currently use a deterministic local embedding generator for development
  - OpenAI embedding API integration is still pending
  - PostgreSQL emits an `unknown OID` warning for the vector column, but retrieval and persistence are functioning through explicit vector SQL literals

## Next Proposed Step

### Step 13 — AI assistant foundation

- Status: `pending`
- Goal:
  - add conversations/messages schema
  - build repository-scoped question answering using retrieval results
  - keep answer generation local-first until OpenAI chat integration is added
- Output:
  - added conversation schema and models:
    - `db/migrate/20260625123000_create_conversations.rb`
    - `db/migrate/20260625123100_create_messages.rb`
    - `app/models/conversation.rb`
    - `app/models/message.rb`
  - extended repository associations with conversations
  - added assistant services:
    - `app/services/assistant/answer_question_service.rb`
    - `app/services/assistant/local_answer_service.rb`
  - added repository assistant routes and controller actions:
    - `assistant`
    - `ask`
  - added assistant page:
    - `app/views/repositories/assistant.html.erb`
  - linked repository detail page to assistant UI
- Verification:
  - applied the conversation/message migrations successfully
  - local assistant Q&A smoke test result:
    - response generation `true`
    - `2` messages persisted in conversation
    - `5` citations attached to assistant answer
    - answer content includes grounded retrieval summary
    - conversation title derived from the user question
- Notes:
  - assistant is repository-scoped
  - answer generation is currently local and retrieval-grounded, not OpenAI-generated yet
  - the conversation/message persistence layer is now in place for later OpenAI chat integration

## Current Status

- `Phase 1 — Project setup, database schema, repository ingestion`: `completed`
- `Phase 2 — Parsing pipeline and metadata extraction`: `completed`
- `Phase 3 — Embeddings and retrieval foundation`: `completed`
- `Phase 4 — AI assistant foundation`: `in_progress`

## Next Proposed Step

### Step 14 — Multi-provider AI configuration foundation

- Status: `completed`
- Goal:
  - add provider-backed AI adapters with support for:
    - `OpenAI`
    - `Anthropic`
    - `Ollama`
  - make provider/model selection configurable from the UI
  - keep the existing local mode as a fallback for development
- Output:
  - added repository-level AI settings migration:
    - `db/migrate/20260625140000_add_ai_settings_to_repositories.rb`
  - extended repository model with assistant/embedding provider configuration:
    - `app/models/repository.rb`
  - added repository edit/update flow for AI settings:
    - `config/routes.rb`
    - `app/controllers/repositories_controller.rb`
    - `app/views/repositories/edit.html.erb`
    - `app/views/repositories/_form.html.erb`
    - `app/views/repositories/show.html.erb`
  - added provider adapter layer:
    - `app/services/ai/http_json_client.rb`
    - `app/services/ai/provider_factory.rb`
    - `app/services/ai/providers/openai_client.rb`
    - `app/services/ai/providers/anthropic_client.rb`
    - `app/services/ai/providers/ollama_client.rb`
  - added provider-backed assistant answer generation:
    - `app/services/assistant/context_formatter.rb`
    - `app/services/assistant/provider_answer_service.rb`
    - `app/services/assistant/answer_question_service.rb`
  - updated embedding generation and semantic retrieval to use repository-configured embedding providers:
    - `app/services/embeddings/text_embedding_service.rb`
    - `app/services/embeddings/generate_chunk_embeddings_service.rb`
    - `app/services/retrieval/semantic_search_service.rb`
  - surfaced active assistant and embedding configuration on assistant/search pages
- Verification:
  - applied the AI settings migration successfully
  - Rails smoke check confirms provider factory wiring for `Ollama` assistant and `OpenAI` embeddings
  - local embedding smoke check returns a `1536`-dimension vector successfully
  - local assistant regression against indexed repository `rake` succeeds with `5` citations attached
- Notes:
  - assistant answers now support remote providers, but fall back to grounded local synthesis if the configured provider fails
  - embedding generation intentionally fails fast on provider/API issues to avoid silently mixing incompatible vector spaces
  - changing embedding provider or embedding model requires repository re-sync to rebuild chunk embeddings
  - Anthropic is supported for assistant responses only; embeddings remain `local`, `OpenAI`, or `Ollama`
  - remote provider calls depend on external credentials/runtime availability:
    - `OPENAI_API_KEY`
    - `ANTHROPIC_API_KEY`
    - local Ollama server

## Current Status

- `Phase 1 — Project setup, database schema, repository ingestion`: `completed`
- `Phase 2 — Parsing pipeline and metadata extraction`: `completed`
- `Phase 3 — Embeddings and retrieval foundation`: `completed`
- `Phase 4 — AI assistant foundation`: `completed`
- `Phase 5 — Production-grade provider execution and UX refinement`: `in_progress`

### Step 16 — UI refinement pass

- Status: `completed`
- Goal:
  - improve information hierarchy across repository, search, and assistant pages
  - make AI configuration and ingestion status easier to scan
  - unify page layout and styling for the current MVP
- Output:
  - rebuilt shared app styling system:
    - `app/assets/stylesheets/application.css`
  - added top-level application header shell:
    - `app/views/layouts/application.html.erb`
  - improved repository index dashboard presentation:
    - `app/views/repositories/index.html.erb`
  - redesigned repository detail view with hero stats, config summaries, and timeline cards:
    - `app/views/repositories/show.html.erb`
  - improved assistant workspace layout and citation presentation:
    - `app/views/repositories/assistant.html.erb`
  - improved semantic search page layout and result cards:
    - `app/views/repositories/search.html.erb`
- Verification:
  - reviewed updated ERB templates after patching for structural consistency
  - no broad test run was added to keep iteration cost low
- Notes:
  - UI remains server-rendered ERB with the existing Rails monolith structure
  - current repository index still computes per-repository counts inline; that is acceptable for MVP scale but can be optimized later

### Step 17 — Centralized user AI settings

- Status: `completed`
- Goal:
  - move AI assistant and embedding configuration from per-repository settings to centralized per-user settings
  - keep repository behavior inheriting from one user-owned configuration source
  - add a dedicated settings screen for managing those defaults
- Output:
  - added user ownership and centralized AI settings schema:
    - `db/migrate/20260625152000_create_users_and_assign_repository_owners.rb`
    - `app/models/user.rb`
  - added app-level current user resolution:
    - `app/controllers/application_controller.rb`
  - scoped repositories to the current user and removed repository-level AI setting edits from repository forms:
    - `app/models/repository.rb`
    - `app/controllers/repositories_controller.rb`
    - `app/services/repositories/create_service.rb`
    - `app/views/repositories/_form.html.erb`
  - added centralized AI settings management UI:
    - `app/controllers/settings_controller.rb`
    - `config/routes.rb`
    - `app/views/settings/edit.html.erb`
    - `app/views/layouts/application.html.erb`
    - `app/models/ai_model_catalog.rb`
    - `app/helpers/application_helper.rb`
  - updated repository, assistant, and search views to show inherited user settings:
    - `app/views/repositories/index.html.erb`
    - `app/views/repositories/show.html.erb`
    - `app/views/repositories/assistant.html.erb`
    - `app/views/repositories/search.html.erb`
  - associated conversations with the repository owner when new assistant threads are created:
    - `app/models/conversation.rb`
    - `app/services/assistant/answer_question_service.rb`
- Verification:
  - applied the user settings migration successfully
  - verified a default user exists and owns repositories
  - verified repositories inherit assistant and embedding settings from the centralized user configuration
- Notes:
  - the app still uses a single default current user because authentication has not been built yet
  - repository AI columns remain only as legacy fallback data; the active source of truth is now the user record
  - centralized settings now expose provider-aware suggested model lists while still allowing freeform model entry

## Next Proposed Step

### Step 15 — Provider execution hardening

- Status: `pending`
- Goal:
  - add environment-backed provider credential validation in the UI
  - improve provider-specific error messages and fallback visibility
  - add re-sync guidance/workflow when embedding settings change
  - run one real remote-provider integration path once credentials are available

### Step 15a — Provider readiness and capability guidance

- Status: `completed`
- Goal:
  - expose provider runtime readiness directly in the UI
  - clarify provider capability boundaries, especially assistant-only vs embedding-supported providers
  - improve provider-specific runtime error messages
- Output:
  - added provider capability profile helpers:
    - `app/models/ai_provider_profile.rb`
  - extended centralized AI settings readiness helpers:
    - `app/models/user.rb`
    - `app/controllers/settings_controller.rb`
  - improved provider-specific failure messages for assistant and embedding execution:
    - `app/services/assistant/provider_answer_service.rb`
    - `app/services/embeddings/text_embedding_service.rb`
  - updated AI settings UI with readiness, credential, and support guidance:
    - `app/views/settings/edit.html.erb`
- Verification:
  - reviewed the updated settings template and service error paths after patching
- Notes:
  - runtime readiness is currently environment-based (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`) and non-blocking
  - actual remote-provider execution still needs a credentialed integration check to fully complete Step 15

### Step 15b — Sidekiq logging enablement

- Status: `completed`
- Goal:
  - enable explicit Sidekiq runtime logging for background execution visibility
- Output:
  - configured Sidekiq server logger in:
    - `config/initializers/sidekiq.rb`
  - default behavior writes to:
    - `log/sidekiq.log`
  - optional stdout logging can be enabled with:
    - `SIDEKIQ_LOG_TO_STDOUT=true`
  - logger level set to:
    - `DEBUG`
- Verification:
  - configuration patched successfully
- Notes:
  - client-side Redis config remains unchanged
  - this enables runtime log capture once the Sidekiq worker process is started

### Step 15c — Ingestion execution idempotency guard

- Status: `completed`
- Goal:
  - prevent duplicate execution of the same ingestion record from re-running the ingestion pipeline body
- Output:
  - added ingestion processability helper:
    - `app/models/repository_ingestion.rb`
  - added a row-lock-backed execution claim at the start of ingestion processing:
    - `app/services/repository_ingestions/process_service.rb`
- Verification:
  - confirmed a previously `skipped` ingestion now returns successfully without changing timestamps or creating new audit logs
- Notes:
  - only `pending` ingestion records are now allowed to enter the processing path
  - repeated execution against a non-pending ingestion becomes a safe no-op

### Step 15d — Sidekiq duplicate lifecycle log reduction

- Status: `completed`
- Goal:
  - reduce confusing duplicate-looking Sidekiq/ActiveJob lifecycle lines in worker logs
- Output:
  - updated Sidekiq log formatter in:
    - `config/initializers/sidekiq.rb`
  - by default, wrapped `ActiveJob` duplicate lines are now filtered from `log/sidekiq.log`
  - full wrapped traces can be re-enabled with:
    - `SIDEKIQ_LOG_ACTIVEJOB_DUPLICATES=true`
- Verification:
  - configuration patched successfully
- Notes:
  - native Sidekiq lifecycle lines remain
  - this changes log presentation only; it does not affect job execution semantics

### Step 15e — Context-sensitive AI settings UI

- Status: `completed`
- Goal:
  - hide irrelevant provider-specific settings unless they are actually needed
  - make provider readiness/capability guidance update live when selections change
- Output:
  - added a reusable hidden-state utility in:
    - `app/assets/stylesheets/application.css`
  - updated centralized AI settings form logic in:
    - `app/views/settings/edit.html.erb`
  - `Ollama base URL` card now hides unless either provider is set to `Ollama`
  - provider status/help text now updates live as assistant and embedding providers change
- Verification:
  - reviewed updated UI logic and visibility rules after patching
- Notes:
  - this is presentation-layer hardening only; persisted settings behavior is unchanged

### Step 15f — Embedding mismatch guard for retrieval

- Status: `completed`
- Goal:
  - prevent repository search/assistant requests from crashing when stored chunk vectors were generated with a different embedding provider/model than the current settings
- Output:
  - added repository metadata for the embedding configuration used to build stored vectors:
    - `db/migrate/20260626073000_add_indexed_embedding_settings_to_repositories.rb`
    - `app/models/repository.rb`
  - persisted indexed embedding provider/model after embedding generation:
    - `app/services/embeddings/generate_chunk_embeddings_service.rb`
  - added semantic search guard and dimension-mismatch rescue:
    - `app/services/retrieval/semantic_search_service.rb`
- Verification:
  - applied the repository embedding metadata migration successfully
  - confirmed a true provider/model mismatch now returns a clean re-sync message instead of a `500`
- Notes:
  - this specifically addresses `different vector dimensions` failures caused by switching embedding provider/model without re-syncing the repository

### Step 15g — Re-sync skip logic honors embedding drift

- Status: `completed`
- Goal:
  - ensure manual re-sync does not skip when embedding provider/model changed, even if commit SHA is unchanged
- Output:
  - updated ingestion skip condition in:
    - `app/services/repository_ingestions/process_service.rb`
- Verification:
  - confirmed embedding drift makes `embedding_settings_aligned?` false, which now prevents the skip path
- Notes:
  - re-sync now requires both:
    - unchanged commit SHA
    - aligned indexed embedding settings
  - if either differs, ingestion continues and embeddings can be rebuilt

### Step 15h — Stale active ingestion recovery

- Status: `completed`
- Goal:
  - prevent old `pending`/active ingestion records from blocking future manual re-sync attempts indefinitely
- Output:
  - added stale-ingestion detection:
    - `app/models/repository_ingestion.rb`
  - updated re-sync start logic to auto-release stale active ingestions before queueing a new one:
    - `app/services/repository_ingestions/start_service.rb`
- Verification:
  - confirmed an old `pending` ingestion is automatically marked `failed` and a fresh `pending` ingestion is queued
- Notes:
  - active ingestions older than `10 minutes` are now treated as stale
  - stale-release action is audit logged before the new ingestion is enqueued

### Step 18 — Provider call audit logging

- Status: `completed`
- Goal:
  - record every provider call in the database for later inspection
  - capture usage, latency, success/failure, and estimated cost metadata for assistant and embedding operations
  - add a first internal log page backed by database records
  - defer realtime streaming/tailing UI until after the database-backed logger is stable
- Output:
  - added `provider_call_logs` persistence with repository/user/provider/model/usage/latency/cost fields
  - added `Ai::ProviderCallLogRecorder` and `Ai::CostEstimator` for structured provider audit capture
  - wired assistant provider calls and remote embedding calls into database logging
  - added internal `Provider Logs` page with repository/provider/operation/status filtering
  - added sidebar navigation entry for provider log review
- Validation:
  - `ruby -c` passed for the new model, controller, and logging service files
  - ERB parse check passed for `app/views/provider_call_logs/index.html.erb`
- Notes:
  - realtime log streaming is still deferred; this step is database-backed history only
  - local deterministic embeddings and local grounded answers are not logged as remote provider calls
  - apply the new migration before using the page in the running app
