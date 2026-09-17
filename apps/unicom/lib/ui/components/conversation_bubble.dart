import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unicom_contracts/contracts.dart';
import '../../app/theme.dart';

class ConversationBubble extends StatelessWidget {
  final ConversationSegment segment;
  final VoidCallback onSpeak;
  final VoidCallback onExplain;
  final bool isExplanationActive;

  const ConversationBubble({
    super.key,
    required this.segment,
    required this.onSpeak,
    required this.onExplain,
    this.isExplanationActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = segment.speakerName.toLowerCase() == 'you';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'Speech segment from ${segment.speakerName}. Original: ${segment.originalText}. Translation: ${segment.translatedText}',
      container: true,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isMe
              ? UnicomTheme.primaryBlue.withValues(alpha: 0.08)
              : (Theme.of(context).cardTheme.color ?? (isDark ? UnicomTheme.darkSurface : UnicomTheme.lightSurface)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMe
                ? UnicomTheme.primaryBlue.withValues(alpha: 0.3)
                : UnicomTheme.darkSurfaceVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Speaker attribution (honest pre-labelled badge) & language direction
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isMe ? UnicomTheme.primaryBlue : UnicomTheme.accentCyan,
                  child: Text(
                    segment.speakerName.isNotEmpty ? segment.speakerName[0].toUpperCase() : 'P',
                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  segment.speakerName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Pre-labelled',
                    style: TextStyle(fontSize: 10, letterSpacing: 0.2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${segment.originalLanguage.toUpperCase()} → ${segment.targetLanguage.toUpperCase()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                // Copy Action
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  tooltip: 'Copy text',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                      text: '${segment.originalText}\n${segment.translatedText}',
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied transcript and translation to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  visualDensity: VisualDensity.compact,
                ),
                // TTS Speak button
                IconButton(
                  icon: const Icon(Icons.volume_up, size: 18),
                  tooltip: 'Listen to translation',
                  onPressed: onSpeak,
                  visualDensity: VisualDensity.compact,
                ),
                // Explain button
                IconButton(
                  icon: Icon(
                    Icons.psychology,
                    size: 18,
                    color: isExplanationActive ? UnicomTheme.accentCyan : null,
                  ),
                  tooltip: 'Explain nuances across 7 personas',
                  onPressed: onExplain,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ORIGINAL SECTION
            const Text(
              'ORIGINAL',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
            ),
            const SizedBox(height: 2),
            SelectableText(
              segment.originalText,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.4),
            ),

            // TRANSLATION SECTION
            if (segment.translatedText.isNotEmpty && segment.translatedText != segment.originalText) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : Colors.blueGrey.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: UnicomTheme.accentCyan.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.translate, size: 12, color: UnicomTheme.accentCyan),
                        SizedBox(width: 4),
                        Text(
                          'TRANSLATION',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: UnicomTheme.accentCyan),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      segment.translatedText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: UnicomTheme.accentCyan,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
