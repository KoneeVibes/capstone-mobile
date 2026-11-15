import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../shared/widgets/app_button.dart';

/// The pair that gates the conversation: open it to start, close it to end.
/// Shown to the staff member holding the case only.
class ChatConversationControls extends StatelessWidget {
  const ChatConversationControls({
    required this.canOpen,
    required this.canClose,
    required this.busy,
    required this.onOpen,
    required this.onClose,
    super.key,
  });

  final bool canOpen;
  final bool canClose;

  /// A toggle is in flight: the live button spins and neither can be tapped.
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Open chat',
            variant: AppButtonVariant.secondary,
            isLoading: busy && canOpen,
            onPressed: canOpen && !busy ? onOpen : null,
          ),
        ),
        const SizedBox(width: AppSizing.space12),
        Expanded(
          child: AppButton(
            label: 'Close chat',
            isLoading: busy && canClose,
            onPressed: canClose && !busy ? onClose : null,
          ),
        ),
      ],
    );
  }
}
