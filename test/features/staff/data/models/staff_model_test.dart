import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/staff/data/models/staff_model.dart';
import 'package:propertyintelmobileapp/features/staff/domain/entities/staff_draft.dart';
import 'package:propertyintelmobileapp/features/staff/domain/entities/staff_role.dart';
import 'package:propertyintelmobileapp/features/staff/domain/entities/staff_status.dart';

/// The payload exactly as the OpenAPI spec documents it.
const _documented = <String, dynamic>{
  'id': '7c8d3a65-6c09-489f-96d5-0f8454b5a8be',
  'firstName': 'Ada',
  'middleName': 'Grace',
  'lastName': 'Okafor',
  'email': 'ada.okafor@example.com',
  'phone': '+2348012345678',
  'avatar': 'https://res.cloudinary.com/demo/image/upload/avatar/example.jpg',
  'role': 'manager',
  'type': 'staff',
  'status': 'active',
  'createdAt': '2026-08-12T18:11:45.542Z',
  'updatedAt': '2026-08-12T18:11:45.542Z',
};

/// The payload the live API actually returns: extra keys, and an empty-string
/// middle name rather than null.
const _live = <String, dynamic>{
  '_id': '6a7a11b7ff370cdcbc73f3c4',
  'id': 'b0e1b50e-8bad-4ca1-8e67-3ef64bba2a90',
  'firstName': 'Ofofonono',
  'middleName': '',
  'lastName': 'Umoren',
  'email': 'umorenofofonono@gmail.com',
  'avatar': 'https://res.cloudinary.com/wyv2jitx/image/upload/v1/avatar/x.jpg',
  'phone': '+2348082238742',
  'type': 'staff',
  'role': 'manager',
  'organization': null,
  'status': 'active',
  'passwordChanged': false,
  'createdAt': '2026-08-10T18:00:23.337Z',
  'updatedAt': '2026-08-10T19:32:33.334Z',
  '__v': 0,
};

