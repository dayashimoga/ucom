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
    Color modeColor;
    String modeLabel;
    IconData modeIcon;

    switch (executionMode) {
      case ExecutionMode.privateOffline:
        modeColor = UnicomTheme.successGreen;
        modeLabel = 'PRIVATE (0% LEAK)';
        modeIcon = Icons.shield_outlined;
        break;
      case ExecutionMode.hybrid:
        modeColor = UnicomTheme.warningAmber;
        modeLabel = 'HYBRID';
        modeIcon = Icons.cloud_queue;
        break;
      case ExecutionMode.cloud:
        modeColor = UnicomTheme.primaryBlueLight;
        modeLabel = 'CLOUD';
        modeIcon = Icons.cloud_done;
        break;
      case ExecutionMode.auto:
        modeColor = UnicomTheme.accentCyan;
        modeLabel = 'AUTO AI';
        modeIcon = Icons.auto_awesome;
        break;
    }

    Color stateColor;
    switch (state) {
      case ConversationState.idle:
        stateColor = Colors.grey;
        break;
      case ConversationState.listening:
        stateColor = UnicomTheme.dangerRed;
        break;
      case ConversationState.transcribing:
        stateColor = UnicomTheme.warningAmber;
        break;
      case ConversationState.translating:
        stateColor = UnicomTheme.accentCyan;
        break;
      case ConversationState.ready:
        stateColor = UnicomTheme.successGreen;
        break;
      case ConversationState.speaking:
        stateColor = UnicomTheme.primaryBlueLight;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mode badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: modeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: modeColor.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(modeIcon, size: 14, color: modeColor),
              const SizedBox(width: 4),
              Text(
                modeLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: modeColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // State badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: stateColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: stateColor.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: stateColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                state.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: stateColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
