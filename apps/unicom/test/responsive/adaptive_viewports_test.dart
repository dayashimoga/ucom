import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unicom_model_runtime/model_runtime.dart';
import 'package:unicom_app/app/app.dart';
import 'package:unicom_app/features/conversation/conversation_state_notifier.dart';

void main() {
  group('Adaptive Viewports & Responsive Layout Tests', () {
    late ConversationController controller;
    late LocalModelManager modelManager;

    setUp(() {
      controller = ConversationController();
      modelManager = LocalModelManager();
    });

    final targetViewports = <String, Size>{
      '360x800 (Compact Phone)': const Size(360, 800),
      '390x844 (Standard Phone)': const Size(390, 844),
      '430x932 (Large Phone)': const Size(430, 932),
      '800x1280 (Portrait Tablet)': const Size(800, 1280),
      '1280x800 (Landscape Tablet)': const Size(1280, 800),
      '1024x1366 (iPad Pro / 4:3)': const Size(1024, 1366),
      '1280x720 (720p Desktop)': const Size(1280, 720),
      '1440x900 (Laptop)': const Size(1440, 900),
      '1920x1080 (FHD Desktop)': const Size(1920, 1080),
    };

    for (final entry in targetViewports.entries) {
      final name = entry.key;
      final size = entry.value;

      testWidgets('validates viewport $name without overflow or clipping',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(UnicomApp(
          controller: controller,
          modelManager: modelManager,
        ));
        await tester.pumpAndSettle();

        expect(find.byType(UnicomApp), findsOneWidget);
        expect(tester.takeException(), isNull,
            reason: 'RenderFlex overflow occurred on viewport $name');
      });

      testWidgets('validates viewport $name in landscape orientation',
          (tester) async {
        final landscapeSize = Size(
            size.height > size.width ? size.height : size.width,
            size.height > size.width ? size.width : size.height);
        tester.view.physicalSize = landscapeSize;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(UnicomApp(
          controller: controller,
          modelManager: modelManager,
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: 'RenderFlex overflow in landscape $name');
      });
    }

    testWidgets(
        'validates 100% to 200% text scaling on compact 360x800 phone without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      for (final scaleFactor in [1.0, 1.25, 1.5, 1.75, 2.0]) {
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(
              size: const Size(360, 800),
              textScaler: TextScaler.linear(scaleFactor),
            ),
            child: UnicomApp(
              controller: controller,
              modelManager: modelManager,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final err = tester.takeException();
        if (err is FlutterError) {
          for (final node in err.diagnostics) {
            debugPrint('DIAG: ${node.name} -> $node');
          }
        }
        expect(err, isNull,
            reason: 'RenderFlex overflow at text scale $scaleFactor');
      }
    });
  });
}