void main() {
  group('StaffModel.fromJson', () {
    test('decodes the documented payload', () {
      final staff = StaffModel.fromJson(_documented);

      expect(staff.id, '7c8d3a65-6c09-489f-96d5-0f8454b5a8be');
      expect(staff.firstName, 'Ada');
      expect(staff.middleName, 'Grace');
      expect(staff.lastName, 'Okafor');
      expect(staff.email, 'ada.okafor@example.com');
      expect(staff.phone, '+2348012345678');
      expect(staff.avatarUrl, isNotNull);
      expect(staff.role, StaffRole.manager);
      expect(staff.status, StaffStatus.active);
      expect(staff.createdAt?.toUtc().day, 12);
      expect(staff.fullName, 'Ada Grace Okafor');
      expect(staff.shortName, 'Ada Okafor');
      expect(staff.initials, 'AO');
      expect(staff.isActive, isTrue);
      expect(staff.hasAvatar, isTrue);
    });

    test('decodes the live payload, ignoring undocumented fields', () {
      final staff = StaffModel.fromJson(_live);

      expect(staff.id, 'b0e1b50e-8bad-4ca1-8e67-3ef64bba2a90');
      expect(staff.firstName, 'Ofofonono');
      expect(staff.lastName, 'Umoren');
      expect(staff.role, StaffRole.manager);
      expect(staff.status, StaffStatus.active);
    });

    test('normalises an empty middle name to null', () {
      expect(StaffModel.fromJson(_live).middleName, isNull);
      expect(
        StaffModel.fromJson({..._documented, 'middleName': '   '}).middleName,
        isNull,
      );
    });

    test('prefers id over _id', () {
      final staff = StaffModel.fromJson({'id': 'app-id', '_id': 'store-id'});
      expect(staff.id, 'app-id');
    });

    test('falls back to _id when id is absent', () {
      expect(StaffModel.fromJson({'_id': 'store-id'}).id, 'store-id');
    });

    test('survives a payload missing every optional field', () {
      final staff = StaffModel.fromJson({
        'id': 'x',
        'firstName': 'Solo',
        'lastName': 'Name',
        'email': 'solo@example.com',
        'role': 'regular',
        'status': 'active',
      });

      expect(staff.middleName, isNull);
      expect(staff.phone, isNull);
      expect(staff.avatarUrl, isNull);
      expect(staff.createdAt, isNull);
      expect(staff.updatedAt, isNull);
      expect(staff.hasAvatar, isFalse);
      expect(staff.fullName, 'Solo Name');
    });

    test('maps an unrecognised role or status to unknown instead of throwing', () {
      final staff = StaffModel.fromJson({
        ..._documented,
        'role': 'supervisor',
        'status': 'archived',
      });

      expect(staff.role, StaffRole.unknown);
      expect(staff.status, StaffStatus.unknown);
      expect(staff.isActive, isFalse);
    });

    test('tolerates non-string values where strings are expected', () {
      final staff = StaffModel.fromJson({
        'id': 'x',
        'firstName': 'Ada',
        'lastName': 'Okafor',
        'email': 'a@b.com',
        'phone': 12345,
        'role': 'admin',
        'status': 'active',
      });

      expect(staff.phone, isNull);
      expect(staff.role, StaffRole.admin);
    });

    test('returns null for an unparseable timestamp', () {
      final staff = StaffModel.fromJson({
        ..._documented,
        'createdAt': 'not a date',
      });
      expect(staff.createdAt, isNull);
    });
  });

  group('StaffModel.listFromJson', () {
    test('decodes a list of records', () {
      final staff = StaffModel.listFromJson([_documented, _live]);
      expect(staff, hasLength(2));
      expect(staff.first.firstName, 'Ada');
    });

    test('returns empty for a null or non-list data node', () {
      expect(StaffModel.listFromJson(null), isEmpty);
      expect(StaffModel.listFromJson('nonsense'), isEmpty);
    });

    test('skips entries that are not objects', () {
      expect(StaffModel.listFromJson([_documented, 'junk', 7]), hasLength(1));
    });
  });

  group('StaffModel.fromData', () {
    test('decodes a single record', () {
      expect(StaffModel.fromData(_documented).firstName, 'Ada');
    });

    test('throws a FormatException when data is not an object', () {
      expect(() => StaffModel.fromData(null), throwsFormatException);
      expect(() => StaffModel.fromData(<dynamic>[]), throwsFormatException);
    });
  });

  group('StaffModel.formDataFrom', () {
    const draft = StaffDraft(
      firstName: '  Ekong ',
      middleName: 'Grace',
      lastName: 'Silas',
      email: ' ekong@slp.africa ',
      phone: '08034112290',
      role: StaffRole.admin,
    );

    Map<String, String> fieldsOf(FormData data) => {
      for (final field in data.fields) field.key: field.value,
    };

    test('sends every editable field, trimmed', () async {
      final fields = fieldsOf(await StaffModel.formDataFrom(draft));

      expect(fields['firstName'], 'Ekong');
      expect(fields['middleName'], 'Grace');
      expect(fields['lastName'], 'Silas');
      expect(fields['email'], 'ekong@slp.africa');
      expect(fields['phone'], '08034112290');
    });

    test('sends the role as its API value, not the enum name', () async {
      final fields = fieldsOf(await StaffModel.formDataFrom(draft));
      expect(fields['role'], 'admin');
    });

    test('never sends a status field, which the API does not accept', () async {
      final fields = fieldsOf(await StaffModel.formDataFrom(draft));
      expect(fields.containsKey('status'), isFalse);
    });

    test('always includes middleName so clearing it takes effect', () async {
      final cleared = await StaffModel.formDataFrom(
        draft.copyWith(middleName: ''),
      );
      final fields = fieldsOf(cleared);

      expect(fields.containsKey('middleName'), isTrue);
      expect(fields['middleName'], '');
    });

    test('omits the avatar when no file was picked', () async {
      final data = await StaffModel.formDataFrom(draft);
      expect(data.files, isEmpty);
    });
  });

  group('StaffModel avatar upload', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('staff_avatar_test');
    });

    tearDown(() async {
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    /// Writes a throwaway file so MultipartFile.fromFile has something to read.
    Future<String> writeFile(String name) async {
      final file = File('${tempDir.path}${Platform.pathSeparator}$name');
      await file.writeAsBytes([1, 2, 3, 4]);
      return file.path;
    }

    const base = StaffDraft(
      firstName: 'Ekong',
      lastName: 'Silas',
      email: 'ekong@slp.africa',
      phone: '08034112290',
      role: StaffRole.admin,
    );

    test('sends a PNG as image/png', () {
      final (filename, mediaType) = StaffModel.avatarUpload('/tmp/shot.png');

      expect(filename, 'avatar.png');
      expect(mediaType.mimeType, 'image/png');
    });

    test('sends a JPG as image/jpeg', () {
      final (filename, mediaType) = StaffModel.avatarUpload('/tmp/shot.jpg');

      expect(filename, 'avatar.jpg');
      expect(mediaType.mimeType, 'image/jpeg');
    });

    test('declares a re-encoded HEIC as JPEG, never as HEIC', () {
      // image_picker hands back JPEG bytes for an iPhone HEIC, but the path can
      // keep its original extension. Trusting the path would send a media type
      // the API rejects outright.
      final (filename, mediaType) = StaffModel.avatarUpload('/tmp/IMG_01.heic');

      expect(filename, 'avatar.jpg');
      expect(mediaType.mimeType, 'image/jpeg');
    });

    test('is case-insensitive about the extension', () {
      expect(StaffModel.avatarUpload('/tmp/A.PNG').$1, 'avatar.png');
      expect(StaffModel.avatarUpload('/tmp/A.JPEG').$1, 'avatar.jpg');
    });

    test('attaches the picked file to the multipart body', () async {
      final path = await writeFile('avatar.png');

      final data = await StaffModel.formDataFrom(
        base.copyWith(avatarPath: path),
      );

      expect(data.files, hasLength(1));
      final entry = data.files.single;
      expect(entry.key, 'avatar');
      expect(entry.value.filename, 'avatar.png');
      expect(entry.value.contentType?.mimeType, 'image/png');
    });

    test('leaves the text fields intact when an avatar is attached', () async {
      final path = await writeFile('avatar.jpg');

      final data = await StaffModel.formDataFrom(
        base.copyWith(avatarPath: path),
      );
      final fields = {
        for (final field in data.fields) field.key: field.value,
      };

      expect(fields['firstName'], 'Ekong');
      expect(fields['role'], 'admin');
      expect(fields['email'], 'ekong@slp.africa');
      expect(fields.containsKey('status'), isFalse);
    });
  });
}
