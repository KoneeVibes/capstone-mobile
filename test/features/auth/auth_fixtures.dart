import 'dart:convert';

import 'package:propertyintelmobileapp/features/auth/domain/entities/sign_up_draft.dart';

/// The token sign-in returned for the live test account on 4 Oct 2026:
/// `{id: 6ac271ffddec7de7f357e017, type: registered-client, iat: 1791128125,
/// exp: 1791214525}`.
const liveClientToken =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjZhYzI3MWZmZGRlYzdkZTdmMzU3'
    'ZTAxNyIsInR5cGUiOiJyZWdpc3RlcmVkLWNsaWVudCIsImlhdCI6MTc5MTEyODEyNSwiZXhw'
    'IjoxNzkxMjE0NTI1fQ.FenylZ0iy5UmTC-mie7Swc4oiXVjDr4PTWMmTNOjj5k';

/// When [liveClientToken] expires.
final liveClientTokenExpiry = DateTime.fromMillisecondsSinceEpoch(
  1791214525 * 1000,
  isUtc: true,
);

/// A JWT-shaped token carrying [payload]. Unsigned — nothing on the device
/// checks the signature.
String tokenWith(Map<String, Object?> payload) {
  final body = base64Url
      .encode(utf8.encode(jsonEncode(payload)))
      .replaceAll('=', '');
  return 'eyJhbGciOiJIUzI1NiJ9.$body.signature';
}

/// A client token for [id] expiring at [expiresAt].
String clientToken({String id = 'user-1', DateTime? expiresAt}) => tokenWith({
  'id': id,
  'type': 'registered-client',
  'iat': 0,
  'exp':
      (expiresAt ?? DateTime.utc(2030)).millisecondsSinceEpoch ~/ 1000,
});

const signUpDraft = SignUpDraft(
  firstName: 'Ada',
  lastName: 'Okafor',
  email: 'ada@example.com',
  password: 'SecurePassword123!',
);
