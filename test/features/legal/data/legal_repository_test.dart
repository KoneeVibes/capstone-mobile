import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/utils/error/app_failure.dart';
import 'package:propertyintelmobileapp/core/utils/result.dart';
import 'package:propertyintelmobileapp/features/legal/data/legal_repository.dart';
import 'package:propertyintelmobileapp/features/legal/domain/legal_document.dart';

class MockAssetBundle extends Mock implements AssetBundle {}

void main() {
  late MockAssetBundle bundle;
  late LegalRepository repository;

  setUp(() {
    bundle = MockAssetBundle();
    repository = LegalRepository(bundle);
  });

  test('reads the document from its asset', () async {
    when(
      () => bundle.loadString('assets/legal/terms.md'),
    ).thenAnswer((_) async => '# Terms');

    final result = await repository.read(LegalDocument.terms);

    expect(result, isA<Ok<String>>());
    expect(result.valueOrNull, '# Terms');
  });

  test('turns a missing asset into a failure', () async {
    when(
      () => bundle.loadString(any()),
    ).thenThrow(FlutterError('Unable to load asset'));

    final result = await repository.read(LegalDocument.privacyPolicy);

    expect(result.failureOrNull, isA<AppFailure>());
  });
}
