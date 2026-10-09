# Repository Intelligence Studio — Learning Guide

This guide is a practical path for understanding the AI-related parts of the project from request entry through retrieval, generation, persistence, and observability. Read the sections in order once, then revisit the sections that match the feature you want to extend.

## What You Will Understand

After completing this guide, you should be able to explain and modify:

- repository-scoped retrieval augmented generation (RAG)
- multi-provider assistant and embedding configuration
- semantic and exact-code search behavior
- deterministic answers versus provider-generated answers
- conversation context, Turbo updates, and background answer generation
- impact analysis using indexed repository relationships
- provider usage, latency, error, and cost logging

## The Product Mental Model

Each tracked repository is an independent knowledge boundary. The application ingests its files, extracts entities and relationships, splits code into chunks, and creates embeddings. The assistant, search, and impact analyzer query only that repository's indexed data.

```text
Repository URL
  -> ingestion
  -> files + entities + relationships + chunks + embeddings
  -> repository-scoped retrieval
  -> structured answer or AI-provider answer
  -> saved conversation/report + provider-call logs
```

## Recommended Study Order

| Order | Topic | Main question to answer | Start here |
| --- | --- | --- | --- |
| 1 | Request entry | How does a user action enter the system? | `app/controllers/repositories_controller.rb` |
| 2 | Assistant orchestration | How is one question routed to the correct answer path? | `app/services/assistant/generate_answer_service.rb` |
| 3 | Retrieval | How are relevant repository chunks selected? | `app/services/retrieval/semantic_search_service.rb` |
| 4 | Provider generation | How are prompts sent to Ollama, OpenAI, or Anthropic? | `app/services/assistant/provider_answer_service.rb` |
| 5 | Deterministic answers | When does the app answer directly from indexed metadata? | `app/services/assistant/structured_answer_service.rb` |
| 6 | Flow-aware answers | How does it narrate code paths and relationships? | `app/services/assistant/flow_answer_service.rb` |
| 7 | Ingestion foundation | Where do chunks, entities, and embeddings come from? | `app/jobs/repository_ingestion_job.rb` |
| 8 | Runtime configuration | How are providers and models selected per user? | `app/services/ai/provider_factory.rb` |
| 9 | Observability | Where are AI calls, latency, and usage recorded? | `app/services/ai/provider_call_log_recorder.rb` |
| 10 | Impact analysis | How does a proposed code change become an impact report? | `app/services/analysis/impact_analysis_service.rb` |

## Learning Path 1 — Follow a Single Assistant Question

Use a simple question such as: `How does repository ingestion work?`

1. Open `app/controllers/repositories_controller.rb` and find the `ask` action.
   - It creates or finds the conversation.
   - It saves the user message and a pending assistant response.
   - It queues the response work so the browser is not blocked.

2. Read `app/jobs/assistant_response_job.rb`.
   - This job calls `Assistant::GenerateAnswerService`.
   - It persists the completed answer or an error state.
   - Turbo Streams replace the pending message in the chat interface.

3. Read `app/services/assistant/generate_answer_service.rb` carefully.
   - This is the central router for assistant answers.
   - It first builds recent conversation context.
   - It tries structured answers, then flow-aware answers.
   - If neither applies, it retrieves chunks and calls the configured AI provider.
   - If a remote provider fails, it can use the local fallback answer path.

4. Read `app/services/assistant/conversation_context_service.rb`.
   - Notice the distinction between the visible user question and the retrieval query.
   - Follow-up questions reuse recent thread context to reduce ambiguity.

5. Read `app/services/assistant/provider_answer_service.rb`.
   - Inspect how repository context, retrieved chunks, citations, and answer instructions become a provider prompt.
   - Look for the response payload: answer text, citations, token counts, and metadata.

### Checkpoint

You should now be able to draw this flow:

```text
Chat form -> controller -> user message + pending message
-> background job -> GenerateAnswerService
-> structured / flow-aware / retrieval + provider
-> completed message -> Turbo Stream update
```

## Learning Path 2 — Understand Repository-Scoped RAG

