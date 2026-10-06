import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/property_search/data/models/search_request_model.dart';
import 'package:propertyintelmobileapp/features/property_search/domain/entities/search_request.dart';

import '../../property_search_fixtures.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('search_request'));
  tearDown(() => dir.deleteSync(recursive: true));

  group('formDataFrom', () {
    test('sends every field the create requires, trimmed', () async {
      final form = await SearchRequestModel.formDataFrom(searchRequest(dir));
      final fields = {for (final field in form.fields) field.key: field.value};

      expect(fields, {
        'applicantName': 'Zz Throwaway',
        'applicantEmail': 'pi.qa@yopmail.com',
        'applicantPhone': '08034112290',
        'propertyState': 'Lagos',
        'propertyLGA': 'Ikeja',
        'propertyCity': 'Ikeja',
        'propertyAddress': '1 Test Street',
        'propertyType': 'land',
        // Repeated keys collapse in this map; checked separately below.
        'propertyTitleType': 'Deed of Assignment',
        'inquiryPurpose': 'Physical Inspection',
        'source': 'mobile-app',
      });
    });

    test(
      'repeats a key per list value, in the wording the API takes',
      () async {
        final form = await SearchRequestModel.formDataFrom(searchRequest(dir));
        List<String> valuesOf(String key) => [
          for (final field in form.fields)
            if (field.key == key) field.value,
        ];

        expect(valuesOf('propertyTitleType'), [
          'Certificate of Occupancy',
          'Deed of Assignment',
        ]);
        expect(valuesOf('inquiryPurpose'), [
          'Due Diligence',
          'Physical Inspection',
        ]);
      },
    );

    test('attaches each upload under its own field and type', () async {
      final form = await SearchRequestModel.formDataFrom(searchRequest(dir));

      expect(form.files.map((file) => file.key), [
        'propertySurveyPlan',
        'propertyTitleDocument',
      ]);
      expect(form.files.first.value.filename, 'plan.pdf');
      expect(form.files.first.value.contentType?.mimeType, 'application/pdf');
      expect(form.files.last.value.contentType?.mimeType, 'image/png');
    });
  });

  test('declares a picked jpg as jpeg', () {
    expect(
      SearchRequestModel.contentTypeOf(
        pickedFile('/x/photo.jpg', extension: 'jpg'),
      ).mimeType,
      'image/jpeg',
    );
  });

  group('submittedFromData', () {
    test('reads the live reply', () {
      expect(
        SearchRequestModel.submittedFromData(createdJson),
        const SubmittedSearch(
          trackingId: 'PI-DU2964LK',
          invoiceId: 'b2516f32-14e9-41ad-9671-0b1dede6f602',
        ),
      );
    });

    test('rejects a reply missing either id', () {
      expect(
        () => SearchRequestModel.submittedFromData({'trackingId': 'PI-X'}),
        throwsFormatException,
      );
      expect(
        () => SearchRequestModel.submittedFromData(null),
        throwsFormatException,
      );
    });
  });
}
