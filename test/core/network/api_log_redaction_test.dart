import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/core/network/api_client.dart';

/// The real `DELETE /api/v1/staff/{id}` response, which includes the account's
/// bcrypt password hash.
const _deleteResponse = <String, dynamic>{
  'status': 'success',
  'message': 'Staff member deleted successfully.',
  'data': {
    'id': '7608004d-eb01-49bb-86a7-648d5e81f867',
    'firstName': 'Zztest',
    'email': 'qa.throwaway@example.com',
    'password': r'$2b$10$3trvVwAt/VkfkTlhk1Bynu7gKhhEmabqT1HqHtks1eGnay64s5nY.',
    'role': 'manager',
    'status': 'inactive',
  },
};

void main() {
  group('redactSecretsForLog', () {
    test('masks a password hash nested in a response body', () {
      final redacted = redactSecretsForLog(_deleteResponse)! as Map;
      final data = redacted['data'] as Map;

      expect(data['password'], '***');
      expect(jsonEncode(redacted), isNot(contains(r'$2b$10$')));
    });

    test('leaves non-secret fields untouched', () {
      final redacted = redactSecretsForLog(_deleteResponse)! as Map;
      final data = redacted['data'] as Map;

      expect(redacted['message'], 'Staff member deleted successfully.');
      expect(data['firstName'], 'Zztest');
      expect(data['email'], 'qa.throwaway@example.com');
      expect(data['status'], 'inactive');
    });

    test('masks every known secret key regardless of casing', () {
      final redacted =
          redactSecretsForLog({
                'Password': 'p',
                'accessToken': 't',
                'refreshToken': 'r',
                'AUTHORIZATION': 'Bearer abc',
                'apiKey': 'k',
                'secret': 's',
              })!
              as Map;

      expect(redacted.values.every((v) => v == '***'), isTrue);
    });

    test('walks into lists, as the staff list response requires', () {
      final redacted =
          redactSecretsForLog({
                'data': [
                  {'id': '1', 'password': 'hash-one'},
                  {'id': '2', 'password': 'hash-two'},
                ],
              })!
              as Map;

      final items = (redacted['data'] as List).cast<Map>();
      expect(items.map((e) => e['password']), ['***', '***']);
      expect(items.map((e) => e['id']), ['1', '2']);
      expect(jsonEncode(redacted), isNot(contains('hash-')));
    });

    test('passes scalars and null through unchanged', () {
      expect(redactSecretsForLog(null), isNull);
      expect(redactSecretsForLog('plain'), 'plain');
      expect(redactSecretsForLog(42), 42);
    });
  });
}
