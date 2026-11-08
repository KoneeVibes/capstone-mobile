import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/network/api_client.dart';
import 'package:propertyintelmobileapp/core/network/api_response.dart';
import 'package:propertyintelmobileapp/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:propertyintelmobileapp/features/profile/domain/entities/profile_draft.dart';
import 'package:propertyintelmobileapp/features/profile/domain/entities/user_profile.dart';

import '../../profile_fixtures.dart';

class MockApiClient extends Mock implements ApiClient {}

ApiResponse<UserProfile> _decoded(Invocation invocation) {
  final decoder =
      invocation.namedArguments[#decoder] as UserProfile Function(Object?);
  return ApiResponse<UserProfile>(
    status: 'success',
    message: 'success',
    data: decoder(staffProfileJson),
  );
}

void main() {
  late MockApiClient client;
  late ProfileRemoteDataSourceImpl source;

  setUp(() {
    client = MockApiClient();
    source = ProfileRemoteDataSourceImpl(client);
  });

  test('reads GET /profile', () async {
    when(
      () => client.get<UserProfile>(any(), decoder: any(named: 'decoder')),
    ).thenAnswer((invocation) async => _decoded(invocation));

    final profile = await source.fetchProfile();

    expect(profile.firstName, 'Ada');
    verify(
      () => client.get<UserProfile>('/profile', decoder: any(named: 'decoder')),
    ).called(1);
  });

  test('PUTs the draft as multipart and returns the saved record', () async {
    when(
      () => client.put<UserProfile>(
        any(),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async => _decoded(invocation));

    final saved = await source.updateProfile(
      const ProfileDraft(phone: '+2348012345678'),
    );

    expect(saved.lastName, 'Okafor Regular');
    final captured = verify(
      () => client.put<UserProfile>(
        captureAny(),
        data: captureAny(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).captured;
    expect(captured[0], '/profile');
    final form = captured[1] as FormData;
    expect(form.fields.single.key, 'phone');
  });
}
