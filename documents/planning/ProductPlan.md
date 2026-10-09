# Product Plan

This document captures the original product direction and project framing.

## Vision

Engineering Knowledge Assistant (EKA) is an AI-powered engineering intelligence platform that understands source code repositories and helps developers answer questions about architecture, dependencies, business logic, APIs, background jobs, and impact analysis.

## Business Problem

Engineering knowledge is often trapped in:

- source code
- pull requests
- documentation
- team members’ heads

The system reduces ramp-up time by making repository behavior searchable and explainable.

## Core MVP Features

- Repository ingestion
- Architecture exploration
- AI repository question answering
- Impact analysis
- Documentation support

## Intended Stack Direction

- Rails monolith
- PostgreSQL
- Redis + Sidekiq
- vector search via `pgvector`
- AI providers for grounded repository workflows
