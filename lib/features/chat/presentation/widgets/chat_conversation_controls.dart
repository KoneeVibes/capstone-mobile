import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../shared/widgets/app_button.dart';

/// The pair that gates the conversation: open it to start, close it to end.
class ChatConversationControls extends StatelessWidget {
  const ChatConversationControls({
    required this.canOpen,
    required this.canClose,
    required this.onOpen,
    required this.onClose,
    super.key,
  });

  final bool canOpen;
  final bool canClose;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Open conversation',
            variant: AppButtonVariant.secondary,
            onPressed: canOpen ? onOpen : null,
          ),
        ),
        const SizedBox(width: AppSizing.space12),
        Expanded(
          child: AppButton(
            label: 'Close conversation.',
            onPressed: canClose ? onClose : null,
          ),
        ),
      ],
    );
  }
}
