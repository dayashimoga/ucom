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
  bool _loading = false;
  final Map<String, double> _downloadProgress = {};
  final Set<String> _downloadingIds = {};

  @override
  void initState() {
    super.initState();
    _models = widget.modelManager.cachedModels;
    _refreshModels();
  }

  Future<void> _refreshModels() async {
    if (_models.isEmpty) setState(() => _loading = true);
    final list = await widget.modelManager.listModels();
    if (mounted) {
      setState(() {
        _models = list;
        _loading = false;
      });
    }
  }

  Future<void> _downloadModel(ModelMetadata m) async {
    setState(() {
      _downloadingIds.add(m.id);
      _downloadProgress[m.id] = 0.0;
    });

    try {
      await widget.modelManager.downloadModel(
        m.id,
        onProgress: (pct) {
          if (mounted) {
            setState(() {
              _downloadProgress[m.id] = pct;
            });
          }
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${m.name} installed successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: UnicomTheme.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingIds.remove(m.id);
          _downloadProgress.remove(m.id);
        });
        await _refreshModels();
      }
    }
  }

  Future<void> _removeModel(ModelMetadata m) async {
    await widget.modelManager.removeModel(m.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${m.name} uninstalled.')),
      );
      await _refreshModels();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Model & Language Pack Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshModels,
          ),
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
                final isDownloading = _downloadingIds.contains(m.id);
                final progress = _downloadProgress[m.id] ?? 0.0;
                final sizeMb = (m.sizeBytes / (1024 * 1024)).toStringAsFixed(1);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                m.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (m.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      UnicomTheme.successGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: UnicomTheme.successGreen,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Type: ${m.type.toUpperCase()} - Version: ${m.version} - Size: $sizeMb MB - License: ${m.license}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Format: ${m.quantization ?? "Standard"} - Runtime: ${m.runtime ?? "Native"} - Min RAM: ${m.minRamMb ?? 64} MB',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                        if (m.family != null || m.parameters != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Family: ${m.family ?? "N/A"} • Params: ${m.parameters ?? "N/A"} • Tokenizer: ${m.tokenizer ?? "N/A"} • Format: ${m.format ?? "N/A"}${m.tokensPerSec != null ? " • ${m.tokensPerSec!.toStringAsFixed(0)} tok/s" : ""}',
                            style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                          ),
                        ],
                        if (isDownloading) ...[
                          const SizedBox(height: 12),
                          LinearProgressIndicator(value: progress),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(progress * 100).toInt()}% downloaded',
                                style: const TextStyle(fontSize: 11),
                              ),
                              TextButton(
                                onPressed: () {
                                  widget.modelManager.cancelDownload(m.id);
                                },
                                child: const Text('Cancel',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: UnicomTheme.dangerRed)),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (!m.isInstalled && !isDownloading)
                              FilledButton(
                                onPressed: () => _downloadModel(m),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.download, size: 16),
                                    SizedBox(width: 8),
                                    Text('Download Pack'),
                                  ],
                                ),
                              )
                            else if (m.isInstalled && !m.isActive) ...[
                              FilledButton.tonalIcon(
                                icon: const Icon(Icons.power_settings_new,
                                    size: 16),
                                label: const Text('Activate'),
                                onPressed: () async {
                                  await widget.modelManager.activateModel(m.id);
                                  await _refreshModels();
                                },
                              ),
                              const SizedBox(width: 8),
                              if (m.isDownloadable)
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 16, color: UnicomTheme.dangerRed),
                                  label: const Text('Remove',
                                      style: TextStyle(
                                          color: UnicomTheme.dangerRed,
                                          fontSize: 12)),
                                  onPressed: () => _removeModel(m),
                                ),
                            ] else if (m.isInstalled && m.isActive) ...[
                              const Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 16, color: UnicomTheme.successGreen),
                                  SizedBox(width: 4),
                                  Text(
                                    'Active Engine',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: UnicomTheme.successGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              if (m.isDownloadable)
                                TextButton.icon(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 16, color: UnicomTheme.dangerRed),
                                  label: const Text('Uninstall',
                                      style: TextStyle(
                                          color: UnicomTheme.dangerRed,
                                          fontSize: 12)),
                                  onPressed: () => _removeModel(m),
                                ),
                            ],
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
