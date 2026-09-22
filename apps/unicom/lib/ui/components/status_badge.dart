import 'package:flutter/material.dart';
import 'package:unicom_contracts/contracts.dart';
import '../../app/theme.dart';

class StatusBadge extends StatelessWidget {
  final ExecutionMode executionMode;
  final ConversationState state;

  const StatusBadge({
    super.key,
    required this.executionMode,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    // Determine primary state representation
    Color stateColor;
    String stateLabel;
    IconData stateIcon;

    switch (state) {
      case ConversationState.idle:
        if (executionMode == ExecutionMode.privateOffline) {
          stateColor = UnicomTheme.successGreen;
          stateLabel = 'Offline';
          stateIcon = Icons.cloud_off;
        } else {
          stateColor = Colors.grey;
          stateLabel = 'Ready';
          stateIcon = Icons.check_circle_outline;
        }
        break;
      case ConversationState.listening:
        stateColor = UnicomTheme.dangerRed;
        stateLabel = 'Listening';
        stateIcon = Icons.mic;
        break;
      case ConversationState.transcribing:
        stateColor = UnicomTheme.warningAmber;
        stateLabel = 'Transcribing';
        stateIcon = Icons.graphic_eq;
        break;
      case ConversationState.translating:
        stateColor = UnicomTheme.accentCyan;
        stateLabel = 'Translating';
        stateIcon = Icons.translate;
        break;
      case ConversationState.processing:
        stateColor = const Color(0xFFB388FF);
        stateLabel = 'Processing';
        stateIcon = Icons.auto_awesome;
        break;
      case ConversationState.ready:
        stateColor = UnicomTheme.successGreen;
        stateLabel = 'Ready';
        stateIcon = Icons.check_circle;
        break;
      case ConversationState.speaking:
        stateColor = UnicomTheme.primaryBlueLight;
        stateLabel = 'Speaking';
        stateIcon = Icons.volume_up;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: stateColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: stateColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(stateIcon, size: 14, color: stateColor),
          const SizedBox(width: 6),
          Text(
            stateLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: stateColor,
            ),
          ),
          if (executionMode == ExecutionMode.privateOffline &&
              state != ConversationState.idle) ...[
            const SizedBox(width: 6),
            Icon(Icons.shield,
                size: 11, color: UnicomTheme.successGreen.withOpacity(0.8)),
          ],
        ],
      ),
    );
  }
}
