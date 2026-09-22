import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_ai_core/ai_core.dart';
import 'package:unicom_app/features/conversation/conversation_state_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('ConversationController Unit Tests', () {
    late ConversationController controller;

    setUp(() {
      controller = ConversationController();
    });

    test('initializes with default settings and active conversation', () {
      expect(controller.state, equals(ConversationState.idle));
      expect(controller.executionMode, equals(ExecutionMode.privateOffline));
      expect(controller.mode, equals(ApplicationMode.general));
      expect(controller.sourceLanguage, equals('en'));
      expect(controller.targetLanguage, equals('es'));
      expect(controller.currentConversation.segments, isEmpty);
      expect(controller.actionableError, isNull);
    });

    test('updates execution mode and synchronizes network gate', () {
      controller.setExecutionMode(ExecutionMode.cloud);
      expect(controller.executionMode, equals(ExecutionMode.cloud));
      expect(controller.router.executionMode, equals(ExecutionMode.cloud));

      controller.setExecutionMode(ExecutionMode.hybrid);
      expect(controller.executionMode, equals(ExecutionMode.hybrid));

      controller.setExecutionMode(ExecutionMode.auto);
      expect(controller.executionMode, equals(ExecutionMode.auto));

      controller.setExecutionMode(ExecutionMode.privateOffline);
      expect(controller.executionMode, equals(ExecutionMode.privateOffline));
    });

    test('updates application mode and resets session', () {
      controller.setApplicationMode(ApplicationMode.interviewPractice);
      expect(controller.mode, equals(ApplicationMode.interviewPractice));
      expect(controller.currentConversation.mode,
          equals(ApplicationMode.interviewPractice));

      controller.setApplicationMode(ApplicationMode.meeting);
      expect(controller.mode, equals(ApplicationMode.meeting));
    });

    test('updates source and target languages', () {
      controller.setLanguages('fr', 'de');
      expect(controller.sourceLanguage, equals('fr'));
      expect(controller.targetLanguage, equals('de'));
    });

    test(
        'sends text input, translates, explains, and updates conversation segments',
        () async {
      await controller.sendTextInput('Hello');

      expect(controller.currentConversation.segments.length, equals(1));
      final seg = controller.currentConversation.segments.first;
      expect(seg.originalText, equals('Hello'));
      expect(seg.translatedText.toLowerCase(), contains('hola'));
      expect(controller.state, equals(ConversationState.idle));
      expect(controller.selectedExplanation, isNotNull);
    });

    test('ignores empty or whitespace-only text inputs', () async {
      await controller.sendTextInput('   ');
      expect(controller.currentConversation.segments, isEmpty);
    });

    test('asks general knowledge and records structured question response',
        () async {
      final response = await controller.askKnowledge('What is Kubernetes?');
      expect(response.question, equals('What is Kubernetes?'));
      expect(response.generativeAnswer, isNotEmpty);
      expect(controller.latestKnowledgeResponse, equals(response));
      expect(controller.currentConversation.segments.length, equals(1));
    });

    test(
        'executes voice input workflow and captures actionable errors when uninstalled',
        () async {
      final controllerWithUninstalledSTT = ConversationController(
        sttProvider: LocalSTTProvider(isModelInstalled: false),
      );

      await controllerWithUninstalledSTT.startVoiceInput();
      expect(controllerWithUninstalledSTT.actionableError, isNotNull);
      expect(controllerWithUninstalledSTT.actionableError, contains('Whisper'));

      controllerWithUninstalledSTT.clearError();
      expect(controllerWithUninstalledSTT.actionableError, isNull);
    });

    test('synthesizes speech without errors', () async {
      await controller.speakText('Hola');
      expect(controller.state, equals(ConversationState.idle));
    });

    test('creates and persists reports of various types', () async {
      await controller
          .sendTextInput('What is our target date? We decided on Friday.');
      final report = await controller.createReport(ReportType.quickSummary);

      expect(report.title, contains('Executive Summary'));
      expect(report.content, contains('PROVENANCE & EXECUTION AUDIT'));
      expect(controller.latestReport, equals(report));
    });

    test('updates cloud configuration and executes connection test', () async {
      controller.setCloudConfig(
        apiKey: 'test_api_key_mock',
        modelName: 'gemini-1.5-flash',
        temperature: 0.5,
        maxTokens: 500,
        timeoutMs: 10000,
      );

      expect(controller.cloudApiKey, equals('test_api_key_mock'));
      expect(controller.cloudModelName, equals('gemini-1.5-flash'));
      expect(controller.cloudTemperature, equals(0.5));
      expect(controller.cloudMaxTokens, equals(500));
      expect(controller.cloudTimeoutMs, equals(10000));

      // Test in private offline returns failure without network call
      final testResult = await controller.testCloudConnection();
      expect(testResult.isSuccessful, isFalse);
      expect(testResult.errorMessage, contains('private_offline'));
    });

    test('cancels active operations cleanly', () {
      controller.cancel();
      expect(controller.state, equals(ConversationState.idle));
    });

    test('swaps source and target languages', () {
      controller.setLanguages('en', 'es');
      controller.swapLanguages();
      expect(controller.sourceLanguage, equals('es'));
      expect(controller.targetLanguage, equals('en'));
    });

    test('loads, deletes, and clears conversation sessions', () async {
      await controller.sendTextInput('Session message');
      final id = controller.currentConversation.id;

      await controller.loadConversation(id);
      expect(controller.currentConversation.id, equals(id));

      await controller.deleteConversation(id);
      expect(controller.currentConversation.id, isNot(equals(id)));

      // Delete conversation when id is not current conversation
      await controller.deleteConversation('non_existent_id');

      // Load conversation when conv does not exist
      await controller.loadConversation('non_existent_id');

      await controller.sendTextInput('Another session');
      await controller.clearAllData();
      expect(controller.currentConversation.segments, isEmpty);
    });

    test('selects explanation cleanly', () async {
      await controller.sendTextInput('Explain quantum computing');
      expect(controller.selectedExplanation, isNotNull);

      final exp = controller.selectedExplanation!;
      controller.selectExplanation(null);
      expect(controller.selectedExplanation, isNull);

      controller.selectExplanation(exp);
      expect(controller.selectedExplanation, equals(exp));
    });

    test('theme mode switching and persistence', () {
      controller.setThemeMode(ThemeMode.light);
      expect(controller.themeMode, equals(ThemeMode.light));

      controller.setThemeMode(ThemeMode.dark);
      expect(controller.themeMode, equals(ThemeMode.dark));

      controller.setThemeMode(ThemeMode.system);
      expect(controller.themeMode, equals(ThemeMode.system));
    });

    test('activeProviderName reflects offline, cloud key, and custom router providers', () {
      // Offline mode
      controller.setExecutionMode(ExecutionMode.privateOffline);
      expect(controller.activeProviderName, contains('Offline'));

      // Cloud mode with key
      controller.setExecutionMode(ExecutionMode.cloud);
      controller.setCloudConfig(apiKey: 'gemini_test_key');
      expect(controller.activeProviderName, contains('Gemini'));

      // With custom registered provider
      controller.addProviderConfig(const AIProviderConfig(
        id: 'p-custom',
        type: AIProviderType.openai,
        displayName: 'Custom GPT-4o',
        isDefault: true,
      ));
      expect(controller.activeProviderName, equals('Custom GPT-4o'));
    });

    test('addProviderConfig, removeProviderConfig, and setDefaultProvider', () {
      const config = AIProviderConfig(
        id: 'cfg_test',
        type: AIProviderType.anthropic,
        displayName: 'Claude Sonnet',
        apiKey: 'ant_key_123',
      );

      controller.addProviderConfig(config);
      expect(controller.configuredProviders.any((c) => c.id == 'cfg_test'), isTrue);

      controller.setDefaultProvider('cfg_test');
      expect(controller.router.defaultProviderId, equals('cfg_test'));

      controller.removeProviderConfig('cfg_test');
      expect(controller.configuredProviders.any((c) => c.id == 'cfg_test'), isFalse);
    });

    test('testProviderConfig exercises all provider types', () async {
      // Gemini
      final geminiRes = await controller.testProviderConfig(const AIProviderConfig(
        id: 't-gemini',
        type: AIProviderType.gemini,
        displayName: 'Gemini',
        apiKey: 'test-key',
      ));
      expect(geminiRes, isNotNull);

      // OpenAI
      final openaiRes = await controller.testProviderConfig(const AIProviderConfig(
        id: 't-openai',
        type: AIProviderType.openai,
        displayName: 'OpenAI',
        apiKey: 'sk-test',
      ));
      expect(openaiRes, isNotNull);

      // Anthropic
      final anthropicRes = await controller.testProviderConfig(const AIProviderConfig(
        id: 't-anthropic',
        type: AIProviderType.anthropic,
        displayName: 'Anthropic',
        apiKey: 'sk-ant',
      ));
      expect(anthropicRes, isNotNull);

      // Local
      final localRes = await controller.testProviderConfig(const AIProviderConfig(
        id: 't-local',
        type: AIProviderType.local,
        displayName: 'Local LLM',
      ));
      expect(localRes, isNotNull);

      // AICore
      final aicoreRes = await controller.testProviderConfig(const AIProviderConfig(
        id: 't-aicore',
        type: AIProviderType.aicore,
        displayName: 'AICore',
      ));
      expect(aicoreRes, isNotNull);
    });

    test('meeting lifecycle: startMeeting, pauseMeeting, resumeMeeting, and stopMeeting', () async {
      await controller.startMeeting();
      expect(controller.isMeetingActive, isTrue);
      expect(controller.isMeetingPaused, isFalse);
      expect(controller.mode, equals(ApplicationMode.meeting));
      expect(controller.state, equals(ConversationState.listening));

      controller.pauseMeeting();
      expect(controller.isMeetingPaused, isTrue);
      expect(controller.state, equals(ConversationState.idle));

      controller.resumeMeeting();
      expect(controller.isMeetingPaused, isFalse);
      expect(controller.state, equals(ConversationState.listening));

      final report = await controller.stopMeeting();
      expect(controller.isMeetingActive, isFalse);
      expect(controller.isMeetingPaused, isFalse);
      expect(controller.state, equals(ConversationState.idle));
      expect(report.reportType, equals(ReportType.meetingMinutes));
    });

    test('interview practice mode evaluates answer when segments >= 2', () async {
      controller.setApplicationMode(ApplicationMode.interviewPractice);

      // Segment 1: Question
      await controller.sendTextInput('What is your greatest technical achievement?');

      // Segment 2: Answer
      await controller.sendTextInput(
        'First, I redesigned the data pipeline to scale under load. '
        'Because latency was high, we introduced caching and verified the result with automated tests.',
      );

      expect(controller.currentConversation.assessments, isNotEmpty);
      final assess = controller.currentConversation.assessments.first;
      expect(assess.overallScore, greaterThan(0));
      expect(assess.rubrics, isNotEmpty);
    });

    test('speakText with empty text returns early', () async {
      await controller.speakText('   ');
      expect(controller.state, equals(ConversationState.idle));
    });

    test('clearSession resets session and clears explanation', () async {
      await controller.sendTextInput('Temporary note');
      expect(controller.selectedExplanation, isNotNull);

      controller.clearSession();
      expect(controller.currentConversation.segments, isEmpty);
      expect(controller.selectedExplanation, isNull);
    });

    test('QA mode, autoTts, speaker, and capability routing methods', () {
      expect(controller.isQaMode, isFalse);
      controller.setQaMode(true);
      expect(controller.isQaMode, isTrue);
      controller.toggleQaMode();
      expect(controller.isQaMode, isFalse);

      expect(controller.autoTts, isFalse);
      controller.setAutoTts(true);
      expect(controller.autoTts, isTrue);

      expect(controller.activeListeningSpeaker, equals('You'));
      controller.setActiveListeningSpeaker('Partner');
      expect(controller.activeListeningSpeaker, equals('Partner'));

      controller.setCapabilityRoute('qa', 'Local GGUF');
      expect(controller.qaRoute, equals('Local GGUF'));
      controller.setCapabilityRoute('translation', 'Cloud Translation');
      expect(controller.translationRoute, equals('Cloud Translation'));
      controller.setCapabilityRoute('stt', 'VOSK Offline');
      expect(controller.sttRoute, equals('VOSK Offline'));
      controller.setCapabilityRoute('tts', 'Device TTS');
      expect(controller.ttsRoute, equals('Device TTS'));
      controller.setCapabilityRoute('summarization', 'Gemini Nano');
      expect(controller.summarizationRoute, equals('Gemini Nano'));
      controller.setCapabilityRoute('unknown', 'Fallback');

      controller.setActionableError('Test error message');
      expect(controller.actionableError, equals('Test error message'));
      controller.clearError();
      expect(controller.actionableError, isNull);
    });

    test('Q&A pipeline routes /ask, ask:, explicit intent, and isQaMode to askQuestion', () async {
      // 1. /ask prefix
      await controller.sendTextInput('/ask What is quantum computing?');
      expect(controller.currentConversation.segments.length, equals(2));
      final userSeg = controller.currentConversation.segments.first;
      final aiSeg = controller.currentConversation.segments.last;
      expect(userSeg.originalText, equals('What is quantum computing?'));
      expect(userSeg.intent, equals(InteractionIntent.qa));
      expect(aiSeg.isAiResponse, isTrue);
      expect(aiSeg.originalText, isNotEmpty);

      // 2. ask: prefix
      await controller.sendTextInput('ask: What is photosynthesis?');
      expect(controller.currentConversation.segments.length, equals(4));

      // 3. Explicit intent
      await controller.sendTextInput(
        'What is distributed consensus?',
        intent: InteractionIntent.qa,
      );
      expect(controller.currentConversation.segments.length, equals(6));

      // 4. isQaMode = true
      controller.setQaMode(true);
      await controller.sendTextInput('What is a neural network?');
      expect(controller.currentConversation.segments.length, equals(8));
      controller.setQaMode(false);
    });

    test('sendTranslation handles same source and target language and autoTts', () async {
      controller.setAutoTts(true);
      // Source == Target: skips translation and uses original text
      await controller.sendTranslation(
        'Same language text',
        sourceLang: 'en',
        targetLang: 'en',
      );
      final lastSeg = controller.currentConversation.segments.last;
      expect(lastSeg.translatedText, equals('Same language text'));
      controller.setAutoTts(false);
    });

    test('sendTranslation executes cloud neural translation prompt path', () async {
      controller.setExecutionMode(ExecutionMode.cloud);
      controller.setCloudConfig(apiKey: 'dummy_cloud_key');
      await controller.sendTranslation('Good morning', sourceLang: 'en', targetLang: 'es');
      expect(controller.currentConversation.segments, isNotEmpty);
      controller.setExecutionMode(ExecutionMode.privateOffline);
    });

    test('startVoiceInput with Partner and QA mode', () async {
      // Voice input as Partner
      await controller.startVoiceInput(speakerName: 'Partner', language: 'es');
      expect(controller.activeListeningSpeaker, equals('Partner'));

      // Voice input with QA mode
      controller.setQaMode(true);
      await controller.startVoiceInput(speakerName: 'You');
      controller.setQaMode(false);
    });

    test('speakText with specific language option', () async {
      await controller.speakText('Hola amigos', language: 'es');
      expect(controller.state, equals(ConversationState.idle));
    });

    test('Android platform speech recognition callbacks via MethodChannel', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
      });

      final androidController = ConversationController();

      // Send onPartialTranscript
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final codec = const StandardMethodCodec();

      await messenger.handlePlatformMessage(
        'com.unicom.ai/speech',
        codec.encodeMethodCall(const MethodCall('onPartialTranscript', {'text': 'Partial speech...'})),
        (data) {},
      );
      expect(androidController.livePartialTranscript, equals('Partial speech...'));

      // Send onFinalTranscript in normal translation mode (You)
      await messenger.handlePlatformMessage(
        'com.unicom.ai/speech',
        codec.encodeMethodCall(const MethodCall('onFinalTranscript', {'text': 'Final speech You'})),
        (data) {},
      );
      expect(androidController.livePartialTranscript, isNull);

      // Send onFinalTranscript in normal translation mode (Partner)
      androidController.setActiveListeningSpeaker('Partner');
      await messenger.handlePlatformMessage(
        'com.unicom.ai/speech',
        codec.encodeMethodCall(const MethodCall('onFinalTranscript', {'text': 'Final speech Partner'})),
        (data) {},
      );

      // Send onFinalTranscript in QA mode
      androidController.setQaMode(true);
      await messenger.handlePlatformMessage(
        'com.unicom.ai/speech',
        codec.encodeMethodCall(const MethodCall('onFinalTranscript', {'text': 'What is deep learning? final'})),
        (data) {},
      );
      androidController.setQaMode(false);

      // Send onFinalTranscript in Meeting mode
      await androidController.startMeeting();
      await messenger.handlePlatformMessage(
        'com.unicom.ai/speech',
        codec.encodeMethodCall(const MethodCall('onFinalTranscript', {'text': 'Meeting contribution speech'})),
        (data) {},
      );
      await androidController.stopMeeting();

      // Send onError normal silence (code 7) during meeting
      await androidController.startMeeting();
      await messenger.handlePlatformMessage(
        'com.unicom.ai/speech',
        codec.encodeMethodCall(const MethodCall('onError', {'message': 'No speech', 'code': 7})),
        (data) {},
      );
      expect(androidController.actionableError, isNull);
      await androidController.stopMeeting();

      // Send onError non-silence error
      await messenger.handlePlatformMessage(
        'com.unicom.ai/speech',
        codec.encodeMethodCall(const MethodCall('onError', {'message': 'Mic hardware error', 'code': 9})),
        (data) {},
      );
      expect(androidController.actionableError, equals('Mic hardware error'));

      // Send onListeningStopped
      await messenger.handlePlatformMessage(
        'com.unicom.ai/speech',
        codec.encodeMethodCall(const MethodCall('onListeningStopped', {})),
        (data) {},
      );
      expect(androidController.state, equals(ConversationState.idle));
    });
  });
}
