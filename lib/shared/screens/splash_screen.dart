import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_constants.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/navigation/app_session.dart';
import '../../core/sizing/app_sizing.dart';
import '../../core/theme/app_colors.dart';

/// The app's first screen: the brand wordmark on white.
///
/// The native launch screens paint the same white, so the handoff into Flutter
/// is invisible. The wordmark is drawn here rather than by the platform because
/// Android 12 replaced the window-background launch screen with an API that
/// masks the launcher icon to a circle — which a 4.3:1 wordmark cannot survive.
///
/// Holds until the stored session has been read, and for at least
/// [AppConstants.splashDuration] so a fast start does not flash past.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_holdThenOpen());
  }

  Future<void> _holdThenOpen() async {
    await Future.wait([
      Future<void>.delayed(AppConstants.splashDuration),
      ref.read(sessionRestoreProvider.future),
    ]);
    _openNext();
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
