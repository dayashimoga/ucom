import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unicom_contracts/contracts.dart';
import '../../app/theme.dart';
import '../../ui/adaptive/responsive_breakpoints.dart';
import '../../ui/components/status_badge.dart';
import '../../ui/components/conversation_bubble.dart';
import '../../ui/components/explanation_card.dart';
import '../../ui/components/understand_modal.dart';
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

  // Camera HUD interactive state
  bool _isFlashOn = false;
  bool _isFrameFrozen = false;

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
    {'code': 'ko', 'name': 'Korean'},
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

  void _openUnderstandModal({
    required String original,
    String? translation,
    String? sourceLang,
    String? targetLang,
    ExplanationResult? explanation,
  }) {
    UnderstandModal.show(
      context,
      originalText: original,
      translatedText: translation,
      sourceLanguage: sourceLang ?? widget.controller.sourceLanguage,
      targetLanguage: targetLang ?? widget.controller.targetLanguage,
      explanation: explanation ?? widget.controller.selectedExplanation,
      onSpeak: (text, lang) =>
          widget.controller.speakText(text, language: lang),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final heroMode = widget.controller.activeHeroMode;

        return Scaffold(
          appBar: _buildAppBar(context),
          body: Column(
            children: [
              _buildErrorBanner(context),
              _buildOfflineModelBanner(context),
              _buildHeroTabBar(context),
              _buildHeroLanguageBar(context),
              Expanded(
                child: isWide
                    ? Row(
                        children: [
                          Expanded(
                              flex: 6,
                              child: _buildActiveHeroBody(context, heroMode)),
                          const VerticalDivider(
                              width: 1, color: UnicomTheme.darkSurfaceVariant),
                          Expanded(
                              flex: 4, child: _buildInsightsPanel(context)),
                        ],
                      )
                    : _buildActiveHeroBody(context, heroMode),
              ),
              _buildListeningIndicator(context),
              _buildPermanentComposer(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroTabBar(BuildContext context) {
    final currentMode = widget.controller.activeHeroMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.4),
        border: const Border(
          bottom: BorderSide(color: UnicomTheme.darkSurfaceVariant, width: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHeroTabItem(
              mode: 'talk',
              icon: Icons.chat_bubble_outline,
              label: 'Talk',
              isSelected: currentMode == 'talk' && !widget.controller.isQaMode,
              onTap: () {
                if (widget.controller.isQaMode) {
                  widget.controller.setQaMode(false);
                }
                widget.controller.setActiveHeroMode('talk');
              },
            ),
            const SizedBox(width: 4),
            _buildHeroTabItem(
              mode: 'listen',
              icon: Icons.hearing,
              label: 'Listen',
              isSelected: currentMode == 'listen',
              onTap: () {
                if (widget.controller.isQaMode) {
                  widget.controller.setQaMode(false);
                }
                widget.controller.setActiveHeroMode('listen');
              },
            ),
            const SizedBox(width: 4),
            _buildHeroTabItem(
              mode: 'camera',
              icon: Icons.camera_alt_outlined,
              label: 'Camera',
              isSelected: currentMode == 'camera',
              onTap: () {
                if (widget.controller.isQaMode) {
                  widget.controller.setQaMode(false);
                }
                widget.controller.setActiveHeroMode('camera');
              },
            ),
            const SizedBox(width: 4),
            _buildHeroTabItem(
              mode: 'ask',
              icon: Icons.auto_awesome,
              label: 'Ask AI',
              isSelected: currentMode == 'ask' || widget.controller.isQaMode,
              onTap: () {
                widget.controller.setQaMode(true);
                widget.controller.setActiveHeroMode('ask');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroTabItem({
    required String mode,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? UnicomTheme.primaryBlue.withOpacity(0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: UnicomTheme.accentCyan.withOpacity(0.5))
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? UnicomTheme.accentCyan : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveHeroBody(BuildContext context, String heroMode) {
    if (widget.controller.isQaMode || heroMode == 'ask') {
      return _buildConversationList(context);
    }

    switch (heroMode) {
      case 'camera':
        return _buildCameraVisualInterpreter(context);
      case 'listen':
        return _buildAmbientListeningView(context);
      case 'talk':
      default:
        return _buildConversationList(context);
    }
  }

  // ====================================================================
  // 4. CAMERA TRANSLATE / VISUAL INTERPRETER VIEW (P0)
  // ====================================================================

  Widget _buildCameraVisualInterpreter(BuildContext context) {
    final ocrResult = widget.controller.currentOcrResult;
    final isProcessing = widget.controller.isOcrProcessing;
    final isOriginal = widget.controller.isOverlayOriginal;
    final targetLang = widget.controller.targetLanguage;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Camera Viewfinder Canvas with Aligned Overlay
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isProcessing
                    ? UnicomTheme.accentCyan
                    : UnicomTheme.darkSurfaceVariant,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isProcessing ? UnicomTheme.accentCyan : Colors.black)
                      .withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Viewfinder background grid / preview simulation
                  CustomPaint(
                    painter: _ViewfinderPainter(
                      isProcessing: isProcessing,
                      isFrozen: _isFrameFrozen,
                    ),
                  ),

                  // Aligned OCR Text Overlay
                  if (ocrResult != null && ocrResult.blocks.isNotEmpty)
                    ...ocrResult.blocks.map((block) {
                      final box = block.boundingBox;
                      final displayText = isOriginal
                          ? block.text
                          : (block.translatedText ?? block.text);

                      return Positioned(
                        left: box.left * 280,
                        top: box.top * 220 + 20,
                        width: box.width * 280,
                        height: box.height * 220,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOriginal
                                ? Colors.black.withOpacity(0.7)
                                : UnicomTheme.primaryBlue.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isOriginal
                                  ? Colors.white54
                                  : UnicomTheme.accentCyan,
                              width: 1,
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              displayText,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                  // Processing loader
                  if (isProcessing)
                    Container(
                      color: Colors.black45,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                                color: UnicomTheme.accentCyan),
                            SizedBox(height: 12),
                            Text(
                              'Analyzing Visual Script & Layout...',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // HUD Overlay Controls
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.filledTonal(
                          icon: Icon(
                            _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            size: 16,
                            color: _isFlashOn
                                ? UnicomTheme.warningAmber
                                : Colors.white70,
                          ),
                          tooltip: 'Flash',
                          onPressed: () =>
                              setState(() => _isFlashOn = !_isFlashOn),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 6),
                        IconButton.filledTonal(
                          icon: Icon(
                            _isFrameFrozen ? Icons.play_arrow : Icons.pause,
                            size: 16,
                            color: _isFrameFrozen
                                ? UnicomTheme.warningAmber
                                : Colors.white70,
                          ),
                          tooltip:
                              _isFrameFrozen ? 'Resume Camera' : 'Freeze Frame',
                          onPressed: () =>
                              setState(() => _isFrameFrozen = !_isFrameFrozen),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),

                  // HUD Bottom Info Bar
                  Positioned(
                    bottom: 8,
                    left: 12,
                    right: 12,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            ocrResult != null
                                ? 'Detected: ${ocrResult.detectedLanguage.toUpperCase()} (${ocrResult.detectedScript})'
                                : 'Point at signs, menus, or text',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.white70),
                          ),
                        ),
                        const Spacer(),
                        if (ocrResult != null)
                          ActionChip(
                            label: Text(
                              isOriginal ? 'Show Translated' : 'Show Original',
                              style: const TextStyle(fontSize: 10),
                            ),
                            onPressed: () =>
                                widget.controller.toggleOcrOverlayMode(),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Sample Presets for Multi-Script Testing
          const Text(
            'Test Visual Interpreter Across Scripts:',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSampleTargetChip('Korean Menu', 'korean', '🇰🇷'),
                _buildSampleTargetChip('Spanish Sign', 'spanish', '🇪🇸'),
                _buildSampleTargetChip('Japanese Notice', 'japanese', '🇯🇵'),
                _buildSampleTargetChip('Arabic Direction', 'arabic', '🇸🇦'),
                _buildSampleTargetChip('Russian Ticket', 'russian', '🇷🇺'),
                _buildSampleTargetChip('Hindi Board', 'hindi', '🇮🇳'),
                _buildSampleTargetChip('Tamil Sign', 'tamil', '🇮🇳'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. OCR Result Card & Actions
          if (ocrResult != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: UnicomTheme.darkSurfaceVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.document_scanner,
                          size: 18, color: UnicomTheme.accentCyan),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Visual Recognition • ${ocrResult.detectedLanguage.toUpperCase()} → ${targetLang.toUpperCase()}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: UnicomTheme.primaryBlue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.controller.ocrRoute,
                          style: const TextStyle(
                              fontSize: 9, color: UnicomTheme.primaryBlueLight),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  const Text(
                    'TRANSLATED TEXT:',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    (ocrResult.translatedText != null &&
                            ocrResult.translatedText!.isNotEmpty)
                        ? ocrResult.translatedText!
                        : ocrResult.rawText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: UnicomTheme.accentCyan,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ORIGINAL OCR TEXT:',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    ocrResult.rawText,
                    style: const TextStyle(fontSize: 13, height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.volume_up, size: 16),
                        label: const Text('Read Aloud',
                            style: TextStyle(fontSize: 12)),
                        onPressed: () => widget.controller.speakText(
                          (ocrResult.translatedText != null &&
                                  ocrResult.translatedText!.isNotEmpty)
                              ? ocrResult.translatedText!
                              : ocrResult.rawText,
                          language: targetLang,
                        ),
                      ),
                      FilledButton.icon(
                        icon: const Icon(Icons.psychology, size: 16),
                        label: const Text('Understand',
                            style: TextStyle(fontSize: 12)),
                        onPressed: () => _openUnderstandModal(
                          original: ocrResult.rawText,
                          translation: ocrResult.translatedText,
                          sourceLang: ocrResult.detectedLanguage,
                          targetLang: targetLang,
                        ),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.copy, size: 16),
                        label:
                            const Text('Copy', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                            text:
                                '${ocrResult.rawText}\n\n${ocrResult.translatedText ?? ""}',
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('OCR Translation copied')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: UnicomTheme.darkSurfaceVariant),
              ),
              child: const Column(
                children: [
                  Icon(Icons.camera_alt_outlined, size: 36, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    'Real-Time Camera Visual Interpreter',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Point at foreign signs, menus, transit boards, and packaging.\nInstant OCR detects script, bounds text regions, and aligns translated overlays.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSampleTargetChip(String label, String sampleType, String flag) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Text(flag, style: const TextStyle(fontSize: 14)),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        onPressed: () async {
          await widget.controller.processSampleImage(sampleType);
        },
      ),
    );
  }

  // ====================================================================
  // 5. LISTEN & UNDERSTAND VIEW (P0)
  // ====================================================================

  Widget _buildAmbientListeningView(BuildContext context) {
    final isListening = widget.controller.isAmbientListening;
    final audioLevel = widget.controller.ambientAudioLevel;
    final detectedLang = widget.controller.ambientDetectedLang;
    final liveTrans = widget.controller.ambientTranslation;
    final segments = widget.controller.ambientSegments;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Ambient Audio Visualizer & State Hero
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isListening
                    ? UnicomTheme.accentCyan
                    : UnicomTheme.darkSurfaceVariant,
              ),
            ),
            child: Column(
              children: [
                // Audio Radar / Pulsing Circle
                GestureDetector(
                  onTap: () {
                    if (isListening) {
                      widget.controller.stopAmbientListening();
                    } else {
                      widget.controller.startAmbientListening();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 88 + (audioLevel * 30).clamp(0.0, 30.0),
                    height: 88 + (audioLevel * 30).clamp(0.0, 30.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isListening
                            ? const [Color(0xFF00E5FF), Color(0xFF00B0FF)]
                            : const [
                                UnicomTheme.primaryBlue,
                                Color(0xFF0D47A1)
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isListening
                                  ? UnicomTheme.accentCyan
                                  : UnicomTheme.primaryBlue)
                              .withOpacity(0.35),
                          blurRadius: 24,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: Icon(
                      isListening ? Icons.hearing : Icons.mic_none,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isListening
                      ? 'Ambient Listening Active'
                      : 'Listen & Understand',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  isListening
                      ? 'Listening to nearby speech, TV, lectures, and announcements.'
                      : 'One-tap external speech listening with continuous translation.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 12),

                // Language detection pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: UnicomTheme.darkSurfaceVariant.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 12, color: UnicomTheme.accentCyan),
                      const SizedBox(width: 6),
                      Text(
                        'Auto Detection: ${detectedLang.toUpperCase()}',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 1-Tap Control Button
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: isListening
                        ? UnicomTheme.dangerRed
                        : UnicomTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  icon: Icon(isListening ? Icons.stop : Icons.play_arrow),
                  label: Text(isListening
                      ? 'Stop Ambient Listening'
                      : 'Start Listening'),
                  onPressed: () {
                    if (isListening) {
                      widget.controller.stopAmbientListening();
                    } else {
                      widget.controller.startAmbientListening();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Real-Time Streaming Box (Partial STT + Translation)
          if (isListening || liveTrans.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: UnicomTheme.accentCyan.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: UnicomTheme.accentCyan.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: UnicomTheme.dangerRed,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'STREAMING LIVE TRANSLATION:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: UnicomTheme.accentCyan,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    liveTrans.isNotEmpty
                        ? liveTrans
                        : 'Listening for vocal speech...',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: liveTrans.isNotEmpty ? Colors.white : Colors.grey,
                      fontStyle: liveTrans.isNotEmpty
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 3. Captured Ambient Speech Segments
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Captured Speech & Translations:',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey),
              ),
              if (segments.isNotEmpty)
                Text(
                  '${segments.length} segments',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (segments.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'No ambient segments captured yet.\nTap Start Listening to capture nearby audio.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            )
          else
            ...segments.reversed.map((seg) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: UnicomTheme.primaryBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              seg.originalLanguage.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: UnicomTheme.primaryBlueLight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: UnicomTheme.accentCyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              seg.targetLanguage.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: UnicomTheme.accentCyan,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(seg.confidence * 100).toInt()}% conf',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        seg.translatedText.isNotEmpty
                            ? seg.translatedText
                            : seg.originalText,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        seg.originalText,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.volume_up, size: 16),
                            tooltip: 'Read Aloud',
                            onPressed: () => widget.controller.speakText(
                              seg.translatedText.isNotEmpty
                                  ? seg.translatedText
                                  : seg.originalText,
                              language: seg.targetLanguage,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            icon: const Icon(Icons.psychology, size: 16),
                            tooltip: 'Understand',
                            onPressed: () => _openUnderstandModal(
                              original: seg.originalText,
                              translation: seg.translatedText,
                              sourceLang: seg.originalLanguage,
                              targetLang: seg.targetLanguage,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 16),
                            tooltip: 'Copy',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                text:
                                    '${seg.originalText}\n${seg.translatedText}',
                              ));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Segment copied')),
                              );
                            },
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ====================================================================
  // 6. TALK / ASK CONVERSATION VIEW & HERO INTERPRETER
  // ====================================================================

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
              style:
                  TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
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
                widget.controller.isQaMode
                    ? Icons.auto_awesome
                    : Icons.translate,
                size: 14,
                color: widget.controller.isQaMode
                    ? const Color(0xFFB388FF)
                    : UnicomTheme.accentCyan,
              ),
              const SizedBox(width: 4),
              Text(
                widget.controller.isQaMode ? 'Ask AI' : 'Translate',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          selected: widget.controller.isQaMode,
          onSelected: (val) {
            widget.controller.setQaMode(val);
            if (val) {
              widget.controller.setActiveHeroMode('ask');
            } else {
              widget.controller.setActiveHeroMode('talk');
            }
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
            color: widget.controller.autoTts
                ? UnicomTheme.accentCyan
                : Colors.grey,
          ),
          tooltip: widget.controller.autoTts ? 'Auto-TTS On' : 'Auto-TTS Off',
          onPressed: () =>
              widget.controller.setAutoTts(!widget.controller.autoTts),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeroLanguageBar(BuildContext context) {
    if (widget.controller.isQaMode ||
        widget.controller.activeHeroMode == 'ask') {
      return const SizedBox.shrink();
    }

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
                    const Icon(Icons.person,
                        size: 16, color: UnicomTheme.primaryBlue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('YOU SPEAK',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          Text(sName,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
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
            icon: const Icon(Icons.swap_horiz,
                size: 22, color: UnicomTheme.accentCyan),
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
                    const Icon(Icons.record_voice_over,
                        size: 16, color: UnicomTheme.accentCyan),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('THEY SPEAK',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          Text(tName,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
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
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
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
                      trailing: isSelected
                          ? const Icon(Icons.check,
                              color: UnicomTheme.accentCyan)
                          : null,
                      onTap: () {
                        if (isSource) {
                          widget.controller.setLanguages(
                              l['code']!, widget.controller.targetLanguage);
                        } else {
                          widget.controller.setLanguages(
                              widget.controller.sourceLanguage, l['code']!);
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () async {
                await widget.controller.modelManager
                    .downloadModel('unicom-knowledge-llm-q4');
                await widget.controller.modelManager
                    .activateModel('unicom-knowledge-llm-q4');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Offline model downloaded & activated.')),
                  );
                }
              },
              child:
                  const Text('Download 50 MB', style: TextStyle(fontSize: 11)),
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
      final isQa = widget.controller.isQaMode ||
          widget.controller.activeHeroMode == 'ask';
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
                onTap: () =>
                    widget.controller.startVoiceInput(speakerName: 'You'),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isQa
                          ? const [Color(0xFF7C4DFF), Color(0xFF00E5FF)]
                          : const [
                              UnicomTheme.primaryBlue,
                              UnicomTheme.accentCyan
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isQa
                                ? const Color(0xFF7C4DFF)
                                : UnicomTheme.primaryBlue)
                            .withOpacity(0.35),
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
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
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
                      label: Text('Speak $sName',
                          style: const TextStyle(fontSize: 12)),
                      onPressed: () =>
                          widget.controller.startVoiceInput(speakerName: 'You'),
                    ),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.hearing, size: 16),
                      label: Text('Speak $tName',
                          style: const TextStyle(fontSize: 12)),
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
                        _buildPromptChip(
                            'How do transformers work in deep learning?'),
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
                    : (seg.translatedText.isNotEmpty
                        ? seg.translatedText
                        : seg.originalText),
                language: seg.isAiResponse
                    ? seg.originalLanguage
                    : seg.targetLanguage,
              ),
              onExplain: () {
                if (seg.explanation != null) {
                  _showExplanationSheet(context, seg.explanation!);
                } else {
                  _openUnderstandModal(
                    original: seg.originalText,
                    translation: seg.translatedText,
                    sourceLang: seg.originalLanguage,
                    targetLang: seg.targetLanguage,
                  );
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
        if (widget.controller.isQaMode ||
            widget.controller.activeHeroMode == 'ask') {
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
            _buildSmallActionChip(
              icon: Icons.lightbulb_outline,
              label: 'Explain',
              onTap: () {
                if (seg.explanation != null) {
                  _showExplanationSheet(context, seg.explanation!);
                } else {
                  _openUnderstandModal(
                    original: seg.originalText,
                    translation: seg.translatedText,
                    sourceLang: seg.originalLanguage,
                    targetLang: seg.targetLanguage,
                  );
                }
              },
            ),
            const SizedBox(width: 6),
            _buildSmallActionChip(
              icon: Icons.volume_up_outlined,
              label: 'Listen',
              onTap: () => widget.controller.speakText(
                seg.isAiResponse
                    ? seg.originalText
                    : (seg.translatedText.isNotEmpty
                        ? seg.translatedText
                        : seg.originalText),
                language: seg.isAiResponse
                    ? seg.originalLanguage
                    : seg.targetLanguage,
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
                    Text('More',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
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
            Text(label,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
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
                fontWeight: partial != null && partial.isNotEmpty
                    ? FontWeight.w600
                    : FontWeight.normal,
                fontStyle: partial != null && partial.isNotEmpty
                    ? FontStyle.normal
                    : FontStyle.italic,
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
    final isQa =
        widget.controller.isQaMode || widget.controller.activeHeroMode == 'ask';
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
                    borderSide:
                        const BorderSide(color: UnicomTheme.darkSurfaceVariant),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

/// Custom painter for authentic camera viewfinder frame HUD
class _ViewfinderPainter extends CustomPainter {
  final bool isProcessing;
  final bool isFrozen;

  _ViewfinderPainter({required this.isProcessing, required this.isFrozen});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF10141C);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final linePaint = Paint()
      ..color = isProcessing
          ? UnicomTheme.accentCyan.withOpacity(0.8)
          : Colors.white.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Viewfinder bracket corners
    const double bracketSize = 24.0;
    const double margin = 16.0;

    // Top-left
    canvas.drawLine(const Offset(margin, margin),
        const Offset(margin + bracketSize, margin), linePaint);
    canvas.drawLine(const Offset(margin, margin),
        const Offset(margin, margin + bracketSize), linePaint);

    // Top-right
    canvas.drawLine(Offset(size.width - margin, margin),
        Offset(size.width - margin - bracketSize, margin), linePaint);
    canvas.drawLine(Offset(size.width - margin, margin),
        Offset(size.width - margin, margin + bracketSize), linePaint);

    // Bottom-left
    canvas.drawLine(Offset(margin, size.height - margin),
        Offset(margin + bracketSize, size.height - margin), linePaint);
    canvas.drawLine(Offset(margin, size.height - margin),
        Offset(margin, size.height - margin - bracketSize), linePaint);

    // Bottom-right
    canvas.drawLine(
        Offset(size.width - margin, size.height - margin),
        Offset(size.width - margin - bracketSize, size.height - margin),
        linePaint);
    canvas.drawLine(Offset(size.width - margin, size.height - margin),
        Offset(size.width - margin, margin + bracketSize), linePaint);

    // Center targeting reticle
    final centerReticlePaint = Paint()
      ..color = isProcessing ? UnicomTheme.accentCyan : Colors.white24
      ..strokeWidth = 1.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawLine(
        Offset(cx - 12, cy), Offset(cx + 12, cy), centerReticlePaint);
    canvas.drawLine(
        Offset(cx, cy - 12), Offset(cx, cy + 12), centerReticlePaint);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter oldDelegate) {
    return oldDelegate.isProcessing != isProcessing ||
        oldDelegate.isFrozen != isFrozen;
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
                const Icon(Icons.lightbulb_outline,
                    color: UnicomTheme.accentCyan, size: 22),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                style:
                    TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy Explanation',
                    style: TextStyle(fontSize: 12)),
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
