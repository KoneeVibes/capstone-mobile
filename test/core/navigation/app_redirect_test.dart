import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/core/navigation/app_redirect.dart';
import 'package:propertyintelmobileapp/core/navigation/app_routes.dart';
import 'package:propertyintelmobileapp/core/navigation/app_session.dart';

String? _redirect(
  String location, {
  AppRole? role,
  bool hasSeenOnboarding = true,
  bool canViewStaff = true,
}) => redirectFor(
  role: role,
  hasSeenOnboarding: hasSeenOnboarding,
  location: location,
  canViewStaff: canViewStaff,
);

void main() {
  group('signed out, first launch', () {
    test('sends everything to onboarding', () {
      for (final location in [
        AppRoutes.rootPath,
        AppRoutes.loginPath,
        AppRoutes.registerPath,
        AppRoutes.dashboardPath,
      ]) {
        expect(
          _redirect(location, hasSeenOnboarding: false),
          AppRoutes.onboardingPath,
          reason: location,
        );
      }
    });

    test('stays on onboarding', () {
      expect(
        _redirect(AppRoutes.onboardingPath, hasSeenOnboarding: false),
        isNull,
      );
    });
  });

  group('signed out, onboarding seen', () {
    test('sends the root and both shells to login', () {
      for (final location in [
        AppRoutes.rootPath,
        AppRoutes.dashboardPath,
        '/client/cases/case-1',
      ]) {
        expect(_redirect(location), AppRoutes.loginPath, reason: location);
      }
    });

    test('moves on from onboarding to login', () {
      expect(_redirect(AppRoutes.onboardingPath), AppRoutes.loginPath);
    });

    test('leaves every sign-in screen reachable', () {
      for (final location in [
        AppRoutes.loginPath,
        AppRoutes.registerPath,
        AppRoutes.registerVerifyPath,
        AppRoutes.forgotPasswordPath,
        AppRoutes.forgotPasswordVerifyPath,
        AppRoutes.resetPasswordPath,
        AppRoutes.passwordChangedPath,
      ]) {
        expect(_redirect(location), isNull, reason: location);
      }
    });
  });

  group('signed in', () {
    test('sends staff from the root to the dashboard', () {
      expect(
        _redirect(AppRoutes.rootPath, role: AppRole.staff),
        AppRoutes.dashboardPath,
      );
    });

    test('sends a client from the root to their home tab', () {
      expect(
        _redirect(AppRoutes.rootPath, role: AppRole.client),
        AppRoutes.clientHomePath,
      );
    });

    test('moves a user off the sign-in screens once signed in', () {
      for (final location in [
        AppRoutes.loginPath,
        AppRoutes.registerVerifyPath,
        AppRoutes.onboardingPath,
      ]) {
        expect(
          _redirect(location, role: AppRole.client),
          AppRoutes.clientHomePath,
          reason: location,
        );
      }
    });

    test('keeps staff out of the client shell', () {
      for (final location in [
        AppRoutes.clientRootPath,
        AppRoutes.clientCasesPath,
        '/client/cases/case-1',
      ]) {
        expect(
          _redirect(location, role: AppRole.staff),
          AppRoutes.dashboardPath,
          reason: location,
        );
      }
    });

    test('keeps a client out of the staff shell', () {
      for (final location in [
        AppRoutes.staffHomePath,
        AppRoutes.staffMembersPath,
        '/staff/cases/case-1',
      ]) {
        expect(
          _redirect(location, role: AppRole.client),
          AppRoutes.clientHomePath,
          reason: location,
        );
      }
    });

    test('leaves each role alone inside its own shell', () {
      expect(_redirect('/staff/cases/case-1', role: AppRole.staff), isNull);
      expect(_redirect('/client/cases/case-1', role: AppRole.client), isNull);
    });

    test('keeps staff who cannot list staff off the Staff tab', () {
      expect(
        _redirect(
          AppRoutes.staffMembersPath,
          role: AppRole.staff,
          canViewStaff: false,
        ),
        AppRoutes.dashboardPath,
      );
      expect(_redirect(AppRoutes.staffMembersPath, role: AppRole.staff), isNull);
      // The rest of the shell is still theirs.
      expect(
        _redirect(AppRoutes.casesPath, role: AppRole.staff, canViewStaff: false),
        isNull,
      );
    });

    test('matches whole path segments, not prefixes', () {
      expect(_redirect('/staffing', role: AppRole.client), isNull);
      expect(_redirect('/login-help', role: AppRole.client), isNull);
    });
  });

  test('leaves the splash and the legal pages to everyone', () {
    for (final role in [null, ...AppRole.values]) {
      for (final seen in [true, false]) {
        for (final location in [
          AppRoutes.splashPath,
          AppRoutes.termsPath,
          AppRoutes.privacyPolicyPath,
        ]) {
          expect(
            _redirect(location, role: role, hasSeenOnboarding: seen),
            isNull,
            reason: '$location as $role',
          );
        }
      }
    }
  });
}
