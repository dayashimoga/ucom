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
  bool _testingConnection = false;
  String? _testStatusMessage;

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
            title: const Text('AI & System Settings'),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // 1. Language & Speech
              _buildLanguageSpeechSection(context),
              const SizedBox(height: 14),

              // 2. AI Execution Tier & Privacy
              _buildAIModeCard(context),
              const SizedBox(height: 14),

              // 3. Android Built-in AI (AICore)
              _buildAndroidAICoreCard(context),
              const SizedBox(height: 14),

              // 4. Downloaded Local Models
              _buildOfflineAIDownloadsSection(context),
              const SizedBox(height: 14),

              // 5. Cloud AI & Model Configuration
              _buildCloudAICard(context),
              const SizedBox(height: 14),

              // 6. Active Intelligence Mode
              _buildApplicationModeCard(context),
              const SizedBox(height: 14),

              // 7. Data Hygiene & Retention
              _buildDataHygieneCard(context),
              const SizedBox(height: 14),

              // 8. Appearance (Theme: System / Dark / Light)
              _buildAppearanceSection(context),
              const SizedBox(height: 14),

              // 9. About UNICOM AI
              _buildAboutSection(context),
              const SizedBox(height: 14),

              // 10. Advanced: AI & Models
              _buildAdvancedSection(context),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // 1. Language & Speech
  Widget _buildLanguageSpeechSection(BuildContext context) {
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
                Text('Language & Speech',
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
          ],
        ),
      ),
    );
  }

  // 2. AI Execution Tier & Privacy
  Widget _buildAIModeCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.security, color: UnicomTheme.successGreen, size: 20),
                SizedBox(width: 8),
                Text('AI Execution Tier & Privacy',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Control where AI reasoning runs. In Offline Only mode, zero network calls leave your device.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            RadioListTile<ExecutionMode>(
              title: const Text('Offline Only (Strict Privacy Invariant)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text(
                  'Local models & Android AICore only. Zero internet transmission under any circumstance.',
                  style: TextStyle(fontSize: 12)),
              value: ExecutionMode.privateOffline,
              groupValue: widget.controller.executionMode,
              onChanged: (val) {
                if (val != null) widget.controller.setExecutionMode(val);
              },
            ),
            RadioListTile<ExecutionMode>(
              title: const Text('Automatic Mode',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text(
                  'Routes to fastest working provider according to availability.',
                  style: TextStyle(fontSize: 12)),
              value: ExecutionMode.auto,
              groupValue: widget.controller.executionMode,
              onChanged: (val) {
                if (val != null) widget.controller.setExecutionMode(val);
              },
            ),
            RadioListTile<ExecutionMode>(
              title: const Text('Hybrid Mode',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text(
                  'Local-first with user-permitted cloud fallback for complex queries.',
                  style: TextStyle(fontSize: 12)),
              value: ExecutionMode.hybrid,
              groupValue: widget.controller.executionMode,
              onChanged: (val) {
                if (val != null) widget.controller.setExecutionMode(val);
              },
            ),
            RadioListTile<ExecutionMode>(
              title: const Text('Cloud Preferred',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text(
                  'Routes to configured cloud LLM with local fallback on network failure.',
                  style: TextStyle(fontSize: 12)),
              value: ExecutionMode.cloud,
              groupValue: widget.controller.executionMode,
              onChanged: (val) {
                if (val != null) widget.controller.setExecutionMode(val);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 3. Android Built-in AI (AICore)
  Widget _buildAndroidAICoreCard(BuildContext context) {
    final status = widget.controller.aicoreStatus;
    final isAvail = status?.isAvailable ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.android, size: 20, color: UnicomTheme.accentCyan),
                const SizedBox(width: 8),
                const Text('Android Built-in AI (AICore)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isAvail ? UnicomTheme.successGreen : Colors.grey)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isAvail ? 'AVAILABLE' : 'NOT PRESENT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isAvail ? UnicomTheme.successGreen : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isAvail
                  ? 'System-level Gemini Nano is available on this Android device.'
                  : (status?.fallbackReason ??
                      'Android AICore system service is not detected on this host.'),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (!isAvail) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.download_for_offline, size: 16),
                    label: const Text('Use Downloaded Offline AI',
                        style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ModelManagerScreen(
                            modelManager: widget.controller.modelManager,
                          ),
                        ),
                      );
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.cloud_outlined, size: 16),
                    label: const Text('Use Cloud AI',
                        style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AIProvidersScreen(
                            controller: widget.controller,
                          ),
                        ),
                      );
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Learn About Device Support',
                        style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      _showAICoreInfoDialog(context);
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 4. Downloaded Local Models
  Widget _buildOfflineAIDownloadsSection(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.download_for_offline_outlined,
            color: UnicomTheme.accentCyan),
        title: const Text('Downloaded Local Models',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: const Text(
          'Manage offline Whisper STT, Q4 Transformer LLM, and offline neural translation models.',
          style: TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ModelManagerScreen(
                modelManager: widget.controller.modelManager,
              ),
            ),
          );
        },
      ),
    );
  }

  // 5. Cloud AI & Model Configuration
  Widget _buildCloudAICard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_outlined,
                    color: UnicomTheme.primaryBlueLight, size: 20),
                const SizedBox(width: 8),
                const Text('Cloud AI & Model Configuration',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AIProvidersScreen(controller: widget.controller),
                      ),
                    );
                  },
                  child: const Text('All Providers', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Configure Google Gemini API key (BYOK). Stored securely in encrypted OS credential vault.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Enter Gemini API key...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              onChanged: (val) {
                widget.controller.setCloudConfig(apiKey: val.trim());
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _testingConnection ? null : _testConnection,
                  child: _testingConnection
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Test'),
                ),
                const SizedBox(width: 10),
                if (_testStatusMessage != null)
                  Expanded(
                    child: Text(
                      _testStatusMessage!,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 6. Active Intelligence Mode
  Widget _buildApplicationModeCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.dashboard_customize_outlined,
                    color: UnicomTheme.accentCyan, size: 20),
                SizedBox(width: 8),
                Text('Active Intelligence Mode',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Select the intelligence persona and analysis workflow.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ApplicationMode>(
              value: widget.controller.mode,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                  value: ApplicationMode.general,
                  child: Text('General Communication & Q&A'),
                ),
                DropdownMenuItem(
                  value: ApplicationMode.interviewPractice,
                  child: Text('Interview Practice & Rubric Coaching'),
                ),
                DropdownMenuItem(
                  value: ApplicationMode.meeting,
                  child: Text('Meeting Intelligence & Minutes'),
                ),
              ],
              onChanged: (val) {
                if (val != null) widget.controller.setApplicationMode(val);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 7. Data Hygiene & Retention
  Widget _buildDataHygieneCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.storage, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text('Data Hygiene & Retention',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'All transcripts, audio frames, and reports are stored locally on your device.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: UnicomTheme.dangerRed),
              label: const Text('Clear All Local Data',
                  style: TextStyle(color: UnicomTheme.dangerRed)),
              onPressed: () {
                widget.controller.clearAllData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('All local data cleared successfully.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 8. Appearance
  Widget _buildAppearanceSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.palette_outlined,
                    color: UnicomTheme.accentCyan, size: 20),
                SizedBox(width: 8),
                Text('Appearance',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text('Theme', style: TextStyle(fontSize: 14)),
                ),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                      icon: Icon(Icons.brightness_auto, size: 16),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode_outlined, size: 16),
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
          ],
        ),
      ),
    );
  }

  // 9. About UNICOM AI
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
                Text('About UNICOM AI',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Version 1.0.0-production\n'
              'Universal Communication & Real-Time Intelligence Platform\n'
              'Designed for privacy-first, on-device translation, multi-persona explanations, and verified multi-provider cloud AI.',
              style: TextStyle(fontSize: 12, height: 1.5, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // 10. Advanced: AI & Models
  Widget _buildAdvancedSection(BuildContext context) {
    return const ExpansionTile(
      leading: Icon(Icons.tune, color: UnicomTheme.accentCyan),
      title: Text('Advanced: AI & Models',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text('AICore, BYOK cloud API keys, and model parameters'),
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Architecture & Quantization',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              SizedBox(height: 4),
              Text(
                'LLM: Quantized Transformer Q4_0 / INT4 (50 MB)\n'
                'STT: Mel-Spectral VAD + Acoustic INT8 (39 MB)\n'
                'TTS: Klatt Formant Resonator Cascade + Android TTS\n'
                'Translation: Neural Sequence Alignment + Offline Lexicon (45 MB)',
                style: TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    fontFamily: 'monospace',
                    color: Colors.grey),
              ),
              Divider(height: 20),

              Text('Network Gate Status',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              SizedBox(height: 4),
              Text(
                'Private Offline Mode enforces hard socket/HTTP transport layer block. Outbound network attempts throw OfflineViolationException with 0 egress bytes.',
                style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _testingConnection = true;
      _testStatusMessage = 'Testing Gemini API...';
    });

    final res = await widget.controller.testCloudConnection();

    if (mounted) {
      setState(() {
        _testingConnection = false;
        _testStatusMessage = res.isSuccessful
            ? 'Connected (${res.latencyMs} ms)'
            : 'Failed: ${res.errorMessage ?? "Error"}';
      });
    }
  }

  void _showAICoreInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Android AICore Support'),
        content: const SingleChildScrollView(
          child: Text(
            'Android AICore is Google\'s system service that powers on-device foundation models like Gemini Nano.\n\n'
            'Requirements:\n'
            '• Android 14 (API 34) or higher\n'
            '• Hardware support (e.g. Google Pixel 8+, Samsung Galaxy S24+, or compatible flagship SoC)\n'
            '• AICore system package installed and enabled via Google Play Services\n\n'
            'For devices without AICore, UniCom automatically falls back to downloaded offline models or configured cloud AI providers.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(bool isSource) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            isSource ? 'Select Source Language' : 'Select Target Language',
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
