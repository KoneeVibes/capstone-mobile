import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/sizing/app_sizing.dart';
import '../../core/theme/app_text_styles.dart';

/// Labelled text input: label above, bordered field below.
///
/// The label is passed by the calling screen, keeping wording where it is read.
/// With [showLabel] off the label moves inside the field as its hint, so the
/// field still announces what it is.
///
/// Everything after [hint] is forwarded unchanged to the underlying
/// `TextFormField`, which validates as the user types.
class AppTextField extends StatelessWidget {
  /// Creates a labelled field. Use inside a `Form` for [validator] to run on
  /// submit.
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

  /// What the field is for, shown above it (or inside it, see [showLabel]).
  final String label;

  /// Off for designs with placeholder-only fields, such as login.
  final bool showLabel;

  /// Lets the platform offer saved emails, passwords and one-time codes.
  final Iterable<String>? autofillHints;

  /// Placeholder text. Defaults to [label] when the label is hidden.
  final String? hint;

  /// Reads and sets the text. Mutually exclusive with [initialValue].
  final TextEditingController? controller;

  /// Starting text when there is no [controller].
  final String? initialValue;

  /// Returns an error message, or null when valid. See `Validators`.
  final String? Function(String?)? validator;

  /// Called on every change.
  final ValueChanged<String>? onChanged;

  /// Which keyboard to show.
  final TextInputType? keyboardType;

  /// The keyboard's action button — usually next, or done on the last field.
  final TextInputAction? textInputAction;

  /// Auto-capitalisation, e.g. words for names.
  final TextCapitalization textCapitalization;

  /// Filters or reshapes input as it is typed.
  final List<TextInputFormatter>? inputFormatters;

  /// False greys the field out and ignores input.
  final bool enabled;

  /// True shows the value but blocks editing, without greying it out.
  final bool readOnly;

  /// Hides the text, for passwords. Forces a single line.
  final bool obscureText;

  /// Lines before the field scrolls.
  final int maxLines;

  /// Character limit; no counter is shown.
  final int? maxLength;

  /// Focuses the field when it first builds.
  final bool autofocus;

  /// Widget inside the field, before the text.
  final Widget? prefixIcon;

  /// Widget inside the field, after the text — e.g. a show-password toggle.
  final Widget? suffixIcon;

  /// Lets the caller move focus programmatically.
  final FocusNode? focusNode;

  /// Called when the keyboard's action button is pressed.
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
