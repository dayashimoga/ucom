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
  });
}
