import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/core/utils/media_picker.dart';
import 'package:propertyintelmobileapp/features/profile/data/models/user_profile_model.dart';
import 'package:propertyintelmobileapp/features/profile/domain/entities/profile_draft.dart';

import '../../profile_fixtures.dart';

void main() {
  group('fromData', () {
    test('reads a sparse profile, nulls and all', () {
      final profile = UserProfileModel.fromData(clientProfileJson);

      expect(profile.id, '77718a9e-1420-4b5b-bdca-90892b8dba26');
      expect(profile.fullName, 'Qa Throwaway');
      expect(profile.initials, 'QT');
      expect(profile.middleName, isNull);
      expect(profile.phone, isNull);
      expect(profile.avatarUrl, isNull);
    });

    test('reads every field, ignoring the store key', () {
      final profile = UserProfileModel.fromData(staffProfileJson);

      expect(profile.id, '9d90a50d-416d-45fa-97eb-135e31cce92a');
      expect(profile.fullName, 'Ada Grace Okafor Regular');
      expect(profile.phone, '+2348012345678');
      expect(profile.avatarUrl, 'https://res.cloudinary.com/demo/avatar.jpg');
    });

    test('treats a blank middle name as none', () {
      final profile = UserProfileModel.fromData({
        ...staffProfileJson,
        'middleName': '',
      });

      expect(profile.middleName, isNull);
    });

    test('refuses a response with no profile', () {
      expect(() => UserProfileModel.fromData(null), throwsFormatException);
    });
  });

  group('formDataFrom', () {
    Map<String, String> fieldsOf(FormData form) => {
      for (final field in form.fields) field.key: field.value,
    };

    test('sends only the fields the draft sets, trimmed', () async {
      final form = await UserProfileModel.formDataFrom(
        const ProfileDraft(firstName: ' Ada ', middleName: ''),
      );

      expect(fieldsOf(form), {'firstName': 'Ada', 'middleName': ''});
      expect(form.files, isEmpty);
    });

    test('sends a photo on its own as avatar', () async {
      final dir = Directory.systemTemp.createTempSync('profile_avatar');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = '${dir.path}/me.png';
      File(path).writeAsBytesSync([1, 2, 3]);

      final form = await UserProfileModel.formDataFrom(
        ProfileDraft.photo(
          PickedMedia(
            path: path,
            fileName: 'me.png',
            sizeBytes: 3,
            extension: 'png',
          ),
        ),
      );

      expect(form.fields, isEmpty);
      expect(form.files.single.key, 'avatar');
      expect(form.files.single.value.contentType.toString(), 'image/png');
    });
  });
}
