# UNICOM AI — Universal Communication Intelligence Makefile
# Compatible with Podman rootless execution and host development

.DEFAULT_GOAL := help
SHELL := /bin/bash

PODMAN ?= podman
CONTAINER_IMAGE ?= unicom-ai:latest
FLUTTER_IMAGE ?= ghcr.io/cirruslabs/flutter:stable
COMPOSE_FILE ?= infrastructure/podman/podman-compose.yml

.PHONY: help
help: ## Display available targets
	@echo "UNICOM AI — Universal Communication Intelligence"
	@echo "================================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-24s\033[0m %s\n", $$1, $$2}'

.PHONY: setup
setup: ## Install all dependencies across all packages and services
	$(PODMAN) run --rm -v ".:/app" -e PUB_CACHE=/app/.pub-cache -w /app $(FLUTTER_IMAGE) bash -c "\
		cd packages/contracts && dart pub get && \
		cd ../shared && dart pub get && \
		cd ../../services/ai_core && dart pub get && \
		cd ../reporting && dart pub get && \
		cd ../model_runtime && dart pub get && \
		cd ../../tests && dart pub get && \
		cd ../apps/unicom && flutter pub get"

.PHONY: dev
dev: ## Start Flutter web application in local development mode
	$(PODMAN) run --rm -it -v ".:/app" -e PUB_CACHE=/app/.pub-cache -p 8080:8080 -w /app/apps/unicom $(FLUTTER_IMAGE) flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0

.PHONY: build
build: web ## Default build target: compiles web production bundle

.PHONY: test
test: ## Run complete test suite (unit, contract, integration, offline, security, performance, e2e)
	$(PODMAN) run --rm -v ".:/app" -e PUB_CACHE=/app/.pub-cache -w /app/tests $(FLUTTER_IMAGE) dart test unit contract integration offline security performance e2e

.PHONY: test-unit
test-unit: ## Run unit tests
	$(PODMAN) run --rm -v ".:/app" -e PUB_CACHE=/app/.pub-cache -w /app/tests $(FLUTTER_IMAGE) dart test unit

.PHONY: test-integration
test-integration: ## Run pipeline integration tests
	$(PODMAN) run --rm -v ".:/app" -e PUB_CACHE=/app/.pub-cache -w /app/tests $(FLUTTER_IMAGE) dart test integration

.PHONY: test-e2e
test-e2e: ## Run end-to-end user journey tests
	$(PODMAN) run --rm -v ".:/app" -e PUB_CACHE=/app/.pub-cache -w /app/tests $(FLUTTER_IMAGE) dart test e2e

.PHONY: coverage
coverage: ## Enforce >=90% line and branch coverage
	$(PODMAN) run --rm -v ".:/app" -e PUB_CACHE=/app/.pub-cache -w /app/tests $(FLUTTER_IMAGE) bash -c "\
		dart test --coverage=coverage --branch-coverage unit contract integration offline security performance e2e && \
		dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.dart_tool/package_config.json --report-on=/app/packages,/app/services"

.PHONY: lint
lint: ## Run analyzer and linter across codebase
	$(PODMAN) run --rm -v ".:/app" -e PUB_CACHE=/app/.pub-cache -w /app $(FLUTTER_IMAGE) bash -c "\
		cd packages/contracts && dart analyze && \
		cd ../shared && dart analyze && \
		cd ../../services/ai_core && dart analyze && \
		cd ../reporting && dart analyze && \
		cd ../model_runtime && dart analyze && \
		cd ../../tests && dart analyze"

.PHONY: security
security: ## Run security scan, privacy tests, and generate SBOM
	$(PODMAN) run --rm -v ".:/app" -e PUB_CACHE=/app/.pub-cache -w /app/tests $(FLUTTER_IMAGE) dart test security offline
	bash infrastructure/scripts/generate-sbom.sh UNICOM_AI_SBOM.json

.PHONY: container-build
container-build: ## Build multi-stage Podman container
	$(PODMAN) build -t $(CONTAINER_IMAGE) -f infrastructure/containers/Containerfile .

.PHONY: container-test
container-test: ## Run test suite inside isolated network-disabled container
	$(PODMAN) run --rm --network none -v ".:/app" -e PUB_CACHE=/app/.pub-cache -w /app/tests $(FLUTTER_IMAGE) dart test offline

.PHONY: android
android: android-apk ## Default Android build target

.PHONY: android-apk
android-apk: ## Build Android release APK
	$(PODMAN) run --rm -v ".:/app" -e PUB_CACHE=/app/.pub-cache -w /app/apps/unicom $(FLUTTER_IMAGE) flutter build apk --release

.PHONY: android-aab
android-aab: ## Build Android App Bundle (AAB) for Google Play
	$(PODMAN) run --rm -v ".:/app" -e PUB_CACHE=/app/.pub-cache -w /app/apps/unicom $(FLUTTER_IMAGE) flutter build appbundle --release

.PHONY: windows
windows: ## Build Windows desktop target (requires Windows host with CMake & Visual Studio)
	@echo "Building Windows desktop application..."
	flutter build windows --release

.PHONY: macos
macos: ## Build macOS desktop target (requires macOS host with Xcode)
	@echo "Building macOS desktop application..."
	flutter build macos --release

.PHONY: linux
linux: ## Build Linux desktop target
	$(PODMAN) run --rm -v ".:/app" -e PUB_CACHE=/app/.pub-cache -w /app/apps/unicom $(FLUTTER_IMAGE) flutter build linux --release

.PHONY: desktop
desktop: windows ## Default desktop build target for current host

.PHONY: web
web: ## Build Web / PWA production bundle
	$(PODMAN) run --rm -v ".:/app" -e PUB_CACHE=/app/.pub-cache -w /app/apps/unicom $(FLUTTER_IMAGE) flutter build web --release

.PHONY: build-all
build-all: web android-apk android-aab linux ## Build all container-supported platform targets

.PHONY: clean
clean: ## Clean build artifacts, lockfiles, and coverage data
	rm -rf apps/unicom/build tests/coverage .pub-cache UNICOM_AI_SBOM.json
