import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/network/api_client.dart';
import 'package:propertyintelmobileapp/core/network/api_endpoints.dart';
import 'package:propertyintelmobileapp/core/network/api_response.dart';
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
}
