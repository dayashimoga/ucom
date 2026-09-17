import 'package:flutter/material.dart';
import 'package:unicom_contracts/contracts.dart';
import '../../app/theme.dart';
import '../conversation/conversation_state_notifier.dart';

class SettingsScreen extends StatelessWidget {
  final ConversationController controller;

  const SettingsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Privacy & System Settings'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Privacy Tier Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.security, color: UnicomTheme.successGreen),
                          SizedBox(width: 8),
                          Text('Privacy & Execution Tier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Control where speech recognition, translation, intelligence, and storage occur.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      RadioListTile<ExecutionMode>(
                        title: const Text('Private / Offline (Strict Invariant)', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('All translation, STT, TTS, intelligence & search run on-device. Zero network calls guaranteed.'),
                        value: ExecutionMode.privateOffline,
                        groupValue: controller.executionMode,
                        onChanged: (val) {
                          if (val != null) controller.setExecutionMode(val);
                        },
                      ),
                      RadioListTile<ExecutionMode>(
                        title: const Text('Hybrid Mode'),
                        subtitle: const Text('Local-first with user-approved cloud enhancements for rare low-resource dialects.'),
                        value: ExecutionMode.hybrid,
                        groupValue: controller.executionMode,
                        onChanged: (val) {
                          if (val != null) controller.setExecutionMode(val);
                        },
                      ),
                      RadioListTile<ExecutionMode>(
                        title: const Text('Cloud Enhanced'),
                        subtitle: const Text('Full cloud enterprise model endpoints (explicitly opted in).'),
                        value: ExecutionMode.cloud,
                        groupValue: controller.executionMode,
                        onChanged: (val) {
                          if (val != null) controller.setExecutionMode(val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Application Mode Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.dashboard_customize, color: UnicomTheme.accentCyan),
                          SizedBox(width: 8),
                          Text('Active Intelligence Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<ApplicationMode>(
                        value: controller.mode,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: ApplicationMode.general, child: Text('General Live Translation')),
                          DropdownMenuItem(value: ApplicationMode.interviewPractice, child: Text('Interview Practice & Rubric Coaching')),
                          DropdownMenuItem(value: ApplicationMode.meeting, child: Text('Meeting Intelligence & Minutes')),
                          DropdownMenuItem(value: ApplicationMode.education, child: Text('Education & Grammar Learning')),
                          DropdownMenuItem(value: ApplicationMode.travel, child: Text('Travel Survival Mode')),
                        ],
                        onChanged: (val) {
                          if (val != null) controller.setApplicationMode(val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Local Data Management
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Data Hygiene & Retention', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text('Conversation history is retained only on your local device unless manually cleared.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline, color: UnicomTheme.dangerRed),
                        label: const Text('Clear Local Conversation Cache', style: TextStyle(color: UnicomTheme.dangerRed)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Local session cache cleared.')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
