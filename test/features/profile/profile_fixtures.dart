import 'package:propertyintelmobileapp/features/profile/domain/entities/user_profile.dart';

/// `GET /profile` as the live API answered for the QA client (8 Nov 2026).
const Map<String, dynamic> clientProfileJson = {
  '_id': '6ac292e10944eae985787e40',
  'id': '77718a9e-1420-4b5b-bdca-90892b8dba26',
  'firstName': 'Qa',
  'middleName': null,
  'lastName': 'Throwaway',
  'avatar': null,
  'phone': null,
};

/// The regular staff account's answer, with every field set.
const Map<String, dynamic> staffProfileJson = {
  '_id': '6ac4dcaeea36c20debf62725',
  'id': '9d90a50d-416d-45fa-97eb-135e31cce92a',
  'firstName': 'Ada',
  'middleName': 'Grace',
  'lastName': 'Okafor Regular',
  'avatar': 'https://res.cloudinary.com/demo/avatar.jpg',
  'phone': '+2348012345678',
};

/// The signed-in user of `session_fixtures.dart`.
const profile = UserProfile(
  id: 'user-1',
  firstName: 'Ada',
  middleName: 'Grace',
  lastName: 'Okafor',
  phone: '+2348012345678',
);
