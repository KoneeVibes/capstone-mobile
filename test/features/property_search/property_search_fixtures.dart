import 'dart:io';

import 'package:propertyintelmobileapp/core/utils/media_picker.dart';
import 'package:propertyintelmobileapp/features/property_search/domain/entities/property_location.dart';
import 'package:propertyintelmobileapp/features/property_search/domain/entities/search_options.dart';
import 'package:propertyintelmobileapp/features/property_search/domain/entities/search_request.dart';

/// Rows from the live `GET /misc/location`, 6 Oct 2026, trimmed to two states.
const List<Map<String, Object?>> locationsJson = [
  {'state': 'Lagos', 'lga': 'Ikeja', 'city': 'Ikeja', 'rate': 4500},
  {'state': 'Lagos', 'lga': 'Eti-Osa', 'city': 'Victoria Island', 'rate': 6000},
  {'state': 'Lagos', 'lga': 'Surulere', 'city': 'Surulere', 'rate': 4200},
  {'state': 'FCT', 'lga': 'AMAC', 'city': 'Abuja', 'rate': 5500},
];

const ikeja = PropertyLocation(
  state: 'Lagos',
  lga: 'Ikeja',
  city: 'Ikeja',
  rate: 4500,
);

const locations = [
  ikeja,
  PropertyLocation(
    state: 'Lagos',
    lga: 'Eti-Osa',
    city: 'Victoria Island',
    rate: 6000,
  ),
  PropertyLocation(state: 'FCT', lga: 'AMAC', city: 'Abuja', rate: 5500),
];

/// The live create reply.
const Map<String, Object?> createdJson = {
  'invoiceId': 'b2516f32-14e9-41ad-9671-0b1dede6f602',
  'trackingId': 'PI-DU2964LK',
};

PickedMedia pickedFile(String path, {String extension = 'pdf'}) => PickedMedia(
  path: path,
  fileName: path.split('/').last,
  sizeBytes: 64,
  extension: extension,
);

/// A request whose files exist, so `MultipartFile.fromFile` can open them.
SearchRequest searchRequest(Directory dir) {
  File('${dir.path}/plan.pdf').writeAsStringSync('%PDF-1.1');
  File('${dir.path}/deed.png').writeAsStringSync('png');
  return SearchRequest(
    applicantName: ' Zz Throwaway ',
    applicantEmail: 'pi.qa@yopmail.com',
    applicantPhone: '0803 411-2290',
    location: ikeja,
    address: '1 Test Street ',
    propertyClass: PropertyClass.land,
    titleTypes: const {
      TitleType.certificateOfOccupancy,
      TitleType.deedOfAssignment,
    },
    purposes: const {
      InquiryPurpose.dueDiligence,
      InquiryPurpose.physicalInspection,
    },
    surveyPlans: [pickedFile('${dir.path}/plan.pdf')],
    titleDocuments: [pickedFile('${dir.path}/deed.png', extension: 'png')],
  );
}
