import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/network/api_client.dart';
import 'package:propertyintelmobileapp/core/network/api_endpoints.dart';
import 'package:propertyintelmobileapp/core/network/api_response.dart';
import 'package:propertyintelmobileapp/core/session/staff_role.dart';
import 'package:propertyintelmobileapp/features/auth/data/datasources/auth_remote_datasource.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient client;
  late AuthRemoteDataSourceImpl source;

  setUp(() {
    client = MockApiClient();
    source = AuthRemoteDataSourceImpl(client);
  });

  void stubPost(Map<String, dynamic> body) {
    when(
      () => client.post<Object?>(any(), data: any(named: 'data')),
    ).thenAnswer(
      (_) async =>
          ApiResponse<Object?>.fromJson(body),
    );
  }

  group('signIn', () {
    test('reads the token from the top of the envelope', () async {
      stubPost({'status': 'success', 'token': 'jwt'});

      final token = await source.signIn(email: 'a@b.co', password: 'pw');

      expect(token, 'jwt');
      verify(
        () => client.post<Object?>(
          ApiEndpoints.signIn,
          data: {'email': 'a@b.co', 'password': 'pw'},
        ),
      ).called(1);
    });

    test('fails rather than storing an empty session', () async {
      stubPost({'status': 'success'});

      expect(
        () => source.signIn(email: 'a@b.co', password: 'pw'),
        throwsFormatException,
      );
    });
  });

  test('both code checks go to verify-otp', () async {
    stubPost({'status': 'success', 'message': 'OTP is successfully verified'});

    await source.resetPassword(email: 'a@b.co', otp: '1', password: 'pw');

    final body =
        verify(
              () => client.post<Object?>(
                ApiEndpoints.verifyOtp,
                data: captureAny(named: 'data'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(body['otpType'], 'password-reset');
  });

  group('fetchStaffRole', () {
    void stubStaff(Map<String, dynamic> data) {
      when(
        () => client.get<StaffRole>(
          any(),
          headers: any(named: 'headers'),
          decoder: any(named: 'decoder'),
        ),
      ).thenAnswer((invocation) async {
        final decoder =
            invocation.namedArguments[#decoder] as StaffRole Function(Object?);
        return ApiResponse<StaffRole>.fromJson({
          'status': 'success',
          'data': data,
        }, decoder: decoder);
      });
    }

    test('reads the role from their own record, with the given token', () async {
      // Trimmed from the live response for a super-admin, 6 Oct 2026.
      stubStaff({'id': 'staff-1', 'type': 'staff', 'role': 'super-admin'});

      final role = await source.fetchStaffRole(userId: 'staff-1', token: 'jwt');

      expect(role, StaffRole.superAdmin);
      verify(
        () => client.get<StaffRole>(
          ApiEndpoints.staffById('staff-1'),
          headers: {'Authorization': 'Bearer jwt'},
          decoder: any(named: 'decoder'),
        ),
      ).called(1);
    });

    test('an unrecognised role grants nothing', () async {
      stubStaff({'id': 'staff-1', 'role': 'auditor'});

      final role = await source.fetchStaffRole(userId: 'staff-1', token: 'jwt');

      expect(role, StaffRole.unknown);
    });
  });
}
