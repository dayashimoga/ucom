import 'package:flutter/material.dart';
import 'package:unicom_contracts/contracts.dart';
import '../../app/theme.dart';
import '../conversation/conversation_state_notifier.dart';
import '../models/model_manager_screen.dart';
import 'ai_providers_screen.dart';

class SettingsScreen extends StatefulWidget {
  final ConversationController controller;

  const SettingsScreen({super.key, required this.controller});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _apiKeyController.text = widget.controller.cloudApiKey ?? '';
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // 1. Language & Voice
              _buildLanguageVoiceSection(context),
              const SizedBox(height: 14),

              // 2. AI (Execution Tier & Providers)
              _buildAISection(context),
              const SizedBox(height: 14),

              // 3. Offline Downloads
              _buildOfflineDownloadsSection(context),
              const SizedBox(height: 14),

              // 4. Privacy & History
              _buildPrivacyHistorySection(context),
              const SizedBox(height: 14),

              // 5. Appearance
              _buildAppearanceSection(context),
              const SizedBox(height: 14),

              // 6. About
              _buildAboutSection(context),
              const SizedBox(height: 14),

              // 7. Advanced (AICore, Quantization, Context, Temperature, Diagnostics)
              _buildAdvancedSection(context),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // 1. Language & Voice
  Widget _buildLanguageVoiceSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.translate, color: UnicomTheme.accentCyan, size: 20),
                SizedBox(width: 8),
                Text('Language & Voice',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Configure your primary communication languages and voice preferences.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Divider(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Primary Language'),
              subtitle: Text(
                  'Currently: ${_getLanguageName(widget.controller.sourceLanguage)} (${widget.controller.sourceLanguage.toUpperCase()})'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => _showLanguagePicker(true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Translation Target'),
              subtitle: Text(
                  'Currently: ${_getLanguageName(widget.controller.targetLanguage)} (${widget.controller.targetLanguage.toUpperCase()})'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => _showLanguagePicker(false),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Audible Speech Output (Auto-TTS)'),
              subtitle: const Text('Automatically speak translated output aloud'),
              value: widget.controller.autoTts,
              onChanged: (val) => widget.controller.setAutoTts(val),
            ),
          ],
        ),
      ),
    );
  }

  // 2. AI Section (Execution Tier & Providers)
  Widget _buildAISection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: UnicomTheme.accentCyan, size: 20),
                const SizedBox(width: 8),
                const Text('AI',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: UnicomTheme.primaryBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.controller.activeProviderName,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: UnicomTheme.accentCyan),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Select execution tier and configure AI providers.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Divider(height: 20),
            RadioListTile<ExecutionMode>(
              contentPadding: EdgeInsets.zero,
              title: const Text('Private Offline'),
              subtitle: const Text('100% on-device inference. Zero data egress guaranteed.'),
              value: ExecutionMode.privateOffline,
              groupValue: widget.controller.executionMode,
              onChanged: (val) {
                if (val != null) widget.controller.setExecutionMode(val);
              },
            ),
            RadioListTile<ExecutionMode>(
              contentPadding: EdgeInsets.zero,
              title: const Text('Automatic (Best Available)'),
              subtitle: const Text('Uses verified on-device models with cloud fallback when configured.'),
              value: ExecutionMode.auto,
              groupValue: widget.controller.executionMode,
              onChanged: (val) {
                if (val != null) widget.controller.setExecutionMode(val);
              },
            ),
            RadioListTile<ExecutionMode>(
              contentPadding: EdgeInsets.zero,
              title: const Text('Cloud Enhanced'),
              subtitle: const Text('Prioritizes high-accuracy cloud models (Google Gemini / BYOK).'),
              value: ExecutionMode.cloud,
              groupValue: widget.controller.executionMode,
              onChanged: (val) {
                if (val != null) widget.controller.setExecutionMode(val);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.tune, color: UnicomTheme.accentCyan),
              title: const Text('Manage AI Providers & Routing'),
              subtitle: const Text('Google Gemini, OpenAI, Claude, Custom Endpoints'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => AIProvidersScreen(controller: widget.controller),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 3. Offline Downloads
  Widget _buildOfflineDownloadsSection(BuildContext context) {
    final localLoaded = widget.controller.localLLM.isModelLoaded;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.download_for_offline_outlined, color: UnicomTheme.accentCyan, size: 20),
                const SizedBox(width: 8),
                const Text('Offline Downloads',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (localLoaded ? UnicomTheme.successGreen : UnicomTheme.warningAmber)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    localLoaded ? 'READY OFFLINE' : 'SETUP REQUIRED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: localLoaded ? UnicomTheme.successGreen : UnicomTheme.warningAmber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Download verified on-device neural models for offline speech, translation, and general AI.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Divider(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.folder_zip_outlined, color: UnicomTheme.accentCyan),
              title: const Text('Model & Language Pack Manager'),
              subtitle: const Text('Install or update compact offline models (Speech, NMT, LLM)'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => ModelManagerScreen(modelManager: widget.controller.modelManager),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 4. Privacy & History
  Widget _buildPrivacyHistorySection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shield_outlined, color: UnicomTheme.successGreen, size: 20),
                SizedBox(width: 8),
                Text('Privacy & History',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Local storage management and zero-telemetry guarantee.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Divider(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Clear All Conversation History'),
              subtitle: const Text('Wipes local transcripts, summaries, and meeting minutes'),
              trailing: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: UnicomTheme.dangerRed,
                  side: const BorderSide(color: UnicomTheme.dangerRed),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _confirmClearHistory(context),
                child: const Text('Clear All'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Conversation Data?'),
        content: const Text('This will permanently delete all conversation transcripts, reports, and extracted insights from device storage.'),
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
              await widget.controller.clearAllData();
              messenger.showSnackBar(
                const SnackBar(content: Text('All local conversation data cleared.')),
              );
            },
          ),
        ],
      ),
    );
  }

  // 5. Appearance
  Widget _buildAppearanceSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.palette_outlined, color: UnicomTheme.accentCyan, size: 20),
                SizedBox(width: 8),
                Text('Appearance',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Select visual theme for day and night environments.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Divider(height: 20),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.settings_suggest, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode, size: 16),
                ),
              ],
              selected: {widget.controller.themeMode},
              onSelectionChanged: (set) {
                if (set.isNotEmpty) {
                  widget.controller.setThemeMode(set.first);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // 6. About
  Widget _buildAboutSection(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey, size: 20),
                SizedBox(width: 8),
                Text('About',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'UNICOM AI — Version 1.0.0 (Production Release)\n'
              'Universal Communication & Real-Time Intelligence Platform.\n'
              'Zero-telemetry policy: all private offline operations run entirely on-device.',
              style: TextStyle(fontSize: 12, height: 1.5, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // 7. Advanced (AICore, Quantization, Context, Temperature, Diagnostics)
  Widget _buildAdvancedSection(BuildContext context) {
    final aicore = widget.controller.aicoreStatus;
    final isAvail = aicore?.isAvailable ?? false;

    return ExpansionTile(
      leading: const Icon(Icons.tune, color: UnicomTheme.accentCyan),
      title: const Text('Advanced',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: const Text('AICore, quantization, context size, temperature, diagnostics'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AICore Hardware Status
              Row(
                children: [
                  const Icon(Icons.android, size: 18, color: UnicomTheme.accentCyan),
                  const SizedBox(width: 8),
                  const Text('Android AICore (Gemini Nano)',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isAvail ? UnicomTheme.successGreen : Colors.grey).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isAvail ? 'AVAILABLE' : 'DEVICE-BLOCKED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isAvail ? UnicomTheme.successGreen : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                isAvail
                    ? 'Hardware AICore bound and ready.'
                    : (aicore?.fallbackReason ??
                        'Hardware AICore requires supported physical device (e.g. Pixel 8/9 / Galaxy S24) with Google AICore service bound.'),
                style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
              ),
              const Divider(height: 20),

              // Quantization and Architecture
              const Text('Architecture & Quantization Specs',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              const Text(
                '• LLM: Quantized Transformer Q4_0 / INT4 (50 MB weights)\n'
                '• STT: Android SpeechRecognizer continuous engine + Whisper INT8\n'
                '• TTS: Android Native TextToSpeech + Klatt Resonator fallback\n'
                '• Translation: Neural Sequence Alignment + Offline Lexicon (45 MB)',
                style: TextStyle(fontSize: 11, height: 1.5, fontFamily: 'monospace', color: Colors.grey),
              ),
              const Divider(height: 20),

              // Context size & Temperature sliders
              Text('Cloud Max Tokens: ${widget.controller.cloudMaxTokens}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              Slider(
                value: widget.controller.cloudMaxTokens.toDouble(),
                min: 256,
                max: 4096,
                divisions: 15,
                label: '${widget.controller.cloudMaxTokens}',
                onChanged: (val) {
                  widget.controller.setCloudConfig(maxTokens: val.toInt());
                },
              ),

              Text('Generation Temperature: ${widget.controller.cloudTemperature.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              Slider(
                value: widget.controller.cloudTemperature,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                label: widget.controller.cloudTemperature.toStringAsFixed(2),
                onChanged: (val) {
                  widget.controller.setCloudConfig(temperature: val);
                },
              ),
              const Divider(height: 20),

              // Network Gate Status
              const Text('Zero-Network Gate Status',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 4),
              const Text(
                'Private Offline mode enforces transport layer isolation. Zero outbound content egress.',
                style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLanguagePicker(bool isSource) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            isSource ? 'Select Primary Language' : 'Select Target Language',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ..._langs.map((l) => ListTile(
                title: Text(l['name']!),
                trailing: Text(l['code']!.toUpperCase(),
                    style: const TextStyle(color: Colors.grey)),
                onTap: () {
                  Navigator.pop(ctx);
                  if (isSource) {
                    widget.controller.setLanguages(
                        l['code']!, widget.controller.targetLanguage);
                  } else {
                    widget.controller.setLanguages(
                        widget.controller.sourceLanguage, l['code']!);
                  }
                },
              )),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    final found = _langs.firstWhere(
      (l) => l['code']?.toLowerCase() == code.toLowerCase(),
      orElse: () => {'name': code.toUpperCase()},
    );
    return found['name'] ?? code.toUpperCase();
  }

  static const List<Map<String, String>> _langs = [
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
}
