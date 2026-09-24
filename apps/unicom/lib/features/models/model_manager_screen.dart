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
  List<LanguagePack> _packs = [];
  bool _loading = false;
  final Map<String, double> _downloadProgress = {};
  final Set<String> _downloadingIds = {};

  @override
  void initState() {
    super.initState();
    _models = widget.modelManager.cachedModels;
    _packs = widget.modelManager.languagePacks;
    _refreshModels();
  }

  Future<void> _refreshModels() async {
    if (_models.isEmpty) setState(() => _loading = true);
    final list = await widget.modelManager.listModels();
    if (mounted) {
      setState(() {
        _models = list;
        _packs = widget.modelManager.languagePacks;
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

  Future<void> _downloadPack(LanguagePack pack) async {
    setState(() {
      _downloadingIds.add(pack.id);
      _downloadProgress[pack.id] = 0.0;
    });

    try {
      await widget.modelManager.downloadLanguagePack(
        pack.id,
        onProgress: (pct) {
          if (mounted) {
            setState(() {
              _downloadProgress[pack.id] = pct;
            });
          }
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${pack.name} verified & ready offline.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pack download failed: ${e.toString()}'),
            backgroundColor: UnicomTheme.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingIds.remove(pack.id);
          _downloadProgress.remove(pack.id);
        });
        await _refreshModels();
      }
    }
  }

  Future<void> _removePack(LanguagePack pack) async {
    await widget.modelManager.removeLanguagePack(pack.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${pack.name} removed from device.')),
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
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // SECTION 1: Core AI Models
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.memory,
                          size: 18, color: UnicomTheme.accentCyan),
                      SizedBox(width: 8),
                      Text(
                        'Core On-Device AI Models',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                ..._models.map((m) => _buildModelCard(context, m)),
                const SizedBox(height: 20),

                // SECTION 2: Offline Language & Travel Packs
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.public,
                          size: 18, color: UnicomTheme.accentCyan),
                      SizedBox(width: 8),
                      Text(
                        'Offline Language & Travel Packs',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Complete multi-capability packages bundling OCR, Speech Recognition (STT), Neural Translation, and Audio Speech Synthesis (TTS).',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                ..._packs.map((p) => _buildLanguagePackCard(context, p)),
              ],
            ),
    );
  }

  Widget _buildModelCard(BuildContext context, ModelMetadata m) {
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: UnicomTheme.successGreen.withOpacity(0.2),
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
              style: const TextStyle(fontSize: 11, color: Colors.grey),
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
                            fontSize: 11, color: UnicomTheme.dangerRed)),
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
                    icon: const Icon(Icons.power_settings_new, size: 16),
                    label: const Text('Activate'),
                    onPressed: () async {
                      await widget.modelManager.activateModel(m.id);
                      await _refreshModels();
                    },
                  ),
                  const SizedBox(width: 8),
                  if (m.isDownloadable || m.downloadUrl != null)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline,
                          size: 16, color: UnicomTheme.dangerRed),
                      label: const Text('Remove',
                          style: TextStyle(
                              color: UnicomTheme.dangerRed, fontSize: 12)),
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
                  if (m.isDownloadable || m.downloadUrl != null)
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline,
                          size: 16, color: UnicomTheme.dangerRed),
                      label: const Text('Uninstall',
                          style: TextStyle(
                              color: UnicomTheme.dangerRed, fontSize: 12)),
                      onPressed: () => _removeModel(m),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguagePackCard(BuildContext context, LanguagePack pack) {
    final isDownloading = _downloadingIds.contains(pack.id);
    final progress = _downloadProgress[pack.id] ?? 0.0;
    final sizeMb = (pack.sizeBytes / (1024 * 1024)).toStringAsFixed(0);

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${pack.languageName} (${pack.languageCode.toUpperCase()}) • v${pack.version} • $sizeMb MB',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (pack.isInstalled)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: UnicomTheme.successGreen.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: UnicomTheme.successGreen.withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            size: 12, color: UnicomTheme.successGreen),
                        SizedBox(width: 4),
                        Text(
                          'READY OFFLINE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: UnicomTheme.successGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Capabilities Checklist
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildCapabilityBadge('OCR ✓', pack.hasOcr),
                _buildCapabilityBadge('STT ✓', pack.hasStt),
                _buildCapabilityBadge('Translation ✓', pack.hasTranslation),
                _buildCapabilityBadge('TTS ✓', pack.hasTts),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              'SHA-256 Checksum: ${pack.sha256.substring(0, 16)}... • License: ${pack.license}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),

            if (isDownloading) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Downloading & validating checksum: ${(progress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 11),
                  ),
                  TextButton(
                    onPressed: () =>
                        widget.modelManager.cancelDownload(pack.id),
                    child: const Text('Cancel',
                        style: TextStyle(
                            fontSize: 11, color: UnicomTheme.dangerRed)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),

            Row(
              children: [
                if (!pack.isInstalled && !isDownloading)
                  FilledButton.icon(
                    icon: const Icon(Icons.download, size: 16),
                    label: Text('Download $sizeMb MB'),
                    onPressed: () => _downloadPack(pack),
                  )
                else if (pack.isInstalled) ...[
                  const Icon(Icons.verified,
                      size: 16, color: UnicomTheme.accentCyan),
                  const SizedBox(width: 6),
                  const Text('Verified & Tested',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const Spacer(),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline,
                        size: 16, color: UnicomTheme.dangerRed),
                    label: const Text('Remove',
                        style: TextStyle(
                            color: UnicomTheme.dangerRed, fontSize: 12)),
                    onPressed: () => _removePack(pack),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilityBadge(String label, bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAvailable
            ? UnicomTheme.primaryBlue.withOpacity(0.12)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isAvailable
              ? UnicomTheme.primaryBlueLight.withOpacity(0.4)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isAvailable ? UnicomTheme.primaryBlueLight : Colors.grey,
        ),
      ),
    );
  }
}
