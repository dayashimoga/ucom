import 'package:flutter/material.dart';
import 'package:unicom_contracts/contracts.dart';
import '../../app/theme.dart';
import '../conversation/conversation_state_notifier.dart';

class AIProvidersScreen extends StatefulWidget {
  final ConversationController controller;

  const AIProvidersScreen({super.key, required this.controller});

  @override
  State<AIProvidersScreen> createState() => _AIProvidersScreenState();
}

class _AIProvidersScreenState extends State<AIProvidersScreen> {
  final Map<String, String> _testStatuses = {};
  final Map<String, bool> _testing = {};

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final providers = widget.controller.configuredProviders;

        return Scaffold(
          appBar: AppBar(
            title: const Text('AI Providers',
                style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add Provider',
                onPressed: _showAddProviderDialog,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: UnicomTheme.primaryBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: UnicomTheme.primaryBlue.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        color: UnicomTheme.accentCyan, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'BYOK (Bring Your Own Key): Secrets are stored exclusively in device encrypted storage. In Private Offline mode, zero network egress occurs.',
                        style: TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Capability Routing Section
              _buildCapabilityRoutingCard(context),
              const SizedBox(height: 20),

              // Configured Providers List
              Row(
                children: [
                  const Text('Configured Providers',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Provider',
                        style: TextStyle(fontSize: 12)),
                    onPressed: _showAddProviderDialog,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Default Built-in providers if none configured
              if (providers.isEmpty) ...[
                _buildDefaultGeminiCard(context),
                const SizedBox(height: 10),
                _buildDefaultAICoreCard(context),
                const SizedBox(height: 10),
                _buildDefaultLocalCard(context),
              ] else
                ...providers.map((p) => _buildProviderCard(context, p)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCapabilityRoutingCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.alt_route, color: UnicomTheme.accentCyan, size: 20),
                SizedBox(width: 8),
                Text('Capability Routing',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Route specific intelligence tasks to specialized models or devices. Tap to reconfigure.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Divider(height: 20),
            _buildRouteTile(
              'General Q&A',
              widget.controller.qaRoute,
              Icons.chat_bubble_outline,
              () => _showRouteSelectionSheet(
                'General Q&A',
                'qa',
                [
                  'Active LLM Provider / Local Fallback',
                  'Google Gemini (Cloud)',
                  'OpenAI / Claude (Cloud)',
                  'On-Device Quantized LLM',
                  'Android Gemini Nano (AICore)',
                ],
              ),
            ),
            _buildRouteTile(
              'Translation',
              widget.controller.translationRoute,
              Icons.translate,
              () => _showRouteSelectionSheet(
                'Translation',
                'translation',
                [
                  'Active Neural Provider / Offline Lexicon',
                  'IndicTrans2 On-Device (Tamil & Hindi)',
                  'Compact Offline Lexicon',
                  'Cloud Translation Adapter',
                ],
              ),
            ),
            _buildRouteTile(
              'Speech-to-Text (STT)',
              widget.controller.sttRoute,
              Icons.mic,
              () => _showRouteSelectionSheet(
                'Speech-to-Text (STT)',
                'stt',
                [
                  'Android SpeechRecognizer / Device Audio',
                  'Whisper Tiny INT8 On-Device',
                  'Local Acoustic + Energy VAD',
                ],
              ),
            ),
            _buildRouteTile(
              'Text-to-Speech (TTS)',
              widget.controller.ttsRoute,
              Icons.volume_up,
              () => _showRouteSelectionSheet(
                'Text-to-Speech (TTS)',
                'tts',
                [
                  'Android Native TextToSpeech Engine',
                  'Piper Fast Neural TTS',
                  'Offline Klatt Formant Resonator',
                ],
              ),
            ),
            _buildRouteTile(
              'Summarization',
              widget.controller.summarizationRoute,
              Icons.summarize,
              () => _showRouteSelectionSheet(
                'Summarization',
                'summarization',
                [
                  'Active LLM Provider / Local Extractor',
                  'Android Gemini Nano (AICore)',
                  'Local Quantized Model',
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteTile(
      String title, String currentRoute, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(currentRoute,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showRouteSelectionSheet(
      String title, String capabilityKey, List<String> options) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Route for $title',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...options.map((opt) => ListTile(
                  title: Text(opt, style: const TextStyle(fontSize: 13)),
                  trailing: const Icon(Icons.check, size: 16),
                  onTap: () {
                    widget.controller.setCapabilityRoute(capabilityKey, opt);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultGeminiCard(BuildContext context) {
    final hasKey = widget.controller.cloudApiKey != null &&
        widget.controller.cloudApiKey!.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome,
                    color: UnicomTheme.accentCyan, size: 20),
                const SizedBox(width: 8),
                const Text('Google Gemini (Default)',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (hasKey ? UnicomTheme.successGreen : Colors.grey)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    hasKey ? 'CONFIGURED' : 'NEEDS KEY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: hasKey ? UnicomTheme.successGreen : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Model: ${widget.controller.cloudModelName} • Endpoint: generativelanguage.googleapis.com',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact),
                  onPressed: () => _testDefaultGemini(),
                  child: _testing['gemini_default'] == true
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Test Connection',
                          style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 10),
                if (_testStatuses['gemini_default'] != null)
                  Expanded(
                    child: Text(
                      _testStatuses['gemini_default']!,
                      style: const TextStyle(fontSize: 11),
                      maxLines: 1,
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

  Widget _buildDefaultAICoreCard(BuildContext context) {
    final status = widget.controller.aicoreStatus;
    final isAvail = status?.isAvailable ?? false;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.android, color: UnicomTheme.accentCyan),
        title: const Text('Android System AICore',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
          isAvail
              ? 'Gemini Nano system service ready'
              : (status?.fallbackReason ?? 'Not present on device'),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: (isAvail ? UnicomTheme.successGreen : Colors.grey)
                .withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isAvail ? 'AVAILABLE' : 'UNAVAILABLE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isAvail ? UnicomTheme.successGreen : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultLocalCard(BuildContext context) {
    final isLoaded = widget.controller.localLLM.isModelLoaded;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.memory, color: UnicomTheme.primaryBlueLight),
        title: const Text('Downloaded Local Model',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
          isLoaded
              ? 'On-device quantized model active'
              : 'No local model installed',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: (isLoaded ? UnicomTheme.successGreen : Colors.grey)
                .withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isLoaded ? 'ACTIVE' : 'NOT LOADED',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isLoaded ? UnicomTheme.successGreen : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderCard(BuildContext context, AIProviderConfig config) {
    final isTesting = _testing[config.id] == true;
    final statusText = _testStatuses[config.id];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getIconForType(config.type),
                    color: UnicomTheme.accentCyan, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(config.displayName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        '${config.type.name.toUpperCase()} • ${config.modelId}',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (config.isDefault)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: UnicomTheme.primaryBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'DEFAULT',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: UnicomTheme.primaryBlueLight),
                    ),
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (val) {
                    if (val == 'default') {
                      widget.controller.setDefaultProvider(config.id);
                    } else if (val == 'delete') {
                      widget.controller.removeProviderConfig(config.id);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                        value: 'default', child: Text('Set as Default')),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Provider',
                            style: TextStyle(color: UnicomTheme.dangerRed))),
                  ],
                ),
              ],
            ),
            if (config.baseUrl.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(config.baseUrl,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact),
                  onPressed: isTesting ? null : () => _testProvider(config),
                  child: isTesting
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Test Connection',
                          style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 10),
                if (statusText != null)
                  Expanded(
                    child: Text(
                      statusText,
                      style: const TextStyle(fontSize: 11),
                      maxLines: 1,
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

  IconData _getIconForType(AIProviderType type) {
    switch (type) {
      case AIProviderType.gemini:
        return Icons.auto_awesome;
      case AIProviderType.openai:
        return Icons.psychology;
      case AIProviderType.anthropic:
        return Icons.smart_toy;
      case AIProviderType.custom:
        return Icons.dns;
      case AIProviderType.local:
        return Icons.memory;
      case AIProviderType.aicore:
        return Icons.android;
    }
  }

  Future<void> _testDefaultGemini() async {
    setState(() => _testing['gemini_default'] = true);
    final res = await widget.controller.testCloudConnection();
    setState(() {
      _testing['gemini_default'] = false;
      _testStatuses['gemini_default'] = res.isSuccessful
          ? 'Success (${res.latencyMs} ms)'
          : (res.errorMessage ?? 'Failed');
    });
  }

  Future<void> _testProvider(AIProviderConfig config) async {
    setState(() => _testing[config.id] = true);
    final res = await widget.controller.testProviderConfig(config);
    setState(() {
      _testing[config.id] = false;
      _testStatuses[config.id] = res.isSuccessful
          ? 'Success (${res.latencyMs} ms)'
          : (res.errorMessage ?? 'Failed');
    });
  }

  void _showAddProviderDialog() {
    AIProviderType selectedType = AIProviderType.gemini;
    final nameController = TextEditingController(text: 'My Provider');
    final baseUrlController = TextEditingController();
    final apiKeyController = TextEditingController();
    final modelController = TextEditingController(text: 'gemini-1.5-flash');
    bool obscureKey = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add AI Provider',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<AIProviderType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Provider Type'),
                  items: const [
                    DropdownMenuItem(
                        value: AIProviderType.gemini,
                        child: Text('Google Gemini')),
                    DropdownMenuItem(
                        value: AIProviderType.openai, child: Text('OpenAI')),
                    DropdownMenuItem(
                        value: AIProviderType.anthropic,
                        child: Text('Anthropic Claude')),
                    DropdownMenuItem(
                        value: AIProviderType.custom,
                        child: Text('Custom OpenAI-Compatible')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        selectedType = val;
                        if (val == AIProviderType.gemini) {
                          nameController.text = 'Google Gemini';
                          modelController.text = 'gemini-1.5-flash';
                          baseUrlController.text = '';
                        } else if (val == AIProviderType.openai) {
                          nameController.text = 'OpenAI';
                          modelController.text = 'gpt-4o-mini';
                          baseUrlController.text = 'https://api.openai.com';
                        } else if (val == AIProviderType.anthropic) {
                          nameController.text = 'Anthropic';
                          modelController.text = 'claude-3-5-sonnet-20241022';
                          baseUrlController.text = 'https://api.anthropic.com';
                        } else if (val == AIProviderType.custom) {
                          nameController.text = 'Custom LLM';
                          modelController.text = 'default';
                          baseUrlController.text = 'http://localhost:11434';
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Display Name'),
                ),
                if (selectedType == AIProviderType.openai ||
                    selectedType == AIProviderType.custom) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: baseUrlController,
                    decoration: const InputDecoration(
                        labelText: 'Base URL',
                        hintText: 'https://api.openai.com'),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: modelController,
                  decoration: const InputDecoration(labelText: 'Model ID'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: apiKeyController,
                  obscureText: obscureKey,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    suffixIcon: IconButton(
                      icon: Icon(
                          obscureKey ? Icons.visibility : Icons.visibility_off,
                          size: 18),
                      onPressed: () =>
                          setDialogState(() => obscureKey = !obscureKey),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(ctx),
            ),
            FilledButton(
              child: const Text('Save Provider'),
              onPressed: () {
                final id = 'prov_${DateTime.now().millisecondsSinceEpoch}';
                final config = AIProviderConfig(
                  id: id,
                  type: selectedType,
                  displayName: nameController.text.trim().isNotEmpty
                      ? nameController.text.trim()
                      : 'AI Provider',
                  baseUrl: baseUrlController.text.trim(),
                  apiKey: apiKeyController.text.trim(),
                  modelId: modelController.text.trim().isNotEmpty
                      ? modelController.text.trim()
                      : 'default',
                  isDefault: widget.controller.configuredProviders.isEmpty,
                );
                widget.controller.addProviderConfig(config);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
