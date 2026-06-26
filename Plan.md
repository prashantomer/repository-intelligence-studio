This is probably the strongest capstone project for your profile because it combines:

* Rails expertise
* AI/RAG
* GitHub integrations
* Architecture analysis
* Business value for engineering teams

It can realistically score 4.0–4.5 on your rubric without requiring model fine-tuning.

Project Vision

Engineering Knowledge Assistant (EKA)

An AI-powered engineering intelligence platform that understands source code repositories and helps developers answer questions about architecture, dependencies, business logic, APIs, background jobs, and impact analysis.

Think:

* GitHub Copilot + Architecture Wiki
* Sourcegraph + AI
* Internal Engineering Assistant

for small and medium engineering teams.

⸻

Business Problem

Most engineering knowledge is trapped in:

* Source code
* Pull requests
* Documentation
* Team members’ heads

New developers spend weeks learning:

* Where code lives
* Which service owns what
* What breaks if something changes

EKA solves this.

⸻

MVP Features

Feature 1: Repository Ingestion

User connects GitHub repository.

System:

* Clones repo
* Parses files
* Extracts metadata

Stores:

{
  "classes": [],
  "modules": [],
  "controllers": [],
  "models": [],
  "jobs": [],
  "services": [],
  "routes": []
}

⸻

Feature 2: Architecture Explorer

Automatically generates:

Components

Controllers
 ↓
Services
 ↓
Models
 ↓
Database

Dependency Graph

Example:

OrderController
 ↓
OrderService
 ↓
PaymentService
 ↓
StripeGateway

⸻

Feature 3: AI Question Answering

Questions:

How is payment processed?
Where is Sidekiq used?
Which services touch Orders?
How are refunds handled?

Uses:

* Repository metadata
* Semantic search
* LLM reasoning

⸻

Feature 4: Impact Analysis

Questions:

What files are affected if I change Order?
What can break if I modify PaymentProcessor?
Which APIs depend on User model?

This impresses evaluators.

⸻

Feature 5: Documentation Generator

Generate:

* API docs
* Architecture docs
* Module summaries

Export:

* Markdown
* PDF

⸻

Tech Stack

Backend

Rails 8

Ruby 3.3+

PostgreSQL

Sidekiq

Redis

⸻

Frontend

Rails + React

or

Rails + Hotwire

For capstone:

Hotwire is sufficient.

⸻

AI Layer

OpenAI GPT-5.x

Embedding Model

Vector Search

Options:

Easy

pgvector

Better

Qdrant⁠￼

Use pgvector initially.

⸻

Repository Processing

Libraries:

Ruby:

rugged
parser
yard

⸻

Background Processing

Sidekiq

Pipeline:

Repo Imported
↓
Clone
↓
Parse
↓
Chunk
↓
Embed
↓
Store

⸻

Architecture

Github Repo
     |
     V
Repository Importer
     |
     V
Code Parser
     |
     +----------------+
     |                |
     V                V
Metadata DB      Vector DB
     |                |
     +--------+-------+
              |
              V
      Knowledge Engine
              |
              V
        AI Assistant

⸻

Database Design

repositories

name
github_url
branch
status

⸻

code_files

repository_id
path
language
content_hash

⸻

code_chunks

repository_id
file_id
chunk_text
embedding

⸻

entities

repository_id
entity_type
# controller
# model
# service
# job
name
metadata

⸻

conversations

repository_id
user_id
question
answer

⸻

AI Pipelines

Pipeline 1

Repository Understanding

Clone
↓
Parse AST
↓
Extract entities
↓
Chunk code
↓
Generate embeddings
↓
Store

⸻

Pipeline 2

Question Answering

Question
↓
Embedding
↓
Similarity Search
↓
Relevant Chunks
↓
Context Builder
↓
GPT
↓
Answer

⸻

Pipeline 3

Impact Analysis

Entity
↓
Dependency Graph
↓
Related Files
↓
AI Reasoning
↓
Impact Report

⸻

Capstone Differentiator

Most projects stop here:

Upload docs
↓
Chatbot

Do NOT do that.

Instead build:

Repository
↓
Code Intelligence
↓
Dependency Graph
↓
Impact Analysis
↓
Architecture Generation
↓
AI Assistant

That moves you from a 3/5 project to a 4+/5 project.

⸻

Master Prompt For Coding Agent

Use this as the initial prompt.

⸻

You are a Staff Engineer responsible for building a production-grade AI Engineering Knowledge Assistant from scratch.

Goal:
Build a Rails 8 application that ingests GitHub repositories and provides AI-powered codebase understanding, architecture exploration, documentation generation, semantic search, and impact analysis.

Requirements:

1. Tech Stack
    * Ruby 3.3+
    * Rails 8
    * PostgreSQL
    * pgvector
    * Redis
    * Sidekiq
    * Hotwire/Turbo
    * OpenAI APIs
2. Core Features
    Repository Ingestion:
    * Connect public/private GitHub repositories
    * Clone repositories asynchronously
    * Track ingestion status
    Code Parsing:
    * Parse Ruby, JavaScript, TypeScript files
    * Extract:
        * Controllers
        * Models
        * Services
        * Jobs
        * Modules
        * Routes
    * Store metadata in PostgreSQL
    Semantic Search:
    * Chunk code intelligently
    * Generate embeddings
    * Store embeddings using pgvector
    * Support similarity search
    AI Assistant:
    * Natural language questions about codebase
    * Retrieval Augmented Generation
    * Context-aware answers
    Impact Analysis:
    * Analyze dependencies
    * Determine affected files/components
    * Generate risk summaries
    Architecture Explorer:
    * Visualize relationships
    * Generate architecture summaries
    Documentation Generator:
    * Generate markdown documentation
    * Generate architecture reports
3. Non Functional Requirements
    * Service object architecture
    * Background jobs for long-running tasks
    * Event-driven design where appropriate
    * Comprehensive RSpec coverage
    * Rubocop compliance
    * SOLID principles
    * Scalable ingestion pipeline
    * Audit logging
    * Error tracking
    * Idempotent jobs
4. Deliverables
    Phase 1:
    * Project setup
    * Database schema
    * Repository ingestion
    Phase 2:
    * Parser engine
    * Metadata extraction
    Phase 3:
    * Embedding generation
    * Semantic search
    Phase 4:
    * AI assistant
    Phase 5:
    * Dependency graph
    * Impact analysis
    Phase 6:
    * Documentation generation
5. Output Format

For every phase provide:

* Architecture decisions
* Database changes
* Folder structure
* Models
* Services
* Jobs
* Tests
* API endpoints
* UI pages
* Acceptance criteria

Generate implementation incrementally and production-ready rather than as a tutorial.

⸻

If this is for a company capstone review, I would add one more feature: “Pull Request Review Assistant” (AI-generated code review comments and risk detection). That single addition often elevates the perceived business impact because reviewers immediately understand the ROI.