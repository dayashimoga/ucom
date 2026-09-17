import 'dart:convert';
import 'package:unicom_contracts/contracts.dart';

class JsonExporter {
  String export(GeneratedReport report) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(report.toJson());
  }

  String exportConversation(Conversation conversation) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(conversation.toJson());
  }
}
