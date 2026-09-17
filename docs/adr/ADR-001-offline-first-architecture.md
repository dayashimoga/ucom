# ADR-001: Offline-First Architecture & Privacy Boundary

## Status
Accepted

## Context
Cross-language communication and intelligent conversation understanding frequently involve sensitive discussions: executive meetings, technical interviews, confidential strategy sessions, and personal dialogues. Standard speech and translation platforms transmit raw audio and transcripts to third-party cloud AI vendors, exposing users to eavesdropping, data harvesting, and regulatory non-compliance (GDPR, HIPAA, CCPA).

## Decision
We establish **Offline-First** as a foundational architectural invariant:
1. The default execution mode is `private_offline`.
2. All core pipeline stages—Speech-to-Text (STT), Language Detection, Translation, Multi-Perspective Explanations, NLP Extraction (questions, action items, topics), Audio Synthesis (TTS), and Report Generation—are fully capable of executing on-device without internet access.
3. Network calls in `private_offline` mode are treated as invariant violations: attempting external network communication throws an explicit `OfflineViolationException`.
4. Cloud enhancements (`hybrid` and `cloud` modes) must be explicitly enabled by user consent.

## Consequences
- **Positive**: Guaranteed zero data leakage in private mode; predictable low latency; operational resilience during network outages.
- **Negative**: Model size constraints on compact devices; requires managing on-device language packs and quantizations.
