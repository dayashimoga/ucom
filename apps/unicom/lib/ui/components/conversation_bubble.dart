import 'package:flutter/material.dart';
import 'package:unicom_contracts/contracts.dart';
import '../../app/theme.dart';

class ConversationBubble extends StatelessWidget {
  final ConversationSegment segment;
  final VoidCallback onSpeak;
  final VoidCallback onExplain;
  final bool isExplanationActive;

  const ConversationBubble({
    Key? key,
    required this.segment,
    required this.onSpeak,
    required this.onExplain,
    this.isExplanationActive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMe = segment.speakerName.toLowerCase() == 'you';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMe
            ? UnicomTheme.primaryBlue.withOpacity(0.08)
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe
              ? UnicomTheme.primaryBlue.withOpacity(0.3)
              : UnicomTheme.darkSurfaceVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Speaker name & timestamp
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: isMe ? UnicomTheme.primaryBlue : UnicomTheme.accentCyan,
                child: Text(
                  segment.speakerName[0].toUpperCase(),
                  style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                segment.speakerName,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(width: 6),
              Text(
                '(${segment.originalLanguage.toUpperCase()} → ${segment.targetLanguage.toUpperCase()})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
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
                tooltip: 'Explain nuances',
                onPressed: onExplain,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Original text
          Text(
            segment.originalText,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          if (segment.translatedText.isNotEmpty && segment.translatedText != segment.originalText) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.translate, size: 14, color: UnicomTheme.accentCyan),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      segment.translatedText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: UnicomTheme.accentCyan,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
