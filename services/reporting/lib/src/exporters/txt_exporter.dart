import 'package:unicom_contracts/contracts.dart';

class TextExporter {
  String export(GeneratedReport report) {
    // Strip markdown headers and styling for clean plain text
    final clean = report.content
        .replaceAll(RegExp(r'^#+\s+', multiLine: true), '')
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1')
        .replaceAll(RegExp(r'^>\s+', multiLine: true), '  ');
    return clean;
  }
}
