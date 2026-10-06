import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/session/staff_role.dart';
import '../../domain/entities/sign_up_draft.dart';
import '../models/auth_payloads.dart';

/// The auth endpoints. Throws on failure — `DioException` propagates untouched
/// for `AuthRepositoryImpl` to convert.
///
/// None of these return a `data` node; only sign-in returns anything, and its
/// `token` sits at the top of the envelope.
abstract class AuthRemoteDataSource {
  /// The JWT.
  Future<String> signIn({required String email, required String password});

  Future<void> signUp(SignUpDraft draft);

  Future<void> verifySignUp({required SignUpDraft draft, required String otp});

  Future<void> requestPasswordReset(String email);

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String password,
  });

  Future<void> signOut();

  /// The staff member's role from `GET /staff/{id}`. Takes the [token]
  /// explicitly: at sign-in the session that would supply it does not exist
  /// yet.
  Future<StaffRole> fetchStaffRole({
    required String userId,
    required String token,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.post<Object?>(
      ApiEndpoints.signIn,
      data: AuthPayloads.signIn(email: email, password: password),
    );

    final token = response.body['token'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('Sign-in returned no token.');
    }
    return token;
  }

  @override
  Future<void> signUp(SignUpDraft draft) =>
      _client.post<Object?>(ApiEndpoints.signUp, data: AuthPayloads.signUp(draft));

  @override
  Future<void> verifySignUp({
    required SignUpDraft draft,
    required String otp,
  }) => _client.post<Object?>(
    ApiEndpoints.verifyOtp,
    data: AuthPayloads.verifySignUp(draft: draft, otp: otp),
  );

  @override
  Future<void> requestPasswordReset(String email) => _client.post<Object?>(
    ApiEndpoints.forgotPassword,
    data: AuthPayloads.forgotPassword(email),
  );

  @override
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) => _client.post<Object?>(
    ApiEndpoints.verifyOtp,
    data: AuthPayloads.resetPassword(
      email: email,
      otp: otp,
      password: password,
    ),
  );

  @override
  Future<void> signOut() => _client.post<Object?>(ApiEndpoints.signOut);

  @override
  Future<StaffRole> fetchStaffRole({
    required String userId,
    required String token,
  }) async {
    final response = await _client.get<StaffRole>(
      ApiEndpoints.staffById(userId),
      headers: {'Authorization': 'Bearer $token'},
      decoder: (data) {
        if (data is! Map<String, dynamic>) {
          throw const FormatException('Expected a staff object in "data".');
        }
        final role = data['role'];
        return StaffRole.fromApi(role is String ? role : null);
      },
    );
    return response.data;
  }
}
