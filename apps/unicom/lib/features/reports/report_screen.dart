import 'package:flutter/material.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_reporting/reporting.dart';
import '../../app/theme.dart';
import '../conversation/conversation_state_notifier.dart';

class ReportScreen extends StatefulWidget {
  final ConversationController controller;

  const ReportScreen({super.key, required this.controller});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportType _selectedType = ReportType.quickSummary;
  GeneratedReport? _activeReport;

  final MarkdownExporter _mdExporter = MarkdownExporter();
  final JsonExporter _jsonExporter = JsonExporter();
  final TextExporter _txtExporter = TextExporter();
  final PdfExporter _pdfExporter = PdfExporter();

  @override
  void initState() {
    super.initState();
    _activeReport = widget.controller.latestReport;
    if (_activeReport == null) {
      _generateReport();
    }
  }

  Future<void> _generateReport() async {
    final rep = await widget.controller.createReport(_selectedType);
    setState(() => _activeReport = rep);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Intelligence Exports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Regenerate',
            onPressed: _generateReport,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            tooltip: 'Export',
            onSelected: _handleExport,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'pdf', child: Text('Export PDF Document (.pdf)')),
              const PopupMenuItem(value: 'md', child: Text('Export Markdown (.md)')),
              const PopupMenuItem(value: 'json', child: Text('Export Structured Data (.json)')),
              const PopupMenuItem(value: 'txt', child: Text('Export Plain Text (.txt)')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Report Type Selector Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).cardTheme.color,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ReportType.values.map((type) {
                  final isSelected = type == _selectedType;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_formatReportTypeName(type)),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedType = type);
                          _generateReport();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Report Content Preview
          Expanded(
            child: _activeReport != null
                ? ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      SelectableText(
                        _activeReport!.content,
                        style: const TextStyle(fontSize: 14, height: 1.6, fontFamily: 'monospace'),
                      ),
                    ],
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  void _handleExport(String format) {
    if (_activeReport == null) return;

    String filename = 'unicom_${_activeReport!.reportType.toJson()}_${DateTime.now().millisecondsSinceEpoch}';
    String message;

    switch (format) {
      case 'pdf':
        final bytes = _pdfExporter.exportPdf(_activeReport!);
        message = 'Exported PDF ($filename.pdf, ${bytes.length} bytes)';
        break;
      case 'md':
        final md = _mdExporter.export(_activeReport!);
        message = 'Exported Markdown ($filename.md, ${md.length} chars)';
        break;
      case 'json':
        final json = _jsonExporter.export(_activeReport!);
        message = 'Exported JSON ($filename.json, ${json.length} chars)';
        break;
      case 'txt':
        final txt = _txtExporter.export(_activeReport!);
        message = 'Exported Plain Text ($filename.txt, ${txt.length} chars)';
        break;
      default:
        message = 'Export completed';
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: UnicomTheme.successGreen,
    ));
  }

  String _formatReportTypeName(ReportType type) {
    switch (type) {
      case ReportType.quickSummary: return 'Quick Summary';
      case ReportType.detailedSummary: return 'Detailed';
      case ReportType.fullTranscript: return 'Full Transcript';
      case ReportType.questionsReport: return 'Questions';
      case ReportType.learningReport: return 'Learning';
      case ReportType.actionItems: return 'Action Items';
      case ReportType.meetingMinutes: return 'Minutes';
      case ReportType.interviewReport: return 'Interview Evaluation';
      case ReportType.vocabularyReport: return 'Vocabulary';
    }
  }
}
