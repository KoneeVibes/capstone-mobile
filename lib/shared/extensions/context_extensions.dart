import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/error/app_failure.dart';

/// Shorthands for the lookups widgets do constantly.
extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => Theme.of(this).textTheme;

  ColorScheme get colors => Theme.of(this).colorScheme;

  Size get screenSize => MediaQuery.sizeOf(this);

  double get screenWidth => MediaQuery.sizeOf(this).width;

  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Keyboard inset — add to sheet padding so fields stay visible.
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  EdgeInsets get screenPadding => MediaQuery.paddingOf(this);

  void hideKeyboard() => FocusScope.of(this).unfocus();

  /// Neutral confirmation message.
  void showMessage(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Renders a failure the only way it is allowed to be rendered: through
  /// [AppFailure.message]. Never pass an exception or a `toString()` here.
  void showFailure(AppFailure failure) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: AppColors.destructive,
        ),
      );
  }
}
