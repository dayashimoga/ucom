# ADR-003: Local-First Storage & Structured Logging Privacy

## Status
Accepted

## Context
Conversation histories and transcripts contain Personally Identifiable Information (PII) and intellectual property. Standard application logging often accidentally serializes full network payloads or speech transcripts into log files or telemetry backends.

## Decision
1. **Local-First Persistence**: Conversation transcripts, explanations, and extracted items are stored locally in the client storage repository (`StorageProvider`).
2. **Privacy Logging Guard**: The `PrivacyLogger` automatically redacts fields named `text`, `originalText`, `translatedText`, `content`, `candidateAnswer`, `audio`, and `apiKey`, replacing them with `[REDACTED_CONTENT]`.
3. **Data Retention Controls**: Users can clear local conversation caches, search history, or exported reports at any time directly through Settings.

## Consequences
- **Positive**: Complete compliance with privacy regulations; eliminates data leakage vectors in log aggregators.
- **Negative**: Cloud multi-device synchronization requires explicit opt-in and end-to-end encrypted storage adapters.
