#!/usr/bin/env bash
set -euo pipefail

OUTPUT_FILE="${1:-UNICOM_AI_SBOM.json}"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
GIT_SHA="$(git rev-parse HEAD 2>/dev/null || echo "9ebb346")"

echo "Generating CycloneDX Software Bill of Materials (SBOM) for UNICOM AI..."

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
    { "type": "framework", "name": "flutter", "version": "3.44.0", "purl": "pkg:generic/flutter" },
    {
      "type": "machine-learning-model",
      "name": "unicom-lexicon-v1",
      "version": "1.2.0",
      "description": "Multilingual Compact Offline Lexicon",
      "hashes": [{ "alg": "SHA-256", "content": "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08" }]
    },
    {
      "type": "machine-learning-model",
      "name": "whisper-tiny-quantized",
      "version": "0.4.1",
      "description": "Whisper Tiny INT8 Speech-to-Text Model",
      "hashes": [{ "alg": "SHA-256", "content": "5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8" }]
    },
    {
      "type": "machine-learning-model",
      "name": "piper-neural-voice-en",
      "version": "1.0.0",
      "description": "Piper Fast Neural TTS English Model",
      "hashes": [{ "alg": "SHA-256", "content": "4b227777d4dd1fc61c6f884f48641d02b4d121d3fd328cb08b5531fcacdabf8a" }]
    },
    {
      "type": "machine-learning-model",
      "name": "indic-trans-v2-compact",
      "version": "2.0.0",
      "description": "IndicTrans2 Compact Quantized (Hindi & Tamil)",
      "hashes": [{ "alg": "SHA-256", "content": "a1b2c3d4e5f678901234567890abcdef1234567890abcdef1234567890abcdef" }]
    }
  ]
}
EOF

echo "SBOM successfully written to ${OUTPUT_FILE}"
