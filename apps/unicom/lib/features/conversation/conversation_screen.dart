import 'package:flutter/material.dart';
import 'package:unicom_contracts/contracts.dart';
import '../../app/theme.dart';
import '../../ui/adaptive/responsive_breakpoints.dart';
import '../../ui/components/status_badge.dart';
import '../../ui/components/conversation_bubble.dart';
import '../../ui/components/explanation_card.dart';
import 'conversation_state_notifier.dart';

class ConversationScreen extends StatefulWidget {
  final ConversationController controller;

  const ConversationScreen({super.key, required this.controller});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const List<Map<String, String>> _availableLangs = [
    {'code': 'en', 'name': 'English'},
    {'code': 'es', 'name': 'Español'},
    {'code': 'fr', 'name': 'Français'},
    {'code': 'de', 'name': 'Deutsch'},
    {'code': 'zh', 'name': '中文'},
    {'code': 'ja', 'name': '日本語'},
    {'code': 'ar', 'name': 'العربية'},
    {'code': 'hi', 'name': 'हिन्दी'},
    {'code': 'ta', 'name': 'தமிழ்'},
    {'code': 'pt', 'name': 'Português'},
    {'code': 'ru', 'name': 'Русский'},
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final isSplit = !ResponsiveLayout.isPhone(context);

        return Scaffold(
          appBar: _buildAppBar(context),
          body: isSplit ? _buildSplitLayout(context) : _buildPhoneLayout(context),
          bottomNavigationBar: _buildBottomActionBar(context),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(widget.controller.currentConversation.title),
              const SizedBox(width: 8),
              StatusBadge(
                executionMode: widget.controller.executionMode,
                state: widget.controller.state,
              ),
            ],
          ),
        ],
      ),
      actions: [
        _buildLanguageSelector(context),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: UnicomTheme.darkSurfaceVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            value: widget.controller.sourceLanguage,
            underline: const SizedBox(),
            isDense: true,
            items: _availableLangs.map((lang) {
              return DropdownMenuItem(
                value: lang['code'],
                child: Text(lang['code']!.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                widget.controller.setLanguages(val, widget.controller.targetLanguage);
              }
            },
          ),
          const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
          DropdownButton<String>(
            value: widget.controller.targetLanguage,
            underline: const SizedBox(),
            isDense: true,
            items: _availableLangs.map((lang) {
              return DropdownMenuItem(
                value: lang['code'],
                child: Text(lang['code']!.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                widget.controller.setLanguages(widget.controller.sourceLanguage, val);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSplitLayout(BuildContext context) {
    return Row(
      children: [
        // Left pane: Conversation Dialogue (60% space)
        Expanded(
          flex: 6,
          child: _buildConversationList(context),
        ),
        const VerticalDivider(width: 1, color: UnicomTheme.darkSurfaceVariant),
        // Right pane: Real-time Explanations & Insights (40% space)
        Expanded(
          flex: 4,
          child: _buildInsightsPanel(context),
        ),
      ],
    );
  }

  Widget _buildPhoneLayout(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildConversationList(context)),
        if (widget.controller.selectedExplanation != null)
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ExplanationCard(explanation: widget.controller.selectedExplanation!),
          ),
      ],
    );
  }

  Widget _buildConversationList(BuildContext context) {
    final segments = widget.controller.currentConversation.segments;

    if (segments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.record_voice_over, size: 56, color: UnicomTheme.accentCyan.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              'Universal Communication Intelligence',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Type or tap the microphone to begin translating in real-time.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(ResponsiveLayout.contentPadding(context)),
      itemCount: segments.length,
      itemBuilder: (context, index) {
        final seg = segments[index];
        final isSelected = widget.controller.selectedExplanation?.segmentId == seg.id;

        return ConversationBubble(
          segment: seg,
          isExplanationActive: isSelected,
          onSpeak: () => widget.controller.speakText(seg.translatedText),
          onExplain: () {
            if (seg.explanation != null) {
              widget.controller.selectExplanation(seg.explanation);
            }
          },
        );
      },
    );
  }

  Widget _buildInsightsPanel(BuildContext context) {
    final exp = widget.controller.selectedExplanation;
    final conv = widget.controller.currentConversation;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Active Intelligence & Nuance',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 12),
        if (exp != null)
          ExplanationCard(explanation: exp)
        else
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: UnicomTheme.darkSurfaceVariant),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Select any speech bubble to inspect simple, deep, terminology, grammar, cultural, and child-friendly explanations.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        const SizedBox(height: 16),
        if (conv.questions.isNotEmpty) ...[
          const Text('Extracted Questions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          ...conv.questions.map((q) => Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Icon(
                        q.isAnswered ? Icons.check_circle : Icons.help_outline,
                        size: 16,
                        color: q.isAnswered ? UnicomTheme.successGreen : UnicomTheme.warningAmber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(q.questionText, style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              )),
        ],
        if (conv.actionItems.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Action Items', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          ...conv.actionItems.map((a) => Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text('• [${a.assignee}] ${a.title}', style: const TextStyle(fontSize: 13)),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: const Border(top: BorderSide(color: UnicomTheme.darkSurfaceVariant)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Voice Mic Button
            IconButton.filled(
              icon: Icon(
                widget.controller.state == ConversationState.listening
                    ? Icons.stop
                    : Icons.mic,
                color: Colors.white,
              ),
              style: IconButton.styleFrom(
                backgroundColor: widget.controller.state == ConversationState.listening
                    ? UnicomTheme.dangerRed
                    : UnicomTheme.primaryBlue,
              ),
              tooltip: 'Speak',
              onPressed: () {
                if (widget.controller.state == ConversationState.listening) {
                  widget.controller.cancel();
                } else {
                  widget.controller.startVoiceInput();
                }
              },
            ),
            const SizedBox(width: 12),
            // Text Input Field
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Type message to translate...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: UnicomTheme.darkSurfaceVariant),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  isDense: true,
                ),
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    widget.controller.sendTextInput(val);
                    _textController.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: UnicomTheme.primaryBlueLight),
              tooltip: 'Translate and Explain',
              onPressed: () {
                final text = _textController.text.trim();
                if (text.isNotEmpty) {
                  widget.controller.sendTextInput(text);
                  _textController.clear();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
