import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/core/navigation/app_redirect.dart';
import 'package:propertyintelmobileapp/core/navigation/app_routes.dart';
import 'package:propertyintelmobileapp/core/navigation/app_session.dart';

void main() {
  group('redirectFor', () {
    test('sends staff from the root to the dashboard', () {
      expect(
        redirectFor(role: AppRole.staff, location: AppRoutes.rootPath),
        AppRoutes.dashboardPath,
      );
    });

    test('sends a client from the root to their home tab', () {
      expect(
        redirectFor(role: AppRole.client, location: AppRoutes.rootPath),
        AppRoutes.clientHomePath,
      );
    });

    test('keeps staff out of the client shell', () {
      for (final location in [
        AppRoutes.clientRootPath,
        AppRoutes.clientCasesPath,
        '/client/cases/case-1',
      ]) {
        expect(
          redirectFor(role: AppRole.staff, location: location),
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
          redirectFor(role: AppRole.client, location: location),
          AppRoutes.clientHomePath,
          reason: location,
        );
      }
    });

    test('leaves each role alone inside its own shell', () {
      expect(
        redirectFor(role: AppRole.staff, location: '/staff/cases/case-1'),
        isNull,
      );
      expect(
        redirectFor(role: AppRole.client, location: '/client/cases/case-1'),
        isNull,
      );
    });

    test('matches whole path segments, not prefixes', () {
      expect(redirectFor(role: AppRole.client, location: '/staffing'), isNull);
    });

    test('leaves shared routes to everyone', () {
      for (final role in AppRole.values) {
        expect(redirectFor(role: role, location: AppRoutes.splashPath), isNull);
        expect(redirectFor(role: role, location: AppRoutes.termsPath), isNull);
      }
    });

    test('does nothing while signed out', () {
      expect(redirectFor(role: null, location: AppRoutes.rootPath), isNull);
    });
  });

  group('devRoleFrom', () {
    test('reads client, ignoring case and whitespace', () {
      expect(devRoleFrom(' Client '), AppRole.client);
    });

    test('defaults to staff when unset or unrecognised', () {
      expect(devRoleFrom(''), AppRole.staff);
      expect(devRoleFrom('admin'), AppRole.staff);
    });
  });
}
