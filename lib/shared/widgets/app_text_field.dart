import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/sizing/app_sizing.dart';
import '../../core/theme/app_text_styles.dart';

/// Labelled text input: label above, bordered field below.
///
/// The label is passed by the calling screen, keeping wording where it is read.
/// With [showLabel] off the label moves inside the field as its hint, so the
/// field still announces what it is.
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    super.key,
    this.showLabel = true,
    this.autofillHints,
    this.hint,
    this.controller,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.autofocus = false,
    this.prefixIcon,
    this.suffixIcon,
    this.focusNode,
    this.onFieldSubmitted,
    this.errorText,
  });

  final String label;
  final bool showLabel;
  final Iterable<String>? autofillHints;
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final int maxLines;
  final int? maxLength;
  final bool autofocus;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final ValueChanged<String>? onFieldSubmitted;

  /// An error set by the caller rather than a validator, e.g. a failed lookup.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: AppSizing.space8),
        ],
        TextFormField(
          autofillHints: autofillHints,
          controller: controller,
          initialValue: initialValue,
          validator: validator,
          onChanged: onChanged,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          enabled: enabled,
          readOnly: readOnly,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          maxLength: maxLength,
          autofocus: autofocus,
          focusNode: focusNode,
          onFieldSubmitted: onFieldSubmitted,
          style: AppTextStyles.bodyLarge,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint ?? (showLabel ? null : label),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            errorText: errorText,
            counterText: '',
          ),
        ),
      ],
    );
  }
}
