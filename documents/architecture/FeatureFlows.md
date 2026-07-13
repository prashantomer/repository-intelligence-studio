# Feature-Wise Technical Request / Response Flow

This document explains how each major feature works.

- low-paragraph
- request → processing → response
- graphical where useful
- focused on current MVP behavior

---

## 1. Repository Creation + Initial Ingestion

### Purpose

User adds a repository and the system builds its indexed knowledge base.

### Request / Response Flow

```mermaid
flowchart LR
    U[User] --> F[Repository Form]
    F --> C[RepositoriesController#create]
    C --> S[Repositories::CreateService]
    S --> DB[(Repository Record)]
    C --> J[RepositoryIngestions::StartService]
    J --> Q[RepositoryIngestionJob]
    Q --> CLONE[Clone Repository]
    CLONE --> INV[File Inventory]
    INV --> ENT[Entity Extraction]
    ENT --> REL[Relationship Extraction]
    REL --> CHUNK[Chunking]
    CHUNK --> EMBED[Embedding Generation]
    EMBED --> EDGE[Dependency Edge Build]
    EDGE --> IDX[(Indexed Repository Data)]
    IDX --> UI[Repository Overview]
```

### Input

- repository name
- GitHub URL
- default/tracked branch

### Output

- repository record created
- ingestion queued
- repository becomes searchable and analyzable after success

---

## 2. Manual Re-Sync

### Purpose

Refresh repository intelligence from the tracked branch.

### Flow

```text
User clicks Re-sync
→ RepositoriesController#resync
→ RepositoryIngestions::StartService(force: true)
→ RepositoryIngestionJob
→ rebuild indexed snapshot
→ update repository status + ingestion history
```

### Output

- new ingestion run
- refreshed chunks, entities, edges, embeddings

---

## 3. Repository Assistant

### Purpose

Ask repository questions and get grounded answers.

### Request / Response Flow

```mermaid
sequenceDiagram
    participant U as User
    participant UI as Assistant UI
    participant RC as RepositoriesController#ask
    participant QS as Assistant::QueueQuestionService
    participant JOB as AssistantResponseJob
    participant GEN as Assistant::GenerateAnswerService
    participant RET as Retrieval::SemanticSearchService
    participant LLM as Provider / Local Answer
    participant DB as Messages

    U->>UI: Ask question
    UI->>RC: POST /repositories/:id/ask
    RC->>QS: queue question
    QS->>DB: save user message
    QS->>DB: save pending assistant message
    QS->>JOB: enqueue background response job
    JOB->>GEN: generate grounded answer
    GEN->>RET: fetch relevant chunks
    RET-->>GEN: repository-scoped evidence
    GEN->>LLM: grounded prompt
    LLM-->>GEN: answer + usage
    GEN->>DB: replace pending message
    DB-->>UI: Turbo update
```

### Input

- natural-language repository question

### Output

- assistant answer
- citations / evidence
- conversation history
- provider usage logs

---

## 4. Semantic Search

### Purpose

Search indexed repository chunks by meaning, not exact keyword only.

### Flow

```text
User enters search query
→ RepositoriesController#search
→ Retrieval::SemanticSearchService
→ embed query with configured embedding provider
→ compare against stored chunk vectors
→ rank best-matching chunks
→ render search results
```

### Output

- top matching files/chunks
- line ranges
- chunk type

---

## 5. Impact Analyzer

### Purpose

Estimate what may be affected if a code entity changes.

### Request / Response Flow

```mermaid
flowchart TD
    U[User Question / Entity Input] --> INT[Impact Query Interpreter]
    INT --> RESOLVE[Resolve Target Entity]
    RESOLVE --> TQ[DependencyGraph::TraversalQuery]
    TQ --> UP[Upstream Entities]
    TQ --> DOWN[Downstream Entities]
    TQ --> ROUTES[Related Routes]
    TQ --> JOBS[Related Jobs]
    TQ --> FILES[Related Files]
    RESOLVE --> RET[Semantic Retrieval]
    RET --> EVID[Top Evidence Chunks]
    UP --> IA[ImpactAnalysisService]
    DOWN --> IA
    ROUTES --> IA
    JOBS --> IA
    FILES --> IA
    EVID --> IA
    IA --> NARR[ImpactNarrationService]
    NARR --> REP[(Impact Report)]
    REP --> UI[Impact Analyzer UI]
```

### Input

- direct entity name  
  `RepositoryIngestion`

- natural-language impact question  
  `What breaks if RepositoryIngestion changes?`

### Output

- resolved entity
- risk level
- upstream dependencies
- downstream dependents
- routes
- jobs
- impacted files
- evidence-backed summary
- narrated review guidance
- checklist
- saved impact report

### Good Inputs

- `What breaks if ApplicationController changes?`
- `Which files depend on RepositoryIngestion?`
- `What APIs use SettingsController?`
- `What jobs depend on AssistantResponseJob?`

### Weak Inputs

- `Impact of rework on design?`
- `How risky is refactoring this app?`

Reason:
- current analyzer is still **entity-centric**
- broad conceptual prompts need a concrete code target

---

## 6. Provider Logs

### Purpose

Track AI/embedding calls, usage, latency, and estimated cost.

### Flow

```text
Feature calls provider
→ Ai::ProviderCallLogRecorder
→ save provider, model, operation, tokens, latency, cost
→ Provider Logs page shows history
```

### Captured For

- assistant
- embeddings
- impact narration

### Output

- execution history
- debugging trail
- usage/cost visibility

---

## 7. Centralized AI Settings

### Purpose

User controls assistant + embedding providers from one place.

### Flow

```text
User opens AI Settings
→ selects provider/model/base URL
→ saves settings
→ repository features inherit current user-level config
→ assistant/search/impact use those settings at runtime
```

### Controls

- assistant provider
- assistant model
- embedding provider
- embedding model
- Ollama base URL

---

## 8. Saved Impact Report History

### Purpose

Keep reusable analysis snapshots.

### Flow

```text
Impact analysis succeeds
→ ImpactReport saved
→ History popup lists reports
→ user can:
   - open report
   - analyze again
   - jump to assistant
```

### Output

- reusable impact snapshots
- historical comparison base

---

## 9. System Boundaries

### Repository Scope

- every assistant/search/impact request runs for **one repository only**
- no cross-repository mixing in MVP

### Snapshot Scope

- answers use the latest successful ingested snapshot
- not the live remote repo at query time

### Current Limitation

- impact depth depends on extracted entities and dependency edges
- strongest on repos where extraction is richer

---

## 10. Quick Feature Map

| Feature | Input | Core Service Path | Output |
|---|---|---|---|
| Repository Create | GitHub repo info | `Repositories::CreateService` | repository record |
| Ingestion | repository + branch | `RepositoryIngestionJob` | indexed snapshot |
| Assistant | natural-language question | `Assistant::GenerateAnswerService` | grounded answer |
| Search | search query | `Retrieval::SemanticSearchService` | matching chunks |
| Impact Analyzer | entity / impact question | `TraversalQuery` + `ImpactAnalysisService` | risk + blast radius |
| AI Logs | provider call metadata | `Ai::ProviderCallLogRecorder` | usage/cost history |

---

## 11. Best Demo Order

If you want to explain the product quickly:

1. Add / ingest repository
2. Show repository overview
3. Ask assistant a repository question
4. Run semantic search
5. Run impact analysis
6. Open provider logs
7. Open saved impact history

