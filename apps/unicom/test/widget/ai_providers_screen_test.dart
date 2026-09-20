import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_app/features/conversation/conversation_state_notifier.dart';
import 'package:unicom_app/features/settings/ai_providers_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AIProvidersScreen Widget Tests', () {
    late ConversationController controller;

    setUp(() {
      controller = ConversationController();
    });

    testWidgets('renders default built-in cards and capability routing when empty',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(
        MaterialApp(
          home: AIProvidersScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Title & BYOK banner
      expect(find.text('AI Providers'), findsOneWidget);
      expect(find.textContaining('BYOK'), findsOneWidget);

      // Capability Routing
      expect(find.text('Capability Routing'), findsOneWidget);
      expect(find.text('General Q&A'), findsOneWidget);
      expect(find.text('Translation'), findsOneWidget);

      // Default built-in cards
      expect(find.text('Google Gemini (Default)'), findsOneWidget);
      expect(find.text('Android System AICore'), findsOneWidget);
      expect(find.text('Downloaded Local Model'), findsOneWidget);

      // Test connection on default Gemini card
      final testConnBtn = find.widgetWithText(FilledButton, 'Test Connection').first;
      await tester.tap(testConnBtn);
      await tester.pumpAndSettle();
      // Should show error or status since offline mode
      expect(find.textContaining('private_offline'), findsOneWidget);
    });

    testWidgets('opens Add Provider dialog, switches types, and saves provider',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(
        MaterialApp(
          home: AIProvidersScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Add Provider
      final addBtn = find.byIcon(Icons.add).first;
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.text('Add AI Provider'), findsOneWidget);

      // Change type to OpenAI
      await tester.tap(find.byType(DropdownButtonFormField<AIProviderType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OpenAI').last);
      await tester.pumpAndSettle();

      // Change type to Anthropic
      await tester.tap(find.byType(DropdownButtonFormField<AIProviderType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anthropic Claude').last);
      await tester.pumpAndSettle();

      // Change type to Custom OpenAI-Compatible
      await tester.tap(find.byType(DropdownButtonFormField<AIProviderType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Custom OpenAI-Compatible').last);
      await tester.pumpAndSettle();

      // Toggle obscureKey
      final visibilityBtn = find.byIcon(Icons.visibility);
      await tester.tap(visibilityBtn);
      await tester.pumpAndSettle();

      // Save Provider
      final saveBtn = find.widgetWithText(FilledButton, 'Save Provider');
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(controller.configuredProviders.length, equals(1));
      expect(find.text('Custom LLM'), findsOneWidget);
    });

    testWidgets('manages configured provider: test connection, set default, and delete',
        (tester) async {
      controller.addProviderConfig(const AIProviderConfig(
        id: 'cfg_1',
        type: AIProviderType.openai,
        displayName: 'OpenAI Prod',
        apiKey: 'sk-test',
        modelId: 'gpt-4o',
        baseUrl: 'https://api.openai.com',
      ));
      controller.addProviderConfig(const AIProviderConfig(
        id: 'cfg_2',
        type: AIProviderType.anthropic,
        displayName: 'Claude Prod',
        apiKey: 'sk-ant-test',
        modelId: 'claude-3-5-sonnet-20241022',
        isDefault: true,
      ));

      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(
        MaterialApp(
          home: AIProvidersScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OpenAI Prod'), findsOneWidget);
      expect(find.text('Claude Prod'), findsOneWidget);
      expect(find.text('DEFAULT'), findsOneWidget);

      // Test connection on configured provider
      final testBtn = find.widgetWithText(FilledButton, 'Test Connection').first;
      await tester.tap(testBtn);
      await tester.pumpAndSettle();

      // Open popup menu on first provider and set default
      final moreBtn = find.byIcon(Icons.more_vert).first;
      await tester.tap(moreBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Set as Default'));
      await tester.pumpAndSettle();
      expect(controller.router.defaultProviderId, equals('cfg_1'));

      // Open popup menu and delete
      final moreBtn2 = find.byIcon(Icons.more_vert).first;
      await tester.tap(moreBtn2);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete Provider'));
      await tester.pumpAndSettle();
      expect(controller.configuredProviders.length, equals(1));
    });
  });
}
