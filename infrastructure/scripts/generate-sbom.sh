#!/usr/bin/env bash
set -euo pipefail

OUTPUT_FILE="${1:-UNICOM_AI_SBOM.json}"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
GIT_SHA="$(git rev-parse HEAD 2>/dev/null || echo "UNKNOWN_SHA")"

echo "Generating Software Bill of Materials (SBOM) for UNICOM AI..."

cat <<EOF > "${OUTPUT_FILE}"
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.5",
  "serialNumber": "urn:uuid:$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d")",
  "version": 1,
  "metadata": {
    "timestamp": "${TIMESTAMP}",
    "tools": [
      { "vendor": "UNICOM AI", "name": "unicom-sbom-generator", "version": "1.0.0" }
    ],
    "component": {
      "type": "application",
      "name": "UNICOM AI",
      "version": "1.0.0",
      "description": "Universal Communication Intelligence",
      "hashes": [
        { "alg": "SHA-1", "content": "${GIT_SHA}" }
      ],
      "licenses": [
        { "license": { "id": "Apache-2.0" } }
      ]
    }
  },
  "components": [
    { "type": "library", "name": "unicom_contracts", "version": "1.0.0", "scope": "required" },
    { "type": "library", "name": "unicom_shared", "version": "1.0.0", "scope": "required" },
    { "type": "library", "name": "unicom_ai_core", "version": "1.0.0", "scope": "required" },
    { "type": "library", "name": "unicom_reporting", "version": "1.0.0", "scope": "required" },
    { "type": "library", "name": "unicom_model_runtime", "version": "1.0.0", "scope": "required" },
    { "type": "library", "name": "crypto", "version": "^3.0.3", "purl": "pkg:pub/crypto" },
    { "type": "framework", "name": "flutter", "version": "3.16+", "purl": "pkg:generic/flutter" }
  ]
}
EOF

echo "SBOM successfully written to ${OUTPUT_FILE}"
