# Centralized AI Settings

## Non-Technical View

### What this feature does

It gives each user one place to configure assistant and embedding behavior.

### What the user can control

- assistant provider
- assistant model
- embedding provider
- embedding model
- provider endpoint/base URL where relevant
- API key environment variable usage pattern

### What the user gets back

- one consistent AI configuration applied across repository features
- provider portability path across `Ollama`, `OpenAI`, and `Anthropic` at the configuration layer

### Why it matters

It centralizes model behavior and keeps repository features aligned with the active user configuration.

## Technical View

### Scope

Settings are user-level and shared across repositories unless repository-specific behavior is added later.

### Current behavior

- assistant and embedding settings are stored centrally per user
- model options are provider-aware in the UI
- free-form model entry remains available
- embedding storage currently assumes the active vector dimension baseline supported by the current table design

### Important implementation note

Changing embedding provider/model may require repository re-sync so stored vectors remain consistent with retrieval behavior.
