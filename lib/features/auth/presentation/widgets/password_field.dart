import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_text_field.dart';

/// A password input with a show/hide toggle.
class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.label,
    required this.controller,
    super.key,
    this.hint,
    this.showLabel = true,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.autofillHints = const [AutofillHints.password],
  });

  final String label;
  final String? hint;
  final bool showLabel;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String> autofillHints;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      hint: widget.hint,
      showLabel: widget.showLabel,
      controller: widget.controller,
      validator: widget.validator,
      obscureText: _obscured,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofillHints: widget.autofillHints,
      suffixIcon: IconButton(
        tooltip: _obscured ? 'Show password' : 'Hide password',
        onPressed: () => setState(() => _obscured = !_obscured),
        icon: Icon(
          _obscured
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
        ),
      ),
    );
  }
}
