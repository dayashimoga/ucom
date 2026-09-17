import 'package:flutter/material.dart';
import 'package:unicom_model_runtime/model_runtime.dart';
import 'app/app.dart';
import 'features/conversation/conversation_state_notifier.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = ConversationController();
  final modelManager = LocalModelManager();

  runApp(UnicomApp(
    controller: controller,
    modelManager: modelManager,
  ));
}