RAG means the model is given retrieved project evidence before it writes an answer. In this application, it is repository-scoped: chunks from repository A are never used to answer a question for repository B.

Read `app/services/retrieval/semantic_search_service.rb` in this order:

1. `call`
   - validates that existing embeddings match the currently selected embedding configuration
   - runs semantic and keyword retrieval
   - merges and limits the final result set

2. `semantic_search_chunks`
   - calls `Embeddings::TextEmbeddingService` for the user query
   - uses pgvector distance ordering against `code_chunks.embedding`

3. `keyword_search_chunks`
   - supports exact and partial matches across chunk text, file path, language, entity name, and entity type
   - is particularly important for symbols such as `purge_existing_index!`

4. `merge_chunks`, `structured_query?`, and `keyword_score`
   - explain why code symbols receive keyword-first behavior while broader natural-language questions retain semantic ranking

Then trace the data models:

- `app/models/repository.rb` — the scope root
- `app/models/code_file.rb` — indexed source files
- `app/models/code_chunk.rb` — searchable code/document snippets and vectors
- `app/models/entity.rb` — detected classes, modules, services, jobs, controllers, and models
- `app/models/entity_relationship.rb` — links between entities

### Experiment

Search the same repository for both:

- `repository ingestion flow`
- `purge_existing_index!`

Compare the results. The first is semantic retrieval; the second should strongly favor exact indexed code evidence.

## Learning Path 3 — Learn Why Some Answers Do Not Need an LLM

Not every question should go to an AI model. Exact inventory requests are faster, cheaper, and more dependable when answered directly from structured indexed data.

Read `app/services/assistant/structured_answer_service.rb`.

Study these concepts:

- `INVENTORY_PATTERNS` recognizes narrow requests such as `list all services`.
- `SCOPING_PATTERNS` prevents overly broad questions such as `list services involved in chunking flow` from being incorrectly treated as a flat inventory.
- the service queries repository-scoped `entities` and builds citations from the related chunks.

Use this comparison:

| Question type | Expected answer path | Why |
| --- | --- | --- |
| `List all services` | Structured answer | The entity index can answer it directly. |
| `Which services are involved in chunking flow?` | Flow-aware/provider answer | It needs relationships, ordering, and explanation. |
| `How does ingestion work?` | Retrieval plus provider answer | It needs synthesized explanation from multiple files. |

## Learning Path 4 — Learn Flow-Aware Answers

Read `app/services/assistant/flow_answer_service.rb` after the structured-answer service.

This service improves questions involving terms such as flow, sequence, pipeline, execution, call, or cycle. It:

1. detects the requested entity type, such as `service` or `job`
2. extracts useful focus words from the question
3. scores matching entities using names, signatures, namespaces, and file paths
4. expands the set through repository entity relationships
5. orders selected entities into a useful path
6. passes the ordered evidence to the provider with instructions to explain names and file paths in sequence

The goal is not merely a list of services. It is a traceable explanation such as:

```text
StartService -> FileInventoryService -> ChunkingService -> TextEmbeddingService
```

with each component tied to a source path and a role in the flow.

## Learning Path 5 — Understand AI Providers and Settings

The app separates assistant generation from embedding generation. This is important because a chat model and an embedding model solve different problems.

Read these files together:

- `app/services/ai/provider_factory.rb`
- `app/services/ai/providers/ollama_client.rb`
- `app/services/ai/providers/openai_client.rb`
- `app/services/ai/providers/anthropic_client.rb`
- `app/models/ai_provider_profile.rb`
- `app/controllers/settings_controller.rb`

Learn these distinctions:

| Capability | Purpose | Typical provider choice |
| --- | --- | --- |
| Assistant generation | Writes grounded natural-language answers | Ollama, OpenAI, Anthropic |
| Embedding generation | Converts chunks and queries to vectors | Ollama or OpenAI; provider support depends on model capability |
| Provider profile | Holds user-level provider, model, endpoint, and credential references | Centralized per user |

### Important Rule

