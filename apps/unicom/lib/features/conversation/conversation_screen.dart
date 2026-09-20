import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final FocusNode _focusNode = FocusNode();

  static const List<Map<String, String>> _availableLangs = [
    {'code': 'en', 'name': 'English'},
    {'code': 'ta', 'name': 'Tamil'},
    {'code': 'es', 'name': 'Spanish'},
    {'code': 'hi', 'name': 'Hindi'},
    {'code': 'fr', 'name': 'French'},
    {'code': 'de', 'name': 'German'},
    {'code': 'ja', 'name': 'Japanese'},
    {'code': 'zh', 'name': 'Chinese'},
    {'code': 'pt', 'name': 'Portuguese'},
    {'code': 'ru', 'name': 'Russian'},
    {'code': 'ar', 'name': 'Arabic'},
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final isSplit = !ResponsiveLayout.isPhone(context);

        return Scaffold(
          appBar: _buildAppBar(context),
          body: Column(
            children: [
              _buildErrorBanner(context),
              _buildOfflineModelBanner(context),
              Expanded(
                child: isSplit
                    ? _buildSplitLayout(context)
                    : _buildPhoneLayout(context),
              ),
              _buildListeningIndicator(context),
              _buildPermanentComposer(context),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'UniCom',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            const SizedBox(width: 8),
            StatusBadge(
              executionMode: widget.controller.executionMode,
              state: widget.controller.state,
            ),
          ],
        ),
      ),
      actions: [
        _buildLanguageSelector(context),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildErrorBanner(BuildContext context) {
    final error = widget.controller.actionableError;
    if (error == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: UnicomTheme.dangerRed,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 16),
            onPressed: () => widget.controller.clearError(),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineModelBanner(BuildContext context) {
    if (widget.controller.executionMode == ExecutionMode.privateOffline &&
        !widget.controller.localLLM.isModelLoaded) {
      return Container(
        width: double.infinity,
        color: UnicomTheme.warningAmber.withOpacity(0.15),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.cloud_download_outlined,
                color: UnicomTheme.warningAmber, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Offline model required for private inference.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () async {
                await widget.controller.modelManager
                    .downloadModel('unicom-knowledge-llm-q4');
                await widget.controller.modelManager
                    .activateModel('unicom-knowledge-llm-q4');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Offline model downloaded & activated.')),
                  );
                }
              },
              child: const Text('Download 50 MB', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildLanguageSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
                child: Text(
                  lang['code']!.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                widget.controller.setLanguages(val, widget.controller.targetLanguage);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz, size: 20, color: UnicomTheme.accentCyan),
            tooltip: 'Swap languages',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(),
            onPressed: () => widget.controller.swapLanguages(),
          ),
          DropdownButton<String>(
            value: widget.controller.targetLanguage,
            underline: const SizedBox(),
            isDense: true,
            items: _availableLangs.map((lang) {
              return DropdownMenuItem(
                value: lang['code'],
                child: Text(
                  lang['code']!.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
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
        Expanded(flex: 6, child: _buildConversationList(context)),
        const VerticalDivider(width: 1, color: UnicomTheme.darkSurfaceVariant),
        Expanded(flex: 4, child: _buildInsightsPanel(context)),
      ],
    );
  }

  Widget _buildPhoneLayout(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildConversationList(context)),
        if (widget.controller.selectedExplanation != null)
          Container(
            constraints: const BoxConstraints(maxHeight: 260),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SingleChildScrollView(
              child: ExplanationCard(
                explanation: widget.controller.selectedExplanation!,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConversationList(BuildContext context) {
    final segments = widget.controller.currentConversation.segments;

    if (segments.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => widget.controller.startVoiceInput(),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [UnicomTheme.primaryBlue, UnicomTheme.accentCyan],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: UnicomTheme.primaryBlue.withOpacity(0.35),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.graphic_eq, size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Talk, type, translate, or ask anything',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap the microphone to speak, or type any question or message below.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildPromptChip('Where is the nearest hospital?'),
                  _buildPromptChip('What is Kubernetes?'),
                  _buildPromptChip('How does the Kubernetes scheduler work?'),
                  _buildPromptChip('Explain quantum entanglement in simple terms'),
                  _buildPromptChip('How are you today?'),
                ],
              ),
            ],
          ),
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

        return Column(
          children: [
            ConversationBubble(
              segment: seg,
              isExplanationActive: isSelected,
              onSpeak: () => widget.controller.speakText(
                seg.translatedText.isNotEmpty ? seg.translatedText : seg.originalText,
              ),
              onExplain: () {
                if (seg.explanation != null) {
                  widget.controller.selectExplanation(seg.explanation);
                }
              },
            ),
            if (index == segments.length - 1)
              _buildContextActions(context, seg),
          ],
        );
      },
    );
  }

  Widget _buildPromptChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        widget.controller.sendTextInput(text);
      },
    );
  }

  Widget _buildContextActions(BuildContext context, ConversationSegment seg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildSmallActionChip(
              icon: Icons.translate,
              label: 'Translate',
              onTap: () {
                widget.controller.sendTextInput(seg.originalText);
              },
            ),
            const SizedBox(width: 6),
            if (seg.explanation != null)
              _buildSmallActionChip(
                icon: Icons.lightbulb_outline,
                label: 'Explain',
                onTap: () => widget.controller.selectExplanation(seg.explanation),
              ),
            const SizedBox(width: 6),
            _buildSmallActionChip(
              icon: Icons.volume_up_outlined,
              label: 'Listen',
              onTap: () => widget.controller.speakText(
                seg.translatedText.isNotEmpty ? seg.translatedText : seg.originalText,
              ),
            ),
            const SizedBox(width: 6),
            _buildSmallActionChip(
              icon: Icons.copy,
              label: 'Copy',
              onTap: () {
                Clipboard.setData(ClipboardData(
                  text: '${seg.originalText}\n${seg.translatedText}',
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
            const SizedBox(width: 6),
            PopupMenuButton<String>(
              tooltip: 'More actions',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: UnicomTheme.darkSurfaceVariant),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.more_horiz, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('More', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              onSelected: (val) {
                if (val == 'clear') widget.controller.clearSession();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 16),
                      SizedBox(width: 8),
                      Text('Clear Session'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: UnicomTheme.darkSurfaceVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: UnicomTheme.accentCyan),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsPanel(BuildContext context) {
    final exp = widget.controller.selectedExplanation;

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
                'Select any conversation bubble to inspect simple, deep, terminology, grammar, cultural, and child-friendly explanations.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildListeningIndicator(BuildContext context) {
    final isListening = widget.controller.state == ConversationState.listening;
    if (!isListening) return const SizedBox.shrink();

    final partial = widget.controller.livePartialTranscript;

    return Container(
      width: double.infinity,
      color: UnicomTheme.primaryBlue.withOpacity(0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: UnicomTheme.dangerRed,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              partial != null && partial.isNotEmpty
                  ? partial
                  : 'Listening... Speak clearly into microphone',
              style: TextStyle(
                fontSize: 13,
                fontWeight: partial != null && partial.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                fontStyle: partial != null && partial.isNotEmpty ? FontStyle.normal : FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => widget.controller.cancel(),
            child: const Text('Stop', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildPermanentComposer(BuildContext context) {
    final isListening = widget.controller.state == ConversationState.listening;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: const Border(
          top: BorderSide(color: UnicomTheme.darkSurfaceVariant),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Talk, type, translate, or ask anything...',
                  hintStyle: const TextStyle(fontSize: 13),
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
                    _scrollToBottom();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              icon: Icon(
                isListening ? Icons.stop : Icons.mic,
                size: 24,
                color: isListening ? UnicomTheme.dangerRed : null,
              ),
              tooltip: isListening ? 'Stop Listening' : 'Voice Input',
              onPressed: () {
                if (isListening) {
                  widget.controller.cancel();
                } else {
                  widget.controller.startVoiceInput();
                }
              },
            ),
            const SizedBox(width: 6),
            IconButton.filled(
              icon: const Icon(Icons.send, size: 24),
              tooltip: 'Send',
              onPressed: () {
                final text = _textController.text.trim();
                if (text.isNotEmpty) {
                  widget.controller.sendTextInput(text);
                  _textController.clear();
                  _scrollToBottom();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
