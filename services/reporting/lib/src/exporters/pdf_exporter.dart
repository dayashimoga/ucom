import 'dart:convert';
import 'dart:typed_data';
import 'package:unicom_contracts/contracts.dart';

class PdfExporter {
  Uint8List exportPdf(GeneratedReport report) {
    final buffer = StringBuffer();
    final lines = report.content.split('\n');

    // Build PDF text stream
    final streamBuffer = StringBuffer();
    streamBuffer.writeln('BT');
    streamBuffer.writeln('/F1 16 Tf');
    streamBuffer.writeln('50 740 Td');
    streamBuffer.writeln('(${_escapePdf(report.title)}) Tj');
    streamBuffer.writeln('/F1 10 Tf');
    streamBuffer.writeln('0 -24 Td');
    streamBuffer.writeln('(Generated on: ${_escapePdf(report.createdAt)}) Tj');
    streamBuffer.writeln('0 -20 Td');

    int yOffset = 0;
    for (final rawLine in lines.take(45)) {
      final line = rawLine.replaceAll(RegExp(r'[#*`_]'), '').trim();
      if (line.isEmpty) {
        streamBuffer.writeln('0 -14 Td');
      } else {
        streamBuffer.writeln('(${_escapePdf(line)}) Tj');
        streamBuffer.writeln('0 -12 Td');
      }
      yOffset += 12;
      if (yOffset > 600) break;
    }

    streamBuffer.writeln('ET');
    final streamContent = streamBuffer.toString();
    final streamBytes = utf8.encode(streamContent);

    // Assembly of PDF objects
    final offsets = <int>[];
    buffer.write('%PDF-1.4\n');

    // Obj 1: Catalog
    offsets.add(buffer.length);
    buffer.write('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');

    // Obj 2: Pages
    offsets.add(buffer.length);
    buffer.write('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n');

    // Obj 3: Page
    offsets.add(buffer.length);
    buffer.write('3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj\n');

    // Obj 4: Content Stream
    offsets.add(buffer.length);
    buffer.write('4 0 obj\n<< /Length ${streamBytes.length} >>\nstream\n');
    buffer.write(streamContent);
    buffer.write('\nendstream\nendobj\n');

    // Obj 5: Font
    offsets.add(buffer.length);
    buffer.write('5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n');

    // XRef Table
    final xrefStart = buffer.length;
    buffer.write('xref\n0 6\n0000000000 65535 f \n');
    for (final offset in offsets) {
      buffer.write('${offset.toString().padLeft(10, '0')} 00000 n \n');
    }

    // Trailer
    buffer.write('trailer\n<< /Size 6 /Root 1 0 R >>\n');
    buffer.write('startxref\n$xrefStart\n%%EOF\n');

    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  String _escapePdf(String input) {
    return input
        .replaceAll('\\', '\\\\')
        .replaceAll('(', '\\(')
        .replaceAll(')', '\\)')
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '?');
  }
}