Changing the embedding provider or model changes the shape or meaning of vectors. A repository must be re-synced before its old chunks can be reliably searched with the new configuration.

## Learning Path 6 — Understand Ingestion Before Extending AI Features

All AI features depend on a good index. Follow an ingestion from start to finish.

Start with:

- `app/jobs/repository_ingestion_job.rb`
- `app/services/repository_ingestions/start_service.rb`
- `app/services/repository_ingestions/process_service.rb`
- `app/services/codebase/index_repository_service.rb`

Then find the services responsible for:

1. cloning or preparing the tracked branch
2. discovering files using the language configuration
3. creating `CodeFile` records
4. extracting entities and entity relationships
5. creating code chunks
6. generating and storing chunk embeddings
7. recording ingestion status and audit information
8. cleaning temporary workspaces after the run

Read `config/language_map.yml` to see how supported file types are configured without hard-coding them in a service.

## Learning Path 7 — Learn the Impact Analyzer

The impact analyzer is a blend of graph data, retrieval evidence, and AI narration.

Start with:

- `app/controllers/repositories_controller.rb` — the `impact` action
- `app/services/analysis/impact_query_interpreter_service.rb`
- `app/services/analysis/impact_analysis_service.rb`
- `app/models/impact_report.rb`
- `app/models/dependency_edge.rb`

Follow this sequence:

```text
Natural-language change request
-> identify target entity
-> traverse upstream/downstream relationships
-> collect related files, routes, and jobs
-> retrieve supporting chunks
-> optionally generate risk narration
-> save impact report
```

Try these inputs in the UI:

- `What breaks if RepositoryIngestion changes?`
- `Which files depend on RepositoriesController?`
- `What jobs use ApplicationJob?`

When a request does not identify a known entity, the analyzer correctly returns an unavailable state rather than inventing a result.

## Learning Path 8 — Observe Every Provider Call

Read:

- `app/services/ai/provider_call_log_recorder.rb`
- `app/models/provider_call_log.rb`
- `app/controllers/provider_call_logs_controller.rb`

For every assistant or embedding call, inspect the saved data:

- provider and model
- operation type and endpoint
- request/response metadata (without exposing sensitive credentials)
- prompt, completion, and total token counts where available
- latency
- estimated cost
- success or failure reason

This is the operational feedback loop for improving model choice, prompt quality, and cost control.

## Practical Extension Exercises

Work through these in increasing difficulty. Make each change on a small branch and add one focused test where the project already has coverage.

1. Add one language mapping in `config/language_map.yml` and confirm it is picked up during ingestion.
2. Add a new exact inventory pattern to `StructuredAnswerService`.
3. Improve keyword ranking for a code-symbol edge case in `SemanticSearchService`.
4. Add a new relationship weight in `FlowAnswerService` and compare its output before and after.
5. Add a provider/model option in the centralized settings UI without changing the provider contract.
6. Add a compact provider-log filter only if the existing controller already supports the required query scope.
7. Improve impact narration instructions while preserving evidence and citations.

## Debugging Checklist

When an AI-related feature looks wrong, debug in this order:

1. Is the repository ingestion completed for the intended branch?
2. Does the repository have files, chunks, entities, relationships, and embeddings?
3. Do the indexed embedding settings match the active user settings?
4. Did keyword retrieval find the exact code symbol?
5. Did the structured or flow-aware route intentionally handle the question first?
6. Did the provider call succeed, and what does `ProviderCallLog` show?
7. Did the pending message transition to completed or failed state?

## Useful Documentation

- [Repository Assistant](features/repository-assistant.md)
- [Semantic Search](features/semantic-search.md)
- [Repository Ingestion](features/repository-ingestion.md)
- [Impact Analyzer](features/impact-analyzer.md)
- [Centralized AI Settings](features/centralized-ai-settings.md)
- [Provider Logs](features/provider-logs.md)
- [Feature Flows](architecture/FeatureFlows.md)
- [Build Action Plan](planning/BuildActionPlan.md)
- [Build Progress](progress/BuildProgress.md)
