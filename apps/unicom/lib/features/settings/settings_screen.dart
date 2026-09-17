import 'package:flutter/material.dart';
import 'package:unicom_contracts/contracts.dart';
import '../../app/theme.dart';
import '../conversation/conversation_state_notifier.dart';

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
            padding: const EdgeInsets.all(16),
            children: [
              // 1. AI Mode Card
              _buildAIModeCard(context),
              const SizedBox(height: 16),

              // 2. Android Built-in AI Status Card
              _buildAndroidAICoreCard(context),
              const SizedBox(height: 16),

              // 3. Local Models Card
              _buildLocalModelsCard(context),
              const SizedBox(height: 16),

              // 4. Cloud AI & Model Configuration Card
              _buildCloudAICard(context),
              const SizedBox(height: 16),

              // 5. Active Application Mode Card
              _buildApplicationModeCard(context),
              const SizedBox(height: 16),

              // 6. Data Hygiene & Retention Card
              _buildDataHygieneCard(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAIModeCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.security, color: UnicomTheme.successGreen),
                SizedBox(width: 8),
                Text('AI Execution Tier & Privacy',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Control where inference runs. In Private/Offline mode, zero network calls leave your device.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            RadioListTile<ExecutionMode>(
              title: const Text('Offline Only (Strict Privacy Invariant)',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text(
                  'Android AICore & local models only. No internet transmission under any circumstance.'),
              value: ExecutionMode.privateOffline,
              groupValue: widget.controller.executionMode,
              onChanged: (val) {
                if (val != null) widget.controller.setExecutionMode(val);
              },
            ),
            RadioListTile<ExecutionMode>(
              title: const Text('Automatic (Capability-Aware Routing)',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text(
                  'Prefers fastest on-device AI; routes to local or cloud according to availability.'),
              value: ExecutionMode.auto,
              groupValue: widget.controller.executionMode,
              onChanged: (val) {
                if (val != null) widget.controller.setExecutionMode(val);
              },
            ),
            RadioListTile<ExecutionMode>(
              title: const Text('Hybrid Mode',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text(
                  'Local-first with user-permitted cloud fallback for rare or high-complexity queries.'),
              value: ExecutionMode.hybrid,
              groupValue: widget.controller.executionMode,
              onChanged: (val) {
                if (val != null) widget.controller.setExecutionMode(val);
              },
            ),
            RadioListTile<ExecutionMode>(
              title: const Text('Cloud Preferred',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text(
                  'Routes to configured enterprise cloud LLM with local fallback on network failure.'),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.android, color: UnicomTheme.accentCyan),
                    SizedBox(width: 8),
                    Text('Android Built-in AI (AICore)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Check AICore Status',
                  onPressed: () => widget.controller.refreshAICoreStatus(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isAvail
                    ? UnicomTheme.successGreen.withOpacity(0.15)
                    : UnicomTheme.warningAmber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isAvail
                      ? UnicomTheme.successGreen
                      : UnicomTheme.warningAmber,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAvail ? Icons.check_circle : Icons.info_outline,
                    size: 16,
                    color: isAvail
                        ? UnicomTheme.successGreen
                        : UnicomTheme.warningAmber,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isAvail
                        ? 'Available: ${status?.modelName ?? "Gemini Nano"}'
                        : 'Status: ${status?.statusCode ?? "Not Detected"}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: isAvail
                          ? UnicomTheme.successGreen
                          : UnicomTheme.warningAmber,
                    ),
                  ),
                ],
              ),
            ),
            if (status != null && status.supportedCapabilities.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: status.supportedCapabilities
                    .map((cap) => Chip(
                          label:
                              Text(cap, style: const TextStyle(fontSize: 10)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocalModelsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.download_for_offline,
                    color: UnicomTheme.primaryBlueLight),
                SizedBox(width: 8),
                Text('Downloaded Local Models',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Pluggable on-device neural models for STT, translation, and general Q&A.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final models = widget.controller.modelManager.cachedModels;
                return Column(
                  children: models.map((m) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        m.isActive
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color:
                            m.isActive ? UnicomTheme.accentCyan : Colors.grey,
                      ),
                      title: Text(m.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text(
                          '${m.type.toUpperCase()} • ${m.quantization ?? "Standard"} • ${(m.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                          style: const TextStyle(fontSize: 11)),
                      trailing: m.isInstalled
                          ? const Chip(
                              label: Text('Installed',
                                  style: TextStyle(fontSize: 10)))
                          : OutlinedButton(
                              onPressed: () async {
                                await widget.controller.modelManager
                                    .downloadModel(m.id);
                                setState(() {});
                              },
                              child: const Text('Download',
                                  style: TextStyle(fontSize: 11)),
                            ),
                      onTap: m.isInstalled
                          ? () async {
                              await widget.controller.modelManager
                                  .activateModel(m.id);
                              setState(() {});
                            }
                          : null,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudAICard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.cloud_queue, color: UnicomTheme.accentCyan),
                SizedBox(width: 8),
                Text('Cloud AI & Model Configuration',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Configure Google Gemini or enterprise endpoint. Keys are stored in secure OS storage.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Google Gemini API Key (BYOK)',
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
              onChanged: (val) {
                widget.controller.setCloudConfig(apiKey: val.trim());
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: widget.controller.cloudModelName,
                    decoration: const InputDecoration(
                      labelText: 'Cloud Model',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'gemini-1.5-flash',
                          child: Text('Gemini 1.5 Flash (Fast)')),
                      DropdownMenuItem(
                          value: 'gemini-1.5-pro',
                          child: Text('Gemini 1.5 Pro (Deep Reasoning)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        widget.controller.setCloudConfig(modelName: val);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: _testingConnection
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.network_check, size: 18),
                  label: const Text('Test'),
                  onPressed: _testingConnection
                      ? null
                      : () async {
                          setState(() => _testingConnection = true);
                          final result =
                              await widget.controller.testCloudConnection();
                          setState(() {
                            _testingConnection = false;
                            _testStatusMessage = result.isSuccessful
                                ? 'Connected: ${result.modelName} (${result.latencyMs}ms)'
                                : 'Error: ${result.errorMessage}';
                          });
                        },
                ),
              ],
            ),
            if (_testStatusMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _testStatusMessage!,
                style: TextStyle(
                  fontSize: 12,
                  color: _testStatusMessage!.startsWith('Connected')
                      ? UnicomTheme.successGreen
                      : UnicomTheme.dangerRed,
                ),
              ),
            ],
            const SizedBox(height: 8),
            // Advanced settings progressive disclosure
            ExpansionTile(
              title: const Text('Advanced LLM Parameters',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              children: [
                ListTile(
                  title:
                      const Text('Temperature', style: TextStyle(fontSize: 13)),
                  subtitle: Slider(
                    value: widget.controller.cloudTemperature,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label:
                        widget.controller.cloudTemperature.toStringAsFixed(1),
                    onChanged: (v) =>
                        widget.controller.setCloudConfig(temperature: v),
                  ),
                  trailing: Text(
                      widget.controller.cloudTemperature.toStringAsFixed(1)),
                ),
                ListTile(
                  title: const Text('Max Output Tokens',
                      style: TextStyle(fontSize: 13)),
                  trailing: Text('${widget.controller.cloudMaxTokens}'),
                  subtitle: Slider(
                    value: widget.controller.cloudMaxTokens.toDouble(),
                    min: 256,
                    max: 4096,
                    divisions: 15,
                    onChanged: (v) =>
                        widget.controller.setCloudConfig(maxTokens: v.toInt()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationModeCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.dashboard_customize, color: UnicomTheme.accentCyan),
                SizedBox(width: 8),
                Text('Active Intelligence Mode',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ApplicationMode>(
              value: widget.controller.mode,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(
                    value: ApplicationMode.general,
                    child: Text('General Live Translation & Q&A')),
                DropdownMenuItem(
                    value: ApplicationMode.interviewPractice,
                    child: Text('Interview Practice & Rubric Coaching')),
                DropdownMenuItem(
                    value: ApplicationMode.meeting,
                    child: Text('Meeting Intelligence & Minutes')),
                DropdownMenuItem(
                    value: ApplicationMode.education,
                    child: Text('Education & Grammar Learning')),
                DropdownMenuItem(
                    value: ApplicationMode.travel,
                    child: Text('Travel Survival Mode')),
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

  Widget _buildDataHygieneCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Data Hygiene & Retention',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
                'Conversation history is retained only on your local device.',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline,
                  color: UnicomTheme.dangerRed),
              label: const Text('Clear All Local Data',
                  style: TextStyle(color: UnicomTheme.dangerRed)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Local cache and conversation records purged.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
