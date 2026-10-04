import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/sizing/app_sizing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// A one-time code entered into a row of boxes, one digit each.
///
/// One invisible text field sits over the boxes and does the typing, so paste,
/// backspace and the system's one-time-code autofill all behave normally; the
/// boxes only draw its text. [onCompleted] fires once every box is filled.
class AppOtpField extends StatefulWidget {
  const AppOtpField({
    required this.controller,
    required this.onCompleted,
    super.key,
    this.length = AppConstants.otpLength,
    this.hasError = false,
    this.enabled = true,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final ValueChanged<String> onCompleted;
  final int length;

  /// Outlines every box in red.
  final bool hasError;
  final bool enabled;
  final bool autofocus;

  @override
  State<AppOtpField> createState() => _AppOtpFieldState();
}

class _AppOtpFieldState extends State<AppOtpField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _focusNode.addListener(_redraw);
  }

  @override
  void didUpdateWidget(AppOtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _redraw() => setState(() {});

  /// The code last reported, so a selection change does not report it twice.
  String? _reported;

  void _onChanged() {
    _redraw();
    final code = widget.controller.text;
    if (code.length < widget.length) {
      _reported = null;
    } else if (code != _reported) {
      _reported = code;
      widget.onCompleted(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;
    final active = _focusNode.hasFocus ? code.length : -1;

    return Semantics(
      label: 'Verification code',
      value: code,
      textField: true,
      child: Stack(
        children: [
          Row(
            children: [
              for (var i = 0; i < widget.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSizing.space8),
                Expanded(
                  child: _DigitBox(
                    digit: i < code.length ? code[i] : '',
                    isActive: i == active,
                    hasError: widget.hasError,
                  ),
                ),
              ],
            ],
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                autofocus: widget.autofocus,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: widget.length,
                showCursor: false,
                enableInteractiveSelection: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration.collapsed(hintText: ''),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DigitBox extends StatelessWidget {
  const _DigitBox({
    required this.digit,
    required this.isActive,
    required this.hasError,
  });

  final String digit;
  final bool isActive;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? AppColors.destructive
        : isActive
        ? AppColors.textPrimary
        : AppColors.border;

    return Container(
      height: AppSizing.fieldHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
        border: Border.all(
          color: borderColor,
          width: isActive || hasError
              ? AppSizing.borderWidthFocused
              : AppSizing.borderWidth,
        ),
      ),
      child: Text(digit, style: AppTextStyles.titleLarge),
    );
  }
}
