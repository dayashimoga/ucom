import 'package:flutter/material.dart';
import 'package:unicom_contracts/contracts.dart';
import 'package:unicom_model_runtime/model_runtime.dart';
import '../../app/theme.dart';

class ModelManagerScreen extends StatefulWidget {
  final LocalModelManager modelManager;

  const ModelManagerScreen({super.key, required this.modelManager});

  @override
  State<ModelManagerScreen> createState() => _ModelManagerScreenState();
}

class _ModelManagerScreenState extends State<ModelManagerScreen> {
  List<ModelMetadata> _models = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refreshModels();
  }

  Future<void> _refreshModels() async {
    final list = await widget.modelManager.listModels();
    setState(() {
      _models = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Model & Language Pack Manager'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshModels),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _models.length,
              itemBuilder: (context, index) {
                final m = _models[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const Spacer(),
                            if (m.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: UnicomTheme.successGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: UnicomTheme.successGreen)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Type: ${m.type.toUpperCase()} • Version: ${m.version} • Size: ${(m.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB • License: ${m.license}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Text('SHA256: ${m.sha256.substring(0, 16)}...', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.grey)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          children: m.capabilities.map((c) => Chip(
                                label: Text(c, style: const TextStyle(fontSize: 10)),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              )).toList(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (!m.isInstalled)
                              FilledButton.icon(
                                icon: const Icon(Icons.download, size: 16),
                                label: const Text('Download Pack'),
                                onPressed: () async {
                                  await widget.modelManager.downloadModel(m.id);
                                  await _refreshModels();
                                },
                              )
                            else if (!m.isActive)
                              FilledButton.tonalIcon(
                                icon: const Icon(Icons.power_settings_new, size: 16),
                                label: const Text('Activate'),
                                onPressed: () async {
                                  await widget.modelManager.activateModel(m.id);
                                  await _refreshModels();
                                },
                              )
                            else
                              const Text('Default Active Engine', style: TextStyle(fontSize: 12, color: UnicomTheme.successGreen, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
