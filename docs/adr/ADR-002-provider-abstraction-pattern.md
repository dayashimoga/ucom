# ADR-002: Replaceable Provider Abstraction Pattern

## Status
Accepted

## Context
AI speech models, translation engines, and LLM reasoning providers evolve rapidly. Tightly coupling the application layer to specific vendor APIs or specific native libraries creates vendor lock-in, increases maintenance friction, and makes deterministic automated testing difficult.

## Decision
We decouple the domain model from underlying execution engines by defining replaceable, typed provider interfaces in `packages/contracts`:
- `STTProvider`
- `TTSProvider`
- `TranslationProvider`
- `LanguageDetectionProvider`
- `LLMProvider`
- `EmbeddingProvider`
- `StorageProvider`
- `ModelManagerProvider`

Every provider exposes an `isOfflineCapable` boolean and adheres to standard data transfer contracts. High-fidelity deterministic fakes (`DeterministicFakeSTTProvider`, `DeterministicFakeTTSProvider`, `DeterministicFakeTranslationProvider`) are provided for testing, ensuring CI runs execute deterministically without external network requests or paid tokens.

## Consequences
- **Positive**: Modular swappability of AI backends; deterministic zero-cost CI testing; clean separation of concerns.
- **Negative**: Requires maintaining adapter wrappers across different engines.
