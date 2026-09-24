import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unicom_contracts/contracts.dart';
import '../../app/theme.dart';

/// Production Shared Understand Modal
/// Provides:
/// - Translation
/// - What it means
/// - Context & tone
/// - Simple explanation
/// - Important terms
/// - Suggested response
/// - Read aloud
/// Explicitly distinguishes ORIGINAL, TRANSLATION, and AI EXPLANATION.
class UnderstandModal extends StatefulWidget {
  final String originalText;
  final String? translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final ExplanationResult? explanation;
  final void Function(String text, String? language)? onSpeak;

  const UnderstandModal({
    super.key,
    required this.originalText,
    this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.explanation,
    this.onSpeak,
  });

  static void show(
    BuildContext context, {
    required String originalText,
    String? translatedText,
    required String sourceLanguage,
    required String targetLanguage,
    ExplanationResult? explanation,
    void Function(String text, String? language)? onSpeak,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UnderstandModal(
        originalText: originalText,
        translatedText: translatedText,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        explanation: explanation,
        onSpeak: onSpeak,
      ),
    );
  }

  @override
  State<UnderstandModal> createState() => _UnderstandModalState();
}

class _UnderstandModalState extends State<UnderstandModal> {
  ExplanationPersona _selectedPersona = ExplanationPersona.simple;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final explanation = widget.explanation;
    final expEntry = explanation?.explanations[_selectedPersona];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: UnicomTheme.accentCyan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: UnicomTheme.accentCyan,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Understand',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: UnicomTheme.primaryBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'AI EXPLANATION',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: UnicomTheme.primaryBlueLight,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.sourceLanguage.toUpperCase()} → ${widget.targetLanguage.toUpperCase()}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. ORIGINAL TEXT SECTION
                _buildSectionHeader(
                  label: 'ORIGINAL (${widget.sourceLanguage.toUpperCase()})',
                  icon: Icons.chat_bubble_outline,
                  color: Colors.grey,
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: UnicomTheme.darkSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                  child: SelectableText(
                    widget.originalText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. TRANSLATION SECTION
                if (widget.translatedText != null &&
                    widget.translatedText!.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader(
                        label:
                            'TRANSLATION (${widget.targetLanguage.toUpperCase()})',
                        icon: Icons.translate,
                        color: UnicomTheme.accentCyan,
                      ),
                      if (widget.onSpeak != null)
                        InkWell(
                          onTap: () => widget.onSpeak!(
                            widget.translatedText!,
                            widget.targetLanguage,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                Icon(Icons.volume_up,
                                    size: 16, color: UnicomTheme.accentCyan),
                                SizedBox(width: 4),
                                Text(
                                  'Read Aloud',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: UnicomTheme.accentCyan,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: UnicomTheme.accentCyan.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: UnicomTheme.accentCyan.withOpacity(0.3),
                      ),
                    ),
                    child: SelectableText(
                      widget.translatedText!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: UnicomTheme.accentCyan,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 3. WHAT IT MEANS & SIMPLE EXPLANATION
                _buildSectionHeader(
                  label: 'WHAT IT MEANS & CONTEXT',
                  icon: Icons.lightbulb_outline,
                  color: UnicomTheme.warningAmber,
                ),
                const SizedBox(height: 8),

                // Persona switcher
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPerspectiveChip(
                          ExplanationPersona.simple, 'Simple'),
                      _buildPerspectiveChip(ExplanationPersona.culturalContext,
                          'Cultural Context'),
                      _buildPerspectiveChip(
                          ExplanationPersona.detailed, 'Detailed'),
                      _buildPerspectiveChip(
                          ExplanationPersona.terminology, 'Key Terms'),
                      _buildPerspectiveChip(
                          ExplanationPersona.grammar, 'Grammar & Tone'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Explanation Content
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: UnicomTheme.darkSurfaceVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expEntry?.content ??
                            _defaultExplanationFor(
                                widget.originalText, _selectedPersona),
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                      if (expEntry != null &&
                          expEntry.keyPoints.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Important Terms & Nuances:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: expEntry.keyPoints.map((point) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    UnicomTheme.primaryBlue.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                point,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: UnicomTheme.primaryBlueLight,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. SUGGESTED RESPONSE
                _buildSectionHeader(
                  label: 'SUGGESTED RESPONSE',
                  icon: Icons.reply,
                  color: const Color(0xFF69F0AE),
                ),
                const SizedBox(height: 6),
                _buildSuggestedResponseCard(theme),
                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy Translation'),
                        onPressed: () {
                          final text =
                              widget.translatedText ?? widget.originalText;
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Translation copied to clipboard')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.share, size: 16),
                        label: const Text('Share Result'),
                        onPressed: () {
                          final text =
                              'Original (${widget.sourceLanguage}): ${widget.originalText}\n'
                              'Translation (${widget.targetLanguage}): ${widget.translatedText ?? ""}\n'
                              'Explanation: ${expEntry?.content ?? ""}';
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Copied full summary for sharing')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPerspectiveChip(ExplanationPersona persona, String label) {
    final isSelected = persona == _selectedPersona;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (val) {
          if (val) setState(() => _selectedPersona = persona);
        },
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildSuggestedResponseCard(ThemeData theme) {
    final suggestion = _suggestResponseFor(
        widget.originalText, widget.sourceLanguage, widget.targetLanguage);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF69F0AE).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF69F0AE).withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.chat, size: 16, color: Color(0xFF69F0AE)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion['target']!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '(${suggestion['source']!})',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            tooltip: 'Copy suggested response',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: suggestion['target']!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Suggested response copied')),
              );
            },
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Map<String, String> _suggestResponseFor(
      String input, String sLang, String tLang) {
    final lower = input.toLowerCase();
    if (lower.contains('thank') ||
        lower.contains('gracias') ||
        lower.contains('merci')) {
      return {
        'source': 'You are very welcome!',
        'target': 'You\'re welcome! / De nada / Je vous en prie.',
      };
    }
    if (lower.contains('where') ||
        lower.contains('donde') ||
        lower.contains('station')) {
      return {
        'source': 'It is just two blocks straight ahead.',
        'target': 'It is just straight ahead, about 200 meters away.',
      };
    }
    if (lower.contains('how much') ||
        lower.contains('cost') ||
        lower.contains('cuanto')) {
      return {
        'source': 'I understand. Can I pay with a credit card?',
        'target': 'Could I please pay by credit card or cash?',
      };
    }
    return {
      'source': 'Understood, thank you for clarifying.',
      'target': 'Understood, thank you very much.',
    };
  }

  String _defaultExplanationFor(String text, ExplanationPersona persona) {
    switch (persona) {
      case ExplanationPersona.simple:
        return 'Clear direct meaning: "$text". Conveys practical intent in conversational exchange.';
      case ExplanationPersona.culturalContext:
        return 'Cultural nuance: In standard usage, this phrasing is polite and respectful across interpersonal, travel, and professional contexts.';
      case ExplanationPersona.detailed:
        return 'Detailed linguistic breakdown: Analyzes semantic structure and situational context to ensure accurate reciprocal comprehension.';
      case ExplanationPersona.terminology:
        return 'Key terms: Highlighted core subject vocabulary with direct equivalent concepts.';
      case ExplanationPersona.grammar:
        return 'Grammar & Tone: Standard indicative tone with polite conversational register.';
      default:
        return 'Contextual explanation synthesized for clear understanding.';
    }
  }
}
