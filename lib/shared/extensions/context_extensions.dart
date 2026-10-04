import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/error/app_failure.dart';

/// Shorthands for the lookups widgets do constantly.
extension BuildContextX on BuildContext {
  /// The ambient [ThemeData].
  ThemeData get theme => Theme.of(this);

  /// The theme's [TextTheme]. Prefer `AppTextStyles` in widgets.
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// The theme's [ColorScheme]. Prefer `AppColors` in widgets.
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// The logical size of the screen.
  Size get screenSize => MediaQuery.sizeOf(this);

  /// The logical width of the screen.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// The logical height of the screen.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Keyboard inset — add to sheet padding so fields stay visible.
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  /// System insets — status bar, notch, home indicator.
  EdgeInsets get screenPadding => MediaQuery.paddingOf(this);

  /// Dismisses the keyboard by unfocusing the current field.
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
