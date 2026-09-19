import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unicom_contracts/contracts.dart';
import '../../app/theme.dart';
import '../conversation/conversation_state_notifier.dart';

class HistoryScreen extends StatefulWidget {
  final ConversationController controller;
  final VoidCallback? onOpenLive;

  const HistoryScreen({
    super.key,
    required this.controller,
    this.onOpenLive,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Conversation> _conversations = [];
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final list = await widget.controller.storage.listConversations(
        query: _searchQuery.isNotEmpty ? _searchQuery : null,
        limit: 100,
      );
      if (mounted) {
        setState(() {
          _conversations = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadHistory,
          ),
          if (_conversations.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear All History',
              onPressed: _confirmClearAll,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search past conversations...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _loadHistory();
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: UnicomTheme.darkSurfaceVariant),
                ),
                isDense: true,
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim());
                _loadHistory();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const SizedBox.shrink()
                : _conversations.isEmpty
                    ? _buildEmptyState()
                    : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off,
                size: 56, color: UnicomTheme.accentCyan.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'No Saved Conversations',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your conversations and translated dialogues will appear here after each session.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conv = _conversations[index];
        final segmentCount = conv.segments.length;
        final preview = conv.segments.isNotEmpty
            ? conv.segments.last.originalText
            : 'No messages';

        final dateFormatted = _formatTimestamp(conv.startedAt);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              await widget.controller.loadConversation(conv.id);
              widget.onOpenLive?.call();
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Loaded session: ${conv.title}')),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: UnicomTheme.primaryBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$segmentCount msgs',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: UnicomTheme.primaryBlueLight),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    preview,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        dateFormatted,
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        tooltip: 'Copy all',
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          final buffer = StringBuffer();
                          for (final seg in conv.segments) {
                            buffer.writeln('${seg.speakerName}: ${seg.originalText}');
                            if (seg.translatedText.isNotEmpty) {
                              buffer.writeln('  -> ${seg.translatedText}');
                            }
                          }
                          Clipboard.setData(ClipboardData(text: buffer.toString()));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied conversation to clipboard')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 16, color: UnicomTheme.dangerRed),
                        tooltip: 'Delete',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _confirmDelete(conv),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(Conversation conv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text('Are you sure you want to delete "${conv.title}"?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: UnicomTheme.dangerRed),
            child: const Text('Delete'),
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.controller.deleteConversation(conv.id);
              await _loadHistory();
            },
          ),
        ],
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text(
            'This will permanently delete all saved conversation records from this device. Continue?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: UnicomTheme.dangerRed),
            child: const Text('Clear All'),
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.controller.clearAllData();
              await _loadHistory();
            },
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        return 'Today at $h:$m';
      }
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso.length >= 16 ? iso.substring(0, 16) : iso;
    }
  }
}
