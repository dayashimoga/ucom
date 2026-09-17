# Contributing to UNICOM AI

Thank you for contributing to UNICOM AI — Universal Communication Intelligence.

## Developer Quickstart

```bash
# Clone the repository
git clone https://github.com/unicom-ai/unicom.git
cd unicom

# Run full setup using Podman
make setup

# Run all test suites
make test

# Verify coverage (must meet >= 90% threshold)
make coverage

# Start local development server
make dev
```

## Pull Request Guidelines
1. Ensure all tests pass (`make test`).
2. Verify line and branch coverage is at least 90% (`make coverage`).
3. Maintain documentation integrity and include ADRs for architectural changes.
4. Strictly ensure zero secret or credential commits.
