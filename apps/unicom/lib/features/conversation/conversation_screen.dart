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

  String _langName(String code) {
    return _availableLangs.firstWhere(
      (l) => l['code'] == code,
      orElse: () => {'code': code, 'name': code.toUpperCase()},
    )['name']!;
  }

  void _showExplanationSheet(BuildContext context, ExplanationResult exp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _ExplanationModal(explanation: exp);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Scaffold(
          appBar: _buildAppBar(context),
          body: Column(
            children: [
              _buildErrorBanner(context),
              _buildOfflineModelBanner(context),
              _buildHeroLanguageBar(context),
              Expanded(
                child: isWide
                    ? Row(
                        children: [
                          Expanded(flex: 6, child: _buildConversationList(context)),
                          const VerticalDivider(width: 1, color: UnicomTheme.darkSurfaceVariant),
                          Expanded(flex: 4, child: _buildInsightsPanel(context)),
                        ],
                      )
                    : _buildConversationList(context),
              ),
              _buildListeningIndicator(context),
              _buildPermanentComposer(context),
            ],
          ),
        );
      },
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: UnicomTheme.darkSurfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(Icons.lightbulb_outline, size: 32, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'Select any message to view linguistic nuance, cultural context, and multi-perspective explanations here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
      ],
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
        // Mode toggle: Translate vs Ask AI
        FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.controller.isQaMode ? Icons.auto_awesome : Icons.translate,
                size: 14,
                color: widget.controller.isQaMode
                    ? const Color(0xFFB388FF)
                    : UnicomTheme.accentCyan,
              ),
              const SizedBox(width: 4),
              Text(
                widget.controller.isQaMode ? 'Ask AI' : 'Translate',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          selected: widget.controller.isQaMode,
          onSelected: (val) {
            widget.controller.setQaMode(val);
          },
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        const SizedBox(width: 4),
        // TTS auto playback toggle
        IconButton(
          icon: Icon(
            widget.controller.autoTts ? Icons.volume_up : Icons.volume_off,
            size: 20,
            color: widget.controller.autoTts ? UnicomTheme.accentCyan : Colors.grey,
          ),
          tooltip: widget.controller.autoTts ? 'Auto-TTS On' : 'Auto-TTS Off',
          onPressed: () => widget.controller.setAutoTts(!widget.controller.autoTts),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeroLanguageBar(BuildContext context) {
    if (widget.controller.isQaMode) return const SizedBox.shrink();

    final sName = _langName(widget.controller.sourceLanguage);
    final tName = _langName(widget.controller.targetLanguage);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.6),
        border: const Border(
          bottom: BorderSide(color: UnicomTheme.darkSurfaceVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showLanguagePicker(true),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: UnicomTheme.primaryBlue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('YOU SPEAK',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text(sName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz, size: 22, color: UnicomTheme.accentCyan),
            tooltip: 'Swap Languages',
            visualDensity: VisualDensity.compact,
            onPressed: () => widget.controller.swapLanguages(),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showLanguagePicker(false),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                child: Row(
                  children: [
                    const Icon(Icons.record_voice_over, size: 16, color: UnicomTheme.accentCyan),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('THEY SPEAK',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text(tName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(bool isSource) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  isSource ? 'Select Your Language' : 'Select Partner Language',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableLangs.length,
                  itemBuilder: (ctx, idx) {
                    final l = _availableLangs[idx];
                    final current = isSource
                        ? widget.controller.sourceLanguage
                        : widget.controller.targetLanguage;
                    final isSelected = l['code'] == current;

                    return ListTile(
                      title: Text(l['name']!),
                      subtitle: Text(l['code']!.toUpperCase()),
                      trailing: isSelected ? const Icon(Icons.check, color: UnicomTheme.accentCyan) : null,
                      onTap: () {
                        if (isSource) {
                          widget.controller.setLanguages(l['code']!, widget.controller.targetLanguage);
                        } else {
                          widget.controller.setLanguages(widget.controller.sourceLanguage, l['code']!);
                        }
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _buildConversationList(BuildContext context) {
    final segments = widget.controller.currentConversation.segments;

    if (segments.isEmpty) {
      final isQa = widget.controller.isQaMode;
      final sName = _langName(widget.controller.sourceLanguage);
      final tName = _langName(widget.controller.targetLanguage);

      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hero Center Mic Button
              GestureDetector(
                onTap: () => widget.controller.startVoiceInput(speakerName: 'You'),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isQa
                          ? const [Color(0xFF7C4DFF), Color(0xFF00E5FF)]
                          : const [UnicomTheme.primaryBlue, UnicomTheme.accentCyan],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isQa ? const Color(0xFF7C4DFF) : UnicomTheme.primaryBlue).withOpacity(0.35),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    isQa ? Icons.auto_awesome : Icons.graphic_eq,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isQa ? 'Ask AI Anything' : 'Real-Time Interpreter',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                isQa
                    ? 'Ask questions in any subject: science, technology, history, or grammar.'
                    : 'Instant two-way conversation between $sName and $tName.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Dual Speak Buttons for Bilateral Interpreter
              if (!isQa) ...[
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.record_voice_over, size: 16),
                      label: Text('Speak $sName', style: const TextStyle(fontSize: 12)),
                      onPressed: () => widget.controller.startVoiceInput(speakerName: 'You'),
                    ),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.hearing, size: 16),
                      label: Text('Speak $tName', style: const TextStyle(fontSize: 12)),
                      onPressed: () => widget.controller.startVoiceInput(
                        speakerName: 'Partner',
                        language: widget.controller.targetLanguage,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Suggested prompt chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: isQa
                    ? [
                        _buildPromptChip('What is zoology?'),
                        _buildPromptChip('Explain quantum computing simply'),
                        _buildPromptChip('What is Kubernetes?'),
                        _buildPromptChip('How do transformers work in deep learning?'),
                      ]
                    : [
                        _buildPromptChip('Where is the railway station?'),
                        _buildPromptChip('What is Kubernetes?'),
                        _buildPromptChip('What is zoology?'),
                        _buildPromptChip('How much does this cost?'),
                        _buildPromptChip('Could you please help me?'),
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

        return Column(
          children: [
            ConversationBubble(
              segment: seg,
              onSpeak: () => widget.controller.speakText(
                seg.isAiResponse
                    ? seg.originalText
                    : (seg.translatedText.isNotEmpty ? seg.translatedText : seg.originalText),
                language: seg.isAiResponse ? seg.originalLanguage : seg.targetLanguage,
              ),
              onExplain: () {
                if (seg.explanation != null) {
                  _showExplanationSheet(context, seg.explanation!);
                }
              },
              onTranslate: seg.isAiResponse
                  ? () => widget.controller.sendTranslation(seg.originalText)
                  : null,
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
        if (widget.controller.isQaMode) {
          widget.controller.askQuestion(text);
        } else {
          widget.controller.sendTranslation(text);
        }
        _scrollToBottom();
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
            if (!seg.isAiResponse)
              _buildSmallActionChip(
                icon: Icons.translate,
                label: 'Translate',
                onTap: () {
                  widget.controller.sendTranslation(seg.originalText);
                },
              ),
            if (seg.isAiResponse)
              _buildSmallActionChip(
                icon: Icons.translate,
                label: 'Translate Answer',
                onTap: () {
                  widget.controller.sendTranslation(seg.originalText);
                },
              ),
            const SizedBox(width: 6),
            if (seg.explanation != null)
              _buildSmallActionChip(
                icon: Icons.lightbulb_outline,
                label: 'Explain',
                onTap: () => _showExplanationSheet(context, seg.explanation!),
              ),
            const SizedBox(width: 6),
            _buildSmallActionChip(
              icon: Icons.volume_up_outlined,
              label: 'Listen',
              onTap: () => widget.controller.speakText(
                seg.isAiResponse
                    ? seg.originalText
                    : (seg.translatedText.isNotEmpty ? seg.translatedText : seg.originalText),
                language: seg.isAiResponse ? seg.originalLanguage : seg.targetLanguage,
              ),
            ),
            const SizedBox(width: 6),
            _buildSmallActionChip(
              icon: Icons.copy,
              label: 'Copy',
              onTap: () {
                final text = seg.isAiResponse
                    ? seg.originalText
                    : '${seg.originalText}\n${seg.translatedText}';
                Clipboard.setData(ClipboardData(text: text));
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

  Widget _buildListeningIndicator(BuildContext context) {
    final isListening = widget.controller.state == ConversationState.listening;
    if (!isListening) return const SizedBox.shrink();

    final partial = widget.controller.livePartialTranscript;
    final speaker = widget.controller.activeListeningSpeaker;

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
                  ? '$speaker: $partial'
                  : 'Listening... ($speaker)',
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
    final isQa = widget.controller.isQaMode;
    final sName = _langName(widget.controller.sourceLanguage);
    final tName = _langName(widget.controller.targetLanguage);

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
                  hintText: isQa
                      ? 'Ask AI anything...'
                      : 'Type in $sName to translate to $tName...',
                  hintStyle: const TextStyle(fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: UnicomTheme.darkSurfaceVariant),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  isDense: true,
                ),
                onSubmitted: (val) {
                  final text = val.trim();
                  if (text.isNotEmpty) {
                    if (isQa) {
                      widget.controller.askQuestion(text);
                    } else {
                      widget.controller.sendTranslation(text);
                    }
                    _textController.clear();
                    _scrollToBottom();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            // Primary speaker mic button
            IconButton.filledTonal(
              icon: Icon(
                isListening ? Icons.stop : Icons.mic,
                size: 24,
                color: isListening ? UnicomTheme.dangerRed : null,
              ),
              tooltip: isListening ? 'Stop' : 'Speak ($sName)',
              onPressed: () {
                if (isListening) {
                  widget.controller.cancel();
                } else {
                  widget.controller.startVoiceInput(speakerName: 'You');
                }
              },
            ),
            // Partner mic button (if in translation mode)
            if (!isQa) ...[
              const SizedBox(width: 4),
              IconButton.filledTonal(
                icon: const Icon(Icons.record_voice_over, size: 20),
                tooltip: 'Partner Speak ($tName)',
                onPressed: () {
                  if (isListening) {
                    widget.controller.cancel();
                  } else {
                    widget.controller.startVoiceInput(
                      speakerName: 'Partner',
                      language: widget.controller.targetLanguage,
                    );
                  }
                },
              ),
            ],
            const SizedBox(width: 6),
            IconButton.filled(
              icon: const Icon(Icons.send, size: 24),
              tooltip: 'Send',
              onPressed: () {
                final text = _textController.text.trim();
                if (text.isNotEmpty) {
                  if (isQa) {
                    widget.controller.askQuestion(text);
                  } else {
                    widget.controller.sendTranslation(text);
                  }
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

class _ExplanationModal extends StatefulWidget {
  final ExplanationResult explanation;

  const _ExplanationModal({required this.explanation});

  @override
  State<_ExplanationModal> createState() => _ExplanationModalState();
}

class _ExplanationModalState extends State<_ExplanationModal> {
  ExplanationPersona _persona = ExplanationPersona.simple;

  static const List<Map<String, dynamic>> _personas = [
    {'persona': ExplanationPersona.simple, 'label': 'Simple'},
    {'persona': ExplanationPersona.detailed, 'label': 'Detailed'},
    {'persona': ExplanationPersona.terminology, 'label': 'Technical'},
    {'persona': ExplanationPersona.childFriendly, 'label': 'Child-Friendly'},
    {'persona': ExplanationPersona.grammar, 'label': 'Grammar'},
  ];

  @override
  Widget build(BuildContext context) {
    final entry = widget.explanation.explanations[_persona];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: UnicomTheme.accentCyan, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Explanation & Nuances',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Persona chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _personas.map((p) {
                  final persona = p['persona'] as ExplanationPersona;
                  final label = p['label'] as String;
                  final isSelected = persona == _persona;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _persona = persona);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            if (entry != null) ...[
              SelectableText(
                entry.content,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              if (entry.keyPoints.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: entry.keyPoints.map((pt) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: UnicomTheme.primaryBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        pt,
                        style: const TextStyle(
                          fontSize: 11,
                          color: UnicomTheme.primaryBlueLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ] else ...[
              const Text(
                'Explanation not yet generated for this persona.',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy Explanation', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  if (entry != null) {
                    Clipboard.setData(ClipboardData(text: entry.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied explanation')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
