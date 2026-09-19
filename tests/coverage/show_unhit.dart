// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final lcov = File('coverage/lcov.info');
  if (!lcov.existsSync()) {
    print('No lcov.info');
    return;
  }
  final lines = lcov.readAsLinesSync();
  String? current;
  final unhit = <String, List<String>>{};

  for (final l in lines) {
    if (l.startsWith('SF:')) {
      current = l.substring(3).trim();
      unhit[current] = [];
    } else if (l.startsWith('BRDA:') && current != null) {
      final parts = l.substring(5).split(',');
      if (parts.length >= 4 && (parts[3] == '0' || parts[3] == '-')) {
        unhit[current]!.add(parts[0]);
      }
    }
  }

  unhit.forEach((k, v) {
    if (v.isNotEmpty) {
      final rel = k.replaceAll(r'\', '/').split('/unicom/').last;
      print(
          '${v.length} unhit branches in $rel: lines ${v.toSet().join(", ")}');
    }
  });
}
