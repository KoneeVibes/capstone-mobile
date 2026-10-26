import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/legal/domain/legal_document.dart';

void main() {
  // The assets were converted from a PDF. The markdown renderer prints raw
  // HTML as text, and a lone number is a page number the conversion left in.
  for (final document in LegalDocument.values) {
    test('${document.name} is clean markdown', () {
      final text = File(document.asset).readAsStringSync();

      expect(text, isNotEmpty);
      expect(RegExp('<[a-z/][^>]*>').hasMatch(text), isFalse);
      expect(RegExp(r'^\s*\d+\s*$', multiLine: true).hasMatch(text), isFalse);
    });
  }
}
