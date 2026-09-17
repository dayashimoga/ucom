# Changelog — UNICOM AI

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-09-17

### Added
- Modular monorepo architecture with clean layer separation (`contracts`, `shared`, `ai_core`, `reporting`, `model_runtime`, `apps/unicom`).
- Offline-First core pipeline: LISTEN → TRANSCRIBE → DETECT LANGUAGE → TRANSLATE → UNDERSTAND → EXPLAIN → RESPOND → REMEMBER → SUMMARIZE → REPORT → LEARN.
- Pure on-device translation engine and multi-lingual phrasebook supporting 10 languages (EN, ES, FR, DE, ZH, JA, AR, HI, PT, RU).
- Multi-perspective Explanation Engine providing 7 personas (Simple, Detailed, Terminology, Grammar, Cultural Context, Examples, Child-Friendly).
- Real-time NLP Conversation Extractor (Questions, Action Items, Decisions, Topics).
- Interview Practice and Evaluation Engine with rubric scoring, STAR analysis, and study plans.
- Multi-format Reporting Engine (Quick/Detailed Summaries, Full Transcript, Minutes, Questions, Learning, Vocabulary, Action Items, and binary PDF generator).
- Model and Language Pack Manager with SHA-256 checksum verification.
- Adaptive Flutter UI with responsive layouts across Phone (320px–430px), Tablet (800px–1280px), and Desktop (1080p+).
- Podman-native development environment, Containerfile, and Compose.
- Complete deterministic test suites achieving 93.31% line and branch coverage.
- Full security documentation (STRIDE Threat Model) and CycloneDX SBOM generator.
