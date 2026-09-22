import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unicom_contracts/contracts.dart';
import '../../app/theme.dart';

class ConversationBubble extends StatelessWidget {
  final ConversationSegment segment;
  final VoidCallback onSpeak;
  final VoidCallback onExplain;
  final VoidCallback? onTranslate;
  final bool isExplanationActive;

  const ConversationBubble({
    super.key,
    required this.segment,
    required this.onSpeak,
    required this.onExplain,
    this.onTranslate,
    this.isExplanationActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = segment.speakerName.toLowerCase() == 'you';
    final isAi = segment.isAiResponse || segment.speakerName == 'UniCom AI';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isAi
        ? (isDark ? const Color(0xFF1E1B2E) : const Color(0xFFF3F0FC))
        : isMe
            ? UnicomTheme.primaryBlue.withOpacity(0.08)
            : (Theme.of(context).cardTheme.color ??
                (isDark ? UnicomTheme.darkSurface : UnicomTheme.lightSurface));

    final borderColor = isAi
        ? const Color(0xFF7C4DFF).withOpacity(0.35)
        : isMe
            ? UnicomTheme.primaryBlue.withOpacity(0.3)
            : UnicomTheme.darkSurfaceVariant;

    return Semantics(
      label: isAi
          ? 'AI Answer from ${segment.aiModelName ?? "UniCom AI"}: ${segment.originalText}'
          : 'Speech segment from ${segment.speakerName}. Original: ${segment.originalText}. Translation: ${segment.translatedText}',
      container: true,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Speaker attribution & metadata
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: isAi
                      ? const Color(0xFF7C4DFF)
                      : isMe
                          ? UnicomTheme.primaryBlue
                          : UnicomTheme.accentCyan,
                  child: isAi
                      ? const Icon(Icons.auto_awesome, size: 14, color: Colors.white)
                      : Text(
                          segment.speakerName.isNotEmpty
                              ? segment.speakerName[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      Text(
                        isAi ? 'UniCom AI' : segment.speakerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      if (isAi && segment.aiModelName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C4DFF).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.3)),
                          ),
                          child: Text(
                            segment.aiModelName!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFB388FF),
                            ),
                          ),
                        ),
                      if (!isAi && segment.intent == InteractionIntent.translation)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              segment.originalLanguage.toUpperCase(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 3),
                            const Icon(Icons.arrow_forward, size: 11, color: Colors.grey),
                            const SizedBox(width: 3),
                            Text(
                              segment.targetLanguage.toUpperCase(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  tooltip: 'Copy',
                  onPressed: () {
                    final textToCopy = isAi
                        ? segment.originalText
                        : (segment.translatedText.isNotEmpty
                            ? '${segment.originalText}\n${segment.translatedText}'
                            : segment.originalText);
                    Clipboard.setData(ClipboardData(text: textToCopy));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up, size: 18),
                  tooltip: 'Listen',
                  onPressed: onSpeak,
                  visualDensity: VisualDensity.compact,
                ),
                if (!isAi && segment.explanation != null)
                  IconButton(
                    icon: Icon(
                      Icons.lightbulb_outline,
                      size: 18,
                      color: isExplanationActive ? UnicomTheme.accentCyan : null,
                    ),
                    tooltip: 'Explain nuances',
                    onPressed: onExplain,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // AI Answer or Original Text
            if (isAi) ...[
              SelectableText(
                segment.originalText,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
              if (onTranslate != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      side: BorderSide(color: UnicomTheme.accentCyan.withOpacity(0.4)),
                    ),
                    icon: const Icon(Icons.translate, size: 14, color: UnicomTheme.accentCyan),
                    label: Text(
                      'Translate to ${segment.targetLanguage.toUpperCase()}',
                      style: const TextStyle(fontSize: 11, color: UnicomTheme.accentCyan),
                    ),
                    onPressed: onTranslate,
                  ),
                ),
              ],
            ] else ...[
              // User original input
              SelectableText(
                segment.originalText,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),

              // TRANSLATION SECTION (Only when authentic translation exists)
              if (segment.intent == InteractionIntent.translation &&
                  segment.translatedText.isNotEmpty &&
                  segment.translatedText != segment.originalText) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.blueGrey.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: UnicomTheme.accentCyan.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.translate, size: 12, color: UnicomTheme.accentCyan),
                          const SizedBox(width: 4),
                          Text(
                            '${segment.targetLanguage.toUpperCase()} TRANSLATION',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: UnicomTheme.accentCyan,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
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
          ],
        ),
      ),
    );
  }
}
