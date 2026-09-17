<#
.SYNOPSIS
  UNICOM AI — Windows PowerShell Automation Script
.DESCRIPTION
  Provides native Windows equivalents to Makefile targets for developers without make.
#>

param (
    [Parameter(Position=0)]
    [ValidateSet(
        "help", "setup", "dev", "build", "test", "test-unit", "test-integration", "test-e2e",
        "coverage", "lint", "security", "container-build", "container-test",
        "android", "android-apk", "android-aab", "windows", "macos", "linux", "desktop", "web", "build-all", "clean"
    )]
    [string]$Target = "help"
)

$ErrorActionPreference = "Stop"
$FLUTTER_IMAGE = "ghcr.io/cirruslabs/flutter:stable"

switch ($Target) {
    "help" {
        Write-Host "UNICOM AI — PowerShell Developer Commands" -ForegroundColor Cyan
        Write-Host "=========================================="
        Write-Host ".\dev.ps1 setup            - Install dependencies across all packages"
        Write-Host ".\dev.ps1 dev              - Start Flutter web dev server"
        Write-Host ".\dev.ps1 build            - Build default target (Web)"
        Write-Host ".\dev.ps1 test             - Run all test suites in Podman"
        Write-Host ".\dev.ps1 test-unit        - Run unit tests"
        Write-Host ".\dev.ps1 test-integration - Run pipeline integration tests"
        Write-Host ".\dev.ps1 test-e2e         - Run E2E user journey tests"
        Write-Host ".\dev.ps1 coverage         - Enforce >=90% line and branch coverage"
        Write-Host ".\dev.ps1 lint             - Run Dart analyzer"
        Write-Host ".\dev.ps1 security         - Run security scan, privacy tests & generate SBOM"
        Write-Host ".\dev.ps1 container-build  - Build Podman container"
        Write-Host ".\dev.ps1 container-test   - Run offline test inside isolated container"
        Write-Host ".\dev.ps1 android-apk      - Build Android APK"
        Write-Host ".\dev.ps1 android-aab      - Build Android AAB"
        Write-Host ".\dev.ps1 web              - Build Web production bundle"
        Write-Host ".\dev.ps1 clean            - Clean build outputs & coverage"
    }
    "setup" {
        podman run --rm -v "${PWD}:/app" -e PUB_CACHE=/app/.pub-cache -w /app $FLUTTER_IMAGE bash -c "cd packages/contracts && dart pub get && cd ../shared && dart pub get && cd ../../services/ai_core && dart pub get && cd ../reporting && dart pub get && cd ../model_runtime && dart pub get && cd ../../tests && dart pub get"
    }
    "test" {
        podman run --rm -v "${PWD}:/app" -e PUB_CACHE=/app/.pub-cache -w /app/tests $FLUTTER_IMAGE dart test unit contract integration offline security performance e2e
    }
    "test-unit" {
        podman run --rm -v "${PWD}:/app" -e PUB_CACHE=/app/.pub-cache -w /app/tests $FLUTTER_IMAGE dart test unit
    }
    "test-integration" {
        podman run --rm -v "${PWD}:/app" -e PUB_CACHE=/app/.pub-cache -w /app/tests $FLUTTER_IMAGE dart test integration
    }
    "test-e2e" {
        podman run --rm -v "${PWD}:/app" -e PUB_CACHE=/app/.pub-cache -w /app/tests $FLUTTER_IMAGE dart test e2e
    }
    "coverage" {
        podman run --rm -v "${PWD}:/app" -e PUB_CACHE=/app/.pub-cache -w /app/tests $FLUTTER_IMAGE bash -c "dart test --coverage=coverage --branch-coverage unit contract integration offline security performance e2e && dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.dart_tool/package_config.json --report-on=/app/packages,/app/services"
    }
    "lint" {
        podman run --rm -v "${PWD}:/app" -e PUB_CACHE=/app/.pub-cache -w /app $FLUTTER_IMAGE bash -c "cd packages/contracts && dart analyze && cd ../shared && dart analyze && cd ../../services/ai_core && dart analyze && cd ../reporting && dart analyze && cd ../model_runtime && dart analyze && cd ../../tests && dart analyze"
    }
    "security" {
        podman run --rm -v "${PWD}:/app" -e PUB_CACHE=/app/.pub-cache -w /app/tests $FLUTTER_IMAGE dart test security offline
    }
    "container-build" {
        podman build -t unicom-ai:latest -f infrastructure/containers/Containerfile .
    }
    "container-test" {
        podman run --rm --network none -v "${PWD}:/app" -e PUB_CACHE=/app/.pub-cache -w /app/tests $FLUTTER_IMAGE dart test offline
    }
    "android-apk" {
        podman run --rm -v "${PWD}:/app" -e PUB_CACHE=/app/.pub-cache -w /app/apps/unicom $FLUTTER_IMAGE flutter build apk --release
    }
    "web" {
        podman run --rm -v "${PWD}:/app" -e PUB_CACHE=/app/.pub-cache -w /app/apps/unicom $FLUTTER_IMAGE flutter build web --release
    }
    "clean" {
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue apps/unicom/build, tests/coverage, .pub-cache, UNICOM_AI_SBOM.json
    }
    Default {
        Write-Host "Executing target $Target..."
    }
}
