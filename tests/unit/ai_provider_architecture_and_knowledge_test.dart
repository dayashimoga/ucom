import 'dart:io';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_shared/shared.dart';
import 'package:unicom_ai_core/ai_core.dart';
import 'package:unicom_model_runtime/model_runtime.dart';

void main() {
  group('AI Provider Architecture & Knowledge Q&A Engine Tests', () {
    // -------------------------------------------------------------
    // 1. Android AICore / Gemini Nano Provider
    // -------------------------------------------------------------
    group('AndroidAICoreProvider', () {
      test('reports AVAILABLE status on supported device', () async {
        final provider = AndroidAICoreProvider(simulateAvailable: true);
        final status = await provider.checkStatus();

        expect(status.isAvailable, isTrue);
        expect(status.isSupportedOnDevice, isTrue);
        expect(status.statusCode, equals('AVAILABLE'));
        expect(status.modelName, contains('Gemini Nano'));
        expect(status.maxContextTokens, equals(4096));
        expect(status.supportedCapabilities, contains('text_generation'));
        expect(status.supportedCapabilities, contains('zero_network_leak'));
        expect(status.toJson()['statusCode'], equals('AVAILABLE'));

        final fromJsonStatus = AICoreStatus.fromJson(status.toJson());
        expect(fromJsonStatus.isAvailable, isTrue);
      });

      test('reports NOT_SUPPORTED status when hardware/OS prerequisite not met', () async {
        final provider = AndroidAICoreProvider(simulateAvailable: false);
        final status = await provider.checkStatus();

        expect(status.isAvailable, isFalse);
        expect(status.isSupportedOnDevice, isFalse);
        expect(status.statusCode, equals('NOT_SUPPORTED'));
        expect(status.fallbackReason, contains('hardware or OS'));
      });

      test('reports simulated error states properly (e.g. QUOTA_EXCEEDED)', () async {
        final provider = AndroidAICoreProvider(simulatedError: 'QUOTA_EXCEEDED');
        final status = await provider.checkStatus();

        expect(status.isAvailable, isFalse);
        expect(status.statusCode, equals('QUOTA_EXCEEDED'));
      });

      test('throws ProviderException when inference attempted while unavailable', () async {
        final provider = AndroidAICoreProvider(simulateAvailable: false);
        expect(
          () async => await provider.complete('Explain Kubernetes'),
          throwsA(isA<ProviderException>()),
        );
        expect(
          () => provider.completeStream('Explain Kubernetes').toList(),
          throwsA(isA<ProviderException>()),
        );
      });

      test('generates on-device completions for domain prompts and streams tokens', () async {
        final provider = AndroidAICoreProvider(simulateAvailable: true);

        // Kubernetes / Node Affinity
        final k8sResp = await provider.complete('Explain Kubernetes scheduler and node affinity');
        expect(k8sResp, contains('Kubernetes scheduler'));
        expect(k8sResp, contains('node affinity'));

        // Quantum entanglement
        final quantumResp = await provider.complete('Explain quantum entanglement for a child');
        expect(quantumResp, contains('Quantum entanglement'));
        expect(quantumResp, contains('magic dice'));

        // Literature: 1984 vs Brave New World
        final litResp = await provider.complete('Compare 1984 and Brave New World');
        expect(litResp, contains('1984'));
        expect(litResp, contains('Brave New World'));

        // System prompt simple
        final simpleResp = await provider.complete('Microservices', systemPrompt: 'simple explanation');
        expect(simpleResp, contains('simple explanation'));

        // Generic fallback prompt
        final genResp = await provider.complete('Arbitrary inquiry text');
        expect(genResp, contains('Gemini Nano analysis'));

        // Stream verification
        final streamWords = await provider.completeStream('Kubernetes scheduler').toList();
        expect(streamWords, isNotEmpty);
        expect(streamWords.join(''), contains('Kubernetes'));
      });
    });

    // -------------------------------------------------------------
    // 2. Local LLM Provider
    // -------------------------------------------------------------
    group('LocalLLMProvider', () {
      test('throws ValidationException when model is not loaded in memory', () async {
        final provider = LocalLLMProvider(isModelLoaded: false);
        expect(
          () async => await provider.complete('Test prompt'),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => provider.completeStream('Test prompt').toList(),
          throwsA(isA<ValidationException>()),
        );
      });

      test('completes and streams across all domain categories when model is loaded', () async {
        final model = ModelMetadata(
          id: 'unicom-knowledge-llm-q4',
          name: 'UNICOM Knowledge & Q&A LLM (INT4 Quantized)',
          version: '1.0.0',
          type: 'llm',
          sizeBytes: 52428800,
          sha256: 'b2c3d4e5f678901234567890abcdef1234567890abcdef1234567890abcdef12',
          license: 'Apache-2.0',
          isInstalled: true,
          isActive: true,
        );
        final provider = LocalLLMProvider(activeModel: model, isModelLoaded: true);

        expect(provider.id, equals('local_downloaded_llm'));
        expect(provider.name, contains('UNICOM Knowledge'));
        expect(provider.isOfflineCapable, isTrue);

        // Kubernetes
        final k8s = await provider.complete('What is node affinity in kubernetes scheduler?');
        expect(k8s, contains('Kubernetes scheduler evaluates'));
        expect(k8s, contains('Node affinity'));

        // Quantum
        final quantum = await provider.complete('Explain quantum entanglement');
        expect(quantum, contains('Quantum entanglement'));

        // Literature
        final lit = await provider.complete('Analyze 1984 and Brave New World');
        expect(lit, contains('1984 critiques'));

        // Math
        final math = await provider.complete('Explain Euler identity in calculus');
        expect(math, contains('Euler\'s identity'));

        // Simple prompt
        final simple = await provider.complete('Distributed consensus', systemPrompt: 'simple summary');
        expect(simple, contains('Simply put:'));

        // Default prompt
        final fallback = await provider.complete('What is photosynthesis?');
        expect(fallback, contains('Local AI response'));

        // Streaming
        final streamList = await provider.completeStream('Explain Euler identity in calculus').toList();
        expect(streamList.join(''), contains('Euler'));
      });
    });

    // -------------------------------------------------------------
    // 3. Cloud LLM Provider & BYOK / Connection Testing
    // -------------------------------------------------------------
    group('CloudLLMProvider', () {
      test('enforces strict privacy invariant in private_offline mode', () async {
        final cloud = CloudLLMProvider(
          executionMode: ExecutionMode.privateOffline,
          apiKey: 'AIzaSy_secret_key',
        );

        // Complete throws OfflineViolationException
        expect(
          () async => await cloud.complete('Hello cloud'),
          throwsA(isA<OfflineViolationException>()),
        );

        // Stream throws OfflineViolationException
        expect(
          () => cloud.completeStream('Hello cloud').toList(),
          throwsA(isA<OfflineViolationException>()),
        );

        // Test connection reports failure without leaking secrets
        final testRes = await cloud.testConnection();
        expect(testRes.isSuccessful, isFalse);
        expect(testRes.errorMessage, contains('private_offline mode'));
      });

      test('validates missing or empty API keys in hybrid/cloud modes', () async {
        final cloud = CloudLLMProvider(
          executionMode: ExecutionMode.hybrid,
          apiKey: '',
        );

        final testRes = await cloud.testConnection();
        expect(testRes.isSuccessful, isFalse);
        expect(testRes.errorMessage, contains('Missing API key'));

        expect(
          () async => await cloud.complete('Hello cloud'),
          throwsA(isA<ProviderException>()),
        );

        expect(
          () => cloud.completeStream('Hello cloud').toList(),
          throwsA(isA<ProviderException>()),
        );
      });

      test('connects and infers successfully when API key is provided', () async {
        final cloud = CloudLLMProvider(
          executionMode: ExecutionMode.hybrid,
          apiKey: 'valid-gemini-test-key',
        );

        final testRes = await cloud.testConnection();
        expect(testRes.isSuccessful, isTrue);
        expect(testRes.latencyMs, greaterThanOrEqualTo(0));
        expect(testRes.toJson()['isSuccessful'], isTrue);

        // Kubernetes
        final k8s = await cloud.complete('Explain Kubernetes scheduler');
        expect(k8s, contains('[Cloud Gemini 1.5]'));
        expect(k8s, contains('kube-scheduler'));

        // Quantum
        final quantum = await cloud.complete('Explain quantum entanglement');
        expect(quantum, contains('[Cloud Gemini 1.5]'));
        expect(quantum, contains('Quantum entanglement'));

        // Generic
        final gen = await cloud.complete('Generic question');
        expect(gen, contains('[Cloud Gemini 1.5]'));

        // Stream
        final stream = await cloud.completeStream('Generic prompt').toList();
        expect(stream.join(''), contains('[Cloud Gemini 1.5]'));
      });
    });

    // -------------------------------------------------------------
    // 4. AI Provider Router
    // -------------------------------------------------------------
    group('AIProviderRouter', () {
      late AndroidAICoreProvider aicoreAvailable;
      late AndroidAICoreProvider aicoreUnavailable;
      late LocalLLMProvider localLoaded;
      late LocalLLMProvider localUnloaded;
      late CloudLLMProvider cloudWithKey;
      late CloudLLMProvider cloudWithoutKey;

      setUp(() {
        aicoreAvailable = AndroidAICoreProvider(simulateAvailable: true);
        aicoreUnavailable = AndroidAICoreProvider(simulateAvailable: false);
        localLoaded = LocalLLMProvider(isModelLoaded: true);
        localUnloaded = LocalLLMProvider(isModelLoaded: false);
        cloudWithKey = CloudLLMProvider(
          executionMode: ExecutionMode.hybrid,
          apiKey: 'test-api-key',
        );
        cloudWithoutKey = CloudLLMProvider(
          executionMode: ExecutionMode.hybrid,
          apiKey: null,
        );
      });

      test('Private Offline Mode: routes to AICore when available', () async {
        final router = AIProviderRouter(
          androidProvider: aicoreAvailable,
          localProvider: localLoaded,
          cloudProvider: cloudWithKey,
          executionMode: ExecutionMode.privateOffline,
        );

        final provider = await router.selectProvider();
        expect(provider.id, equals('android_aicore_gemini_nano'));

        final answer = await router.complete('Kubernetes scheduler');
        expect(answer, contains('Kubernetes'));
      });

      test('Private Offline Mode: routes to Local LLM when AICore is unavailable', () async {
        final router = AIProviderRouter(
          androidProvider: aicoreUnavailable,
          localProvider: localLoaded,
          cloudProvider: cloudWithKey,
          executionMode: ExecutionMode.privateOffline,
        );

        final provider = await router.selectProvider();
        expect(provider.id, equals('local_downloaded_llm'));
      });

      test('Private Offline Mode: throws OfflineInferenceUnavailableException when neither available (NEVER cloud fallback)', () async {
        final router = AIProviderRouter(
          androidProvider: aicoreUnavailable,
          localProvider: localUnloaded,
          cloudProvider: cloudWithKey,
          executionMode: ExecutionMode.privateOffline,
        );

        expect(
          () async => await router.selectProvider(),
          throwsA(isA<OfflineInferenceUnavailableException>()),
        );
      });

      test('Hybrid Mode: routes AICore -> Local -> Cloud -> throws', () async {
        // Case 1: AICore available
        var router = AIProviderRouter(
          androidProvider: aicoreAvailable,
          localProvider: localLoaded,
          cloudProvider: cloudWithKey,
          executionMode: ExecutionMode.hybrid,
        );
        expect((await router.selectProvider()).id, equals('android_aicore_gemini_nano'));

        // Case 2: Local loaded
        router = AIProviderRouter(
          androidProvider: aicoreUnavailable,
          localProvider: localLoaded,
          cloudProvider: cloudWithKey,
          executionMode: ExecutionMode.hybrid,
        );
        expect((await router.selectProvider()).id, equals('local_downloaded_llm'));

        // Case 3: Cloud fallback
        router = AIProviderRouter(
          androidProvider: aicoreUnavailable,
          localProvider: localUnloaded,
          cloudProvider: cloudWithKey,
          executionMode: ExecutionMode.hybrid,
        );
        expect((await router.selectProvider()).id, equals('cloud_gemini_llm'));

        // Case 4: No providers
        router = AIProviderRouter(
          androidProvider: aicoreUnavailable,
          localProvider: localUnloaded,
          cloudProvider: cloudWithoutKey,
          executionMode: ExecutionMode.hybrid,
        );
        expect(() async => await router.selectProvider(), throwsA(isA<OfflineInferenceUnavailableException>()));
      });

      test('Cloud Mode: Cloud preferred, falling back to AICore or Local', () async {
        // Cloud key configured
        var router = AIProviderRouter(
          androidProvider: aicoreAvailable,
          localProvider: localLoaded,
          cloudProvider: cloudWithKey,
          executionMode: ExecutionMode.cloud,
        );
        expect((await router.selectProvider()).id, equals('cloud_gemini_llm'));

        // Cloud key missing, AICore fallback
        router = AIProviderRouter(
          androidProvider: aicoreAvailable,
          localProvider: localLoaded,
          cloudProvider: cloudWithoutKey,
          executionMode: ExecutionMode.cloud,
        );
        expect((await router.selectProvider()).id, equals('android_aicore_gemini_nano'));

        // Cloud missing, AICore unavailable, Local fallback
        router = AIProviderRouter(
          androidProvider: aicoreUnavailable,
          localProvider: localLoaded,
          cloudProvider: cloudWithoutKey,
          executionMode: ExecutionMode.cloud,
        );
        expect((await router.selectProvider()).id, equals('local_downloaded_llm'));

        // None available
        router = AIProviderRouter(
          androidProvider: aicoreUnavailable,
          localProvider: localUnloaded,
          cloudProvider: cloudWithoutKey,
          executionMode: ExecutionMode.cloud,
        );
        expect(() async => await router.selectProvider(), throwsA(isA<ProviderException>()));
      });

      test('Auto Mode: Capability-aware routing AICore -> Local -> Cloud', () async {
        var router = AIProviderRouter(
          androidProvider: aicoreAvailable,
          localProvider: localLoaded,
          cloudProvider: cloudWithKey,
          executionMode: ExecutionMode.auto,
        );
        expect((await router.selectProvider()).id, equals('android_aicore_gemini_nano'));

        router = AIProviderRouter(
          androidProvider: aicoreUnavailable,
          localProvider: localLoaded,
          cloudProvider: cloudWithKey,
          executionMode: ExecutionMode.auto,
        );
        expect((await router.selectProvider()).id, equals('local_downloaded_llm'));

        router = AIProviderRouter(
          androidProvider: aicoreUnavailable,
          localProvider: localUnloaded,
          cloudProvider: cloudWithKey,
          executionMode: ExecutionMode.auto,
        );
        expect((await router.selectProvider()).id, equals('cloud_gemini_llm'));

        router = AIProviderRouter(
          androidProvider: aicoreUnavailable,
          localProvider: localUnloaded,
          cloudProvider: cloudWithoutKey,
          executionMode: ExecutionMode.auto,
        );
        expect(() async => await router.selectProvider(), throwsA(isA<OfflineInferenceUnavailableException>()));
      });

      test('discoverCapabilities and stream complete', () async {
        final router = AIProviderRouter(
          androidProvider: aicoreAvailable,
          localProvider: localLoaded,
          cloudProvider: cloudWithKey,
          executionMode: ExecutionMode.privateOffline,
        );

        final caps = await router.discoverCapabilities();
        expect(caps['executionMode'], equals('privateOffline'));
        expect(caps['androidAICore']['isAvailable'], isTrue);

        router.setExecutionMode(ExecutionMode.hybrid);
        expect(router.executionMode, equals(ExecutionMode.hybrid));

        final streamWords = await router.completeStream('Kubernetes scheduler').toList();
        expect(streamWords, isNotEmpty);
      });
    });

    // -------------------------------------------------------------
    // 5. Rag Retrieval Provider & Knowledge Engine
    // -------------------------------------------------------------
    group('RagRetrievalProvider', () {
      test('indexes, scores, and retrieves grounded documents', () async {
        final provider = RagRetrievalProvider();

        expect(await provider.retrieve(''), isEmpty);

        final doc1 = const RetrievalDocument(
          id: 'doc1',
          title: 'Kubernetes Pod Scheduling',
          content: 'The kube-scheduler selects a node for each pod using filtering and scoring phases.',
          sourceUri: 'https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/',
        );
        final doc2 = const RetrievalDocument(
          id: 'doc2',
          title: 'Quantum Physics Basics',
          content: 'Quantum entanglement describes correlations between particles at distance.',
          sourceUri: 'https://arxiv.org/quantum',
        );

        await provider.indexDocument(doc1);
        await provider.indexDocument(doc2);

        // Retrieve K8s
        final k8sDocs = await provider.retrieve('How does the Kubernetes scheduler assign pods?');
        expect(k8sDocs.length, equals(1));
        expect(k8sDocs.first.id, equals('doc1'));
        expect(k8sDocs.first.score, greaterThan(0.0));

        // Retrieve Quantum
        final qDocs = await provider.retrieve('Quantum entanglement');
        expect(qDocs.first.id, equals('doc2'));

        // Delete document
        final deleted = await provider.deleteDocument('doc1');
        expect(deleted, isTrue);
        expect((await provider.retrieve('Kubernetes scheduler')), isEmpty);
      });
    });

    group('KnowledgeEngine', () {
      late AIProviderRouter router;
      late RagRetrievalProvider rag;
      late OfflineTranslationEngine translationEngine;
      late KnowledgeEngine knowledge;

      setUp(() {
        final aicore = AndroidAICoreProvider(simulateAvailable: true);
        final local = LocalLLMProvider(isModelLoaded: true);
        final cloud = CloudLLMProvider(executionMode: ExecutionMode.hybrid, apiKey: 'key');
        router = AIProviderRouter(
          androidProvider: aicore,
          localProvider: local,
          cloudProvider: cloud,
          executionMode: ExecutionMode.privateOffline,
        );

        rag = RagRetrievalProvider([
          const RetrievalDocument(
            id: 'k8s_guide',
            title: 'Kubernetes Node Affinity Architecture',
            content: 'Node affinity allows you to constrain which nodes your Pod can be scheduled on based on node labels.',
            sourceUri: 'https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/',
          ),
        ]);

        translationEngine = OfflineTranslationEngine();
        knowledge = KnowledgeEngine(
          router: router,
          retrievalProvider: rag,
          translationProvider: translationEngine,
        );
      });

      test('asks question with grounded RAG context, persona, and translation', () async {
        final response = await knowledge.ask(
          question: 'Explain Kubernetes node affinity',
          persona: ExplanationPersona.simple,
          targetLanguage: 'es',
          retrieveContext: true,
        );

        expect(response.question, equals('Explain Kubernetes node affinity'));
        expect(response.generativeAnswer, contains('Kubernetes'));
        expect(response.groundedSources.length, equals(1));
        expect(response.groundedSources.first.title, contains('Kubernetes Node Affinity'));
        expect(response.explanation, isNotNull);
        expect(response.translatedAnswer, isNotNull);
        expect(response.targetLanguage, equals('es'));
        expect(response.aiSummary, isNotNull);

        final md = response.toStructuredMarkdown();
        expect(md, contains('### VERBATIM QUESTION'));
        expect(md, contains('### GENERATIVE ANSWER'));
        expect(md, contains('### EXPLANATION'));
        expect(md, contains('### TRANSLATION (ES)'));
        expect(md, contains('### AI SUMMARY'));
        expect(md, contains('### GROUNDED SOURCES'));
        expect(md, contains('Provenance: Provider'));
      });

      test('convenience actions: explainSimply, explainDeeply, giveExample, askStream', () async {
        final simple = await knowledge.explainSimply('Quantum entanglement');
        expect(simple.explanation, isNotNull);

        final deep = await knowledge.explainDeeply('Kubernetes scheduler');
        expect(deep.explanation, isNotNull);

        final ex = await knowledge.giveExample('Microservices');
        expect(ex.explanation, isNotNull);

        final streamResult = await knowledge.askStream(question: 'What is 1984?').toList();
        expect(streamResult.join(''), contains('1984'));
      });
    });

    // -------------------------------------------------------------
    // 6. Branch Coverage Edge Cases (Speech, Translation, Storage)
    // -------------------------------------------------------------
    group('Speech & Translation Adapter Branch Coverage', () {
      test('CloudTranslationAdapter private_offline and missing key branches', () async {
        final offlineAdapter = CloudTranslationAdapter(executionMode: ExecutionMode.privateOffline);
        expect(
          () async => await offlineAdapter.translate(
            'hello',
            options: const TranslationOptions(targetLanguage: 'es'),
          ),
          throwsA(isA<OfflineViolationException>()),
        );

        final noKeyAdapter = CloudTranslationAdapter(executionMode: ExecutionMode.hybrid, apiKey: '');
        expect(
          () async => await noKeyAdapter.translate(
            'hello',
            options: const TranslationOptions(targetLanguage: 'es'),
          ),
          throwsA(isA<ProviderException>()),
        );
      });

      test('CloudSpeechAdapter private_offline and missing key branches', () async {
        final offlineSpeech = CloudSpeechAdapter(executionMode: ExecutionMode.privateOffline);
        expect(
          () async => await offlineSpeech.transcribe(Uint8List(10)),
          throwsA(isA<OfflineViolationException>()),
        );
        expect(
          () async => await offlineSpeech.synthesize('hello'),
          throwsA(isA<OfflineViolationException>()),
        );

        final noKeySpeech = CloudSpeechAdapter(executionMode: ExecutionMode.hybrid, apiKey: '');
        expect(
          () async => await noKeySpeech.transcribe(Uint8List(10)),
          throwsA(isA<ProviderException>()),
        );
        expect(
          () async => await noKeySpeech.synthesize('hello'),
          throwsA(isA<ProviderException>()),
        );

        noKeySpeech.cancel(); // does not throw
      });

      test('Fake providers helper branches', () async {
        final fakeSpeech = DeterministicFakeSTTProvider();
        fakeSpeech.cancel();

        final fakeTTS = DeterministicFakeTTSProvider();
        final synRes = await fakeTTS.synthesize('Test TTS');
        expect(synRes.audioBytes.isNotEmpty, isTrue);

        final fakeTrans = DeterministicFakeTranslationProvider();
        final tr = await fakeTrans.translate('unmapped input text', options: const TranslationOptions(targetLanguage: 'de'));
        expect(tr.translatedText, contains('[DE]'));
      });
    });

    // -------------------------------------------------------------
    // 7. Local Model Manager Branch Coverage
    // -------------------------------------------------------------
    group('LocalModelManager Branch Coverage', () {
      late Directory tempDir;
      late LocalModelManager manager;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('unicom_model_test_');
        manager = LocalModelManager(storageDirectory: tempDir);
      });

      tearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });

      test('downloadModel returns existing model immediately if already installed', () async {
        final m = await manager.getModel('unicom-lexicon-v1');
        expect(m, isNotNull);
        expect(m!.isInstalled, isTrue);

        final downloaded = await manager.downloadModel('unicom-lexicon-v1');
        expect(downloaded.id, equals('unicom-lexicon-v1'));
      });

      test('downloadModel throws StorageFullException if available disk space is insufficient', () async {
        final lowDiskManager = LocalModelManager(
          storageDirectory: tempDir,
          availableDiskSpaceBytes: 100, // < 40MB
        );
        expect(
          () async => await lowDiskManager.downloadModel('whisper-tiny-quantized'),
          throwsA(isA<StorageFullException>()),
        );
      });

      test('downloadModel throws ChecksumMismatchException if mock downloaded bytes hash fails', () async {
        expect(
          () async => await manager.downloadModel(
            'whisper-tiny-quantized',
            mockDownloadedBytes: [1, 2, 3, 4], // will not match whisper sha256
          ),
          throwsA(isA<ChecksumMismatchException>()),
        );
      });

      test('activateModel deactivates previous active model of same type', () async {
        // Download and install whisper
        final whisperDownloaded = await manager.downloadModel('whisper-tiny-quantized');
        expect(whisperDownloaded.isInstalled, isTrue);

        // Activate it
        await manager.activateModel('whisper-tiny-quantized');
        final activeWhisper = await manager.getModel('whisper-tiny-quantized');
        expect(activeWhisper!.isActive, isTrue);
        expect(activeWhisper.isLoadedInMemory, isTrue);

        // Verify checksum computes when file exists
        final checksumValid = await manager.verifyChecksum('whisper-tiny-quantized');
        expect(checksumValid, isTrue);

        // Unload from memory
        await manager.unloadModel('whisper-tiny-quantized');
        final unloadedWhisper = await manager.getModel('whisper-tiny-quantized');
        expect(unloadedWhisper!.isLoadedInMemory, isFalse);

        // Remove model deletes physical file
        final removed = await manager.removeModel('whisper-tiny-quantized');
        expect(removed, isTrue);
        final afterRemoval = await manager.getModel('whisper-tiny-quantized');
        expect(afterRemoval!.isInstalled, isFalse);
        expect(afterRemoval.installPath, isNull);
      });
    });

    // -------------------------------------------------------------
    // 8. Durable Storage Branch Coverage (Pagination, Query Filtering)
    // -------------------------------------------------------------
    group('DurableFileStorageProvider Additional Branch Coverage', () {
      late Directory tempDir;
      late DurableFileStorageProvider storage;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('unicom_storage_branches_');
        storage = DurableFileStorageProvider(baseDirectory: tempDir);
      });

      tearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });

      test('listConversations filters by query (original and translated text), mode, and executionMode', () async {
        final c1 = Conversation(
          id: 'c_search_1',
          title: 'Quantum Research',
          mode: ApplicationMode.education,
          executionMode: ExecutionMode.privateOffline,
          startedAt: '2026-09-17T01:00:00Z',
          segments: [
            ConversationSegment(
              id: 's1',
              speakerId: 'spk1',
              speakerName: 'Alice',
              startTime: 0,
              originalText: 'Schrodinger equation explanation',
              originalLanguage: 'en',
              translatedText: 'Explicación de la ecuación de Schrödinger',
              targetLanguage: 'es',
            ),
          ],
        );

        final c2 = Conversation(
          id: 'c_search_2',
          title: 'Kubernetes Pod Deployment',
          mode: ApplicationMode.meeting,
          executionMode: ExecutionMode.hybrid,
          startedAt: '2026-09-17T02:00:00Z',
          segments: [
            ConversationSegment(
              id: 's2',
              speakerId: 'spk2',
              speakerName: 'Bob',
              startTime: 0,
              originalText: 'Rollout deployment',
              originalLanguage: 'en',
              translatedText: 'Despliegue de actualización',
              targetLanguage: 'es',
            ),
          ],
        );

        await storage.saveConversation(c1);
        await storage.saveConversation(c2);

        // Search by title
        final resTitle = await storage.searchConversations('quantum');
        expect(resTitle.length, equals(1));
        expect(resTitle.first.id, equals('c_search_1'));

        // Search by segment originalText
        final resSegOrig = await storage.listConversations(query: 'schrodinger');
        expect(resSegOrig.length, equals(1));
        expect(resSegOrig.first.id, equals('c_search_1'));

        // Search by segment translatedText
        final resSegTrans = await storage.listConversations(query: 'despliegue');
        expect(resSegTrans.length, equals(1));
        expect(resSegTrans.first.id, equals('c_search_2'));

        // Filter by mode
        final resMode = await storage.listConversations(mode: ApplicationMode.education);
        expect(resMode.length, equals(1));
        expect(resMode.first.id, equals('c_search_1'));

        // Filter by executionMode
        final resExec = await storage.listConversations(executionMode: ExecutionMode.hybrid);
        expect(resExec.length, equals(1));
        expect(resExec.first.id, equals('c_search_2'));

        // Offset beyond length returns []
        final resOffset = await storage.listConversations(offset: 100);
        expect(resOffset, isEmpty);

        // Delete non-existent conversation returns false
        final delNonExistent = await storage.deleteConversation('no_such_conv');
        expect(delNonExistent, isFalse);

        // Overwrite existing conversation
        await storage.saveConversation(c1);
        final overwritten = await storage.getConversation('c_search_1');
        expect(overwritten, isNotNull);
      });
    });
  });
}
