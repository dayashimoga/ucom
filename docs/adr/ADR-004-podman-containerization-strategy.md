# ADR-004: Podman Rootless Containerization Strategy

## Status
Accepted

## Context
Cross-platform developer tooling, testing in clean environments, and CI container builds often depend on proprietary desktop container engines (e.g. Docker Desktop) requiring licensing or daemon root privileges.

## Decision
1. **Podman as Mandatory Container Engine**: We mandate Podman as the primary local container technology, supporting rootless execution and compatibility with Docker CLI aliases.
2. **Multi-Stage Containerfile**: Production and testing images use multi-stage builds (`ghcr.io/cirruslabs/flutter:stable` or `dart:stable`), running as non-root users where practical and mounting local source code into `/app`.
3. **Reproducible Tooling Fallback**: When developers do not have native local Flutter/Dart SDKs installed, Podman container execution serves as the guaranteed, zero-friction developer execution environment.

## Consequences
- **Positive**: Zero licensing costs; rootless execution by default; identical builds between local developer environments and CI pipelines.
- **Negative**: Requires WSL2 integration on Windows hosts.
