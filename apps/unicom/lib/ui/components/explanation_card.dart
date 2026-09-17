import 'package:flutter/material.dart';
import 'package:unicom_contracts/contracts.dart';
import '../../app/theme.dart';

class ExplanationCard extends StatefulWidget {
  final ExplanationResult explanation;

  const ExplanationCard({Key? key, required this.explanation}) : super(key: key);

  @override
  State<ExplanationCard> createState() => _ExplanationCardState();
}

class _ExplanationCardState extends State<ExplanationCard> {
  ExplanationPersona _selectedPersona = ExplanationPersona.simple;

  @override
  Widget build(BuildContext context) {
    final expEntry = widget.explanation.explanations[_selectedPersona];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: UnicomTheme.accentCyan, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Multi-Persona Intelligence',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  widget.explanation.createdAt.substring(11, 16),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Persona chips selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ExplanationPersona.values.map((persona) {
                  final isSelected = persona == _selectedPersona;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(
                        _personaLabel(persona),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedPersona = persona);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            // Content
            if (expEntry != null) ...[
              Text(
                expEntry.content,
                style: const TextStyle(fontSize: 14, height: 1.45),
              ),
              if (expEntry.keyPoints.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: expEntry.keyPoints.map((point) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: UnicomTheme.primaryBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        point,
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
              const Text('Explanation unavailable for this persona.', style: TextStyle(fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }

  String _personaLabel(ExplanationPersona persona) {
    switch (persona) {
      case ExplanationPersona.simple: return 'Simple';
      case ExplanationPersona.detailed: return 'Detailed';
      case ExplanationPersona.terminology: return 'Terms';
      case ExplanationPersona.grammar: return 'Grammar';
      case ExplanationPersona.culturalContext: return 'Culture';
      case ExplanationPersona.examples: return 'Examples';
      case ExplanationPersona.childFriendly: return 'Child-Friendly';
    }
  }
}
