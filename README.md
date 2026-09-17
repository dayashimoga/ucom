# UNICOM AI — Universal Communication Intelligence

<div align="center">

> *"Understand anyone. Speak to anyone. Remember what matters. Learn from every conversation."*

[![CI](https://github.com/unicom-ai/unicom/actions/workflows/ci.yml/badge.svg)](https://github.com/unicom-ai/unicom/actions/workflows/ci.yml)
[![Coverage: 93.31%](https://img.shields.io/badge/Coverage-93.31%25-brightgreen.svg)](tests/coverage/lcov.info)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Podman Ready](https://img.shields.io/badge/Podman-Compatible-purple.svg)](infrastructure/podman/podman-compose.yml)

</div>

---

## Executive Summary

**UNICOM AI** is an offline-first, multiplatform universal communication platform engineered to eliminate language barriers while maintaining an uncompromised privacy boundary.

### Core Intelligence Pipeline

```mermaid
flowchart LR
    A[LISTEN] --> B[TRANSCRIBE]
    B --> C[DETECT LANG]
    C --> D[TRANSLATE]
    D --> E[UNDERSTAND]
    E --> F[EXPLAIN]
    F --> G[RESPOND]
    G --> H[REMEMBER]
    H --> I[SUMMARIZE]
    I --> J[REPORT]
    J --> K[LEARN]
```

### Key Capabilities
- **On-Device Offline Translation**: Zero network dependencies for top 10 global languages (EN, ES, FR, DE, ZH, JA, AR, HI, PT, RU) with morphology preservation and formality tuning.
- **Multi-Perspective Explanations**: 7 distinct reasoning personas for every statement:
  1. `Simple`: Direct essence, jargon-free.
  2. `Detailed`: Syntactic breakdown, communicative nuance.
  3. `Terminology`: Identification and domain definitions.
  4. `Grammar`: Clauses, moods, and structural concord.
  5. `Cultural Context`: Pragmatic etiquette and cross-cultural acceptability.
  6. `Examples`: Professional, conversational, and collaborative scenarios.
  7. `Child-Friendly`: Playful, cheerful analogies.
- **Conversation Extraction Intelligence**: Real-time identification of questions, answers, unresolved items, action items with assignees, and decisions.
- **Dedicated Application Modes**:
  - **Live Conversation**: Split-view real-time bilingual dialogue.
  - **Interview Practice**: STAR-method evaluation, rubrics (clarity, depth, structure, delivery, correctness), follow-up drills, and study plans (strictly non-covert, transparent coaching).
  - **Meeting Intelligence**: Speaker attribution, live agenda tracking, and instant Meeting Minutes.
  - **Education & Travel**: Targeted grammar and survival phrase cards.
- **Multi-Format Reporting Engine**: Generates 9 structured reports with one-click export to **PDF (binary standard)**, **Markdown**, **JSON**, and **Plain Text**.
- **Privacy Tiers**:
  - `Private / Offline`: 0% data leak. External network attempts throw `OfflineViolationException`.
  - `Hybrid`: Local-first with explicit user opt-in for cloud extensions.
  - `Cloud`: Enterprise cloud enhanced.
- **Model & Language Pack Manager**: Cryptographic SHA-256 verification, lazy loading, and unconsented download prevention.

---

## Architectural Layout

```
h:/unicom/
├── apps/
│   └── unicom/                     # Flutter Adaptive Multiplatform Application
│       ├── lib/
│       │   ├── app/                # Shell, router, Material 3 design tokens
│       │   ├── features/           # Conversation, Interview, Meeting, Reports, Models, Settings
│       │   ├── providers/          # Local in-memory & SQLite storage adapters
│       │   └── ui/adaptive/        # Phone (320-430px), Tablet (800-1280px), Desktop (1080p+)
│       ├── android/                # Native Android Gradle configuration (APK & AAB)
│       ├── web/                    # PWA HTML5 web shell & manifest
│       ├── windows/                # Windows native CMake runner
│       ├── linux/                  # Linux GTK CMake runner
│       └── macos/                  # macOS native configurations
├── services/
│   ├── ai_core/                    # Pure Dart offline translation, speech, extraction, & interview evaluator
│   ├── model_runtime/              # Model registry, SHA-256 checksum validator & lifecycle manager
│   └── reporting/                  # Report builders & exporters (PDF, MD, JSON, TXT)
├── packages/
│   ├── contracts/                  # Domain models, enums, & provider interfaces (STT, TTS, Translation, Storage)
│   └── shared/                     # Exceptions, PrivacyLogger (redaction), TextUtils, CryptoUtils
├── tests/
│   ├── unit/                       # Unit tests (detector, translation, explanation, extraction, speech, models)
│   ├── contract/                   # Contract & serialization round-trip tests
│   ├── integration/                # Full pipeline integration tests
│   ├── offline/                    # Offline privacy invariant verification (0 network calls)
│   ├── security/                   # Sensitive data redaction & sanitization tests
│   ├── performance/                # Latency budget benchmarks (<30ms translation)
│   └── e2e/                        # Mandatory 5 end-to-end user journeys
├── infrastructure/
│   ├── containers/Containerfile    # Multi-stage non-root container
│   ├── podman/podman-compose.yml   # Podman Compose configuration
│   └── scripts/                    # dev.ps1, generate-sbom.sh
├── docs/
│   ├── adr/                        # Architecture Decision Records (ADR-001 to ADR-005)
│   └── security/THREAT_MODEL.md    # STRIDE Threat Model
├── Makefile                        # Universal developer automation
└── README.md
```

---

## Developer Quickstart

### Prerequisites
- **Podman** (5.0+) or native Flutter 3.16+ / Dart 3.0+.
- No Docker Desktop required.

### 1. Setup
```bash
git clone https://github.com/unicom-ai/unicom.git
cd unicom

# Automated workspace dependency resolution via Podman
make setup
```

*(On Windows PowerShell, use `.\infrastructure\scripts\dev.ps1 setup`)*

### 2. Run Test Suite & Verify Coverage Gate
```bash
# Runs all 59 unit, contract, integration, offline, security, performance, and e2e tests
make test

# Enforces >= 90% line and branch coverage
make coverage
```

### 3. Start Local Development Server
```bash
make dev
```
Navigate your browser to `http://localhost:8080`.

---

## Platform Build Targets

| Platform | Command | Artifact Output |
| :--- | :--- | :--- |
| **Web / PWA** | `make web` | `apps/unicom/build/web/` |
| **Android APK** | `make android-apk` | `apps/unicom/build/app/outputs/flutter-apk/app-release.apk` |
| **Android AAB** | `make android-aab` | `apps/unicom/build/app/outputs/bundle/release/app-release.aab` |
| **Linux Desktop**| `make linux` | `apps/unicom/build/linux/` |
| **Windows Desktop**| `make windows` | `apps/unicom/build/windows/` |
| **All Supported**| `make build-all` | Full release bundle |

---

## Architecture Decision Records (ADRs)
- [ADR-001: Offline-First Architecture & Privacy Boundary](docs/adr/ADR-001-offline-first-architecture.md)
- [ADR-002: Replaceable Provider Abstraction Pattern](docs/adr/ADR-002-provider-abstraction-pattern.md)
- [ADR-003: Local-First Storage & Structured Logging Privacy](docs/adr/ADR-003-local-first-storage-and-privacy-boundary.md)
- [ADR-004: Podman Rootless Containerization Strategy](docs/adr/ADR-004-podman-containerization-strategy.md)
- [ADR-005: Interview Assessment Ethics, Transparency & Consent](docs/adr/ADR-005-interview-assessment-ethics-and-consent.md)

---

## Security & Privacy Invariants
For threat analysis and mitigations against model poisoning, prompt injection, and audio tampering, see [docs/security/THREAT_MODEL.md](docs/security/THREAT_MODEL.md).
- **Zero Content Logging**: All conversation audio and transcript text are automatically masked by `PrivacyLogger`.
- **Offline Network Isolation**: Private mode strictly forbids external network requests.
- **SBOM**: Software Bill of Materials generated in CycloneDX format via `infrastructure/scripts/generate-sbom.sh`.

---

## License
Licensed under the [Apache License, Version 2.0](LICENSE).
