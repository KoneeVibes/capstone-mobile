import 'package:flutter/material.dart';

import '../../core/sizing/app_sizing.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_bottom_sheet.dart';
import 'app_button.dart';

/// Where every "Pay now" lands until Paystack is wired in. Shared because both
/// the new-search flow and the cases list offer it, and features do not import
/// each other; the copy lives here for the same reason.
Future<void> showPaymentComingSoonSheet(BuildContext context) {
  return showAppBottomSheet<void>(
    context: context,
    title: 'Payment coming soon',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Paying in the app isn't available yet. Your request is saved under "
          'Cases, and it will move forward once it is paid.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSizing.space24),
        Builder(
          builder: (context) => AppButton(
            label: 'Got it',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    ),
  );
}
