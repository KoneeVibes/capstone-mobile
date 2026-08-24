import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_constants.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/sizing/app_sizing.dart';
import '../../core/theme/app_colors.dart';

/// The app's first screen: the brand wordmark on white.
///
/// The native launch screens paint the same white, so the handoff into Flutter
/// is invisible. The wordmark is drawn here rather than by the platform because
/// Android 12 replaced the window-background launch screen with an API that
/// masks the launcher icon to a circle — which a 4.3:1 wordmark cannot survive.
///
/// TODO(auth): the timer is a branding beat with nothing behind it. When
/// authentication lands, await the session restore here and treat
/// [AppConstants.splashDuration] as a floor rather than the whole wait, so a
/// slow start holds the screen and a fast one still does not flash past.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(AppConstants.splashDuration, _openNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Hands off to the root route, which redirects to the branch matching the
  /// current role. Deciding that here too would duplicate the router's rule.
  void _openNext() {
    if (!mounted) return;
    context.goNamed(AppRoutes.rootName);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // There is no AppBar here for the status bar to take its styling from,
      // so state it outright: dark icons, as everywhere else in the app.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: Image.asset(
            AppAssets.splashLogo,
            width: AppSizing.splashLogoWidth,
            fit: BoxFit.contain,
            semanticLabel: AppConstants.appName,
          ),
        ),
      ),
    );
  }
}
