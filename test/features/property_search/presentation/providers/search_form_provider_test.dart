import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/session/cases_changed.dart';
import 'package:propertyintelmobileapp/core/utils/error/app_failure.dart';
import 'package:propertyintelmobileapp/core/utils/error/app_failures.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';
import 'package:propertyintelmobileapp/core/utils/media_picker.dart';
import 'package:propertyintelmobileapp/core/utils/result.dart';
import 'package:propertyintelmobileapp/features/property_search/domain/entities/search_options.dart';
import 'package:propertyintelmobileapp/features/property_search/domain/entities/search_request.dart';
import 'package:propertyintelmobileapp/features/property_search/domain/repositories/property_search_repository.dart';
import 'package:propertyintelmobileapp/features/property_search/presentation/providers/property_search_providers.dart';
import 'package:propertyintelmobileapp/features/property_search/presentation/providers/search_form_provider.dart';

import '../../property_search_fixtures.dart';

class MockRepository extends Mock implements PropertySearchRepository {}

class FakeBackend implements MediaPickerBackend {
  List<RawPickedFile> files = const [];
  Set<String>? lastAllowed;

  @override
  Future<RawPickedFile?> pickImage() async => null;

  @override
  Future<List<RawPickedFile>> pickFiles({
    required Set<String> allowedExtensions,
    required bool allowMultiple,
  }) async {
    lastAllowed = allowedExtensions;
    return files;
  }
}

const _created = SubmittedSearch(trackingId: 'PI-DU2964LK', invoiceId: 'inv');

void main() {
  late MockRepository repository;
  late FakeBackend backend;
  late ProviderContainer container;

  setUpAll(() => registerFallbackValue(searchRequestFallback));

  setUp(() async {
    repository = MockRepository();
    backend = FakeBackend();
    container = ProviderContainer(
      overrides: [
        propertySearchRepositoryProvider.overrideWithValue(repository),
        mediaPickerProvider.overrideWithValue(MediaPicker(backend)),
        propertyLocationsProvider.overrideWith((ref) async => locations),
      ],
    );
    addTearDown(container.dispose);
    // Keeps the auto-dispose form alive between reads.
    container.listen(searchFormProvider, (_, _) {});
    await container.read(propertyLocationsProvider.future);
  });

  SearchFormNotifier form() => container.read(searchFormProvider.notifier);
  SearchFormState state() => container.read(searchFormProvider);

  Future<Result<SubmittedSearch>?> submit({bool textValid = true}) =>
      form().submit(
        textValid: textValid,
        applicantName: 'Zz Throwaway',
        applicantEmail: 'pi.qa@yopmail.com',
        applicantPhone: '08034112290',
        address: '1 Test Street',
      );

  Future<void> fillEverything() async {
    form()
      ..selectState('Lagos')
      ..selectLga('Ikeja')
      ..selectCity('Ikeja')
      ..selectClass(PropertyClass.land)
      ..toggleTitle(TitleType.certificateOfOccupancy)
      ..togglePurpose(InquiryPurpose.dueDiligence);
    backend.files = const [
      RawPickedFile(path: '/f/plan.pdf', name: 'plan.pdf', sizeBytes: 10),
    ];
    await form().pick(SearchDocument.surveyPlan);
    backend.files = const [
      RawPickedFile(path: '/f/deed.jpg', name: 'deed.jpg', sizeBytes: 10),
    ];
    await form().pick(SearchDocument.titleDocument);
  }

  group('location', () {
    test('a new state empties the LGA and city under it', () {
      form()
        ..selectState('Lagos')
        ..selectLga('Ikeja')
        ..selectCity('Ikeja')
        ..selectState('FCT');

      expect(state().state, 'FCT');
      expect(state().lga, isNull);
      expect(state().city, isNull);
    });

    test('a new LGA empties the city only', () {
      form()
        ..selectState('Lagos')
        ..selectLga('Ikeja')
        ..selectCity('Ikeja')
        ..selectLga('Eti-Osa');

      expect(state().state, 'Lagos');
      expect(state().city, isNull);
    });

    test('choosing the same state again keeps the rest', () {
      form()
        ..selectState('Lagos')
        ..selectLga('Ikeja')
        ..selectState('Lagos');

      expect(state().lga, 'Ikeja');
    });
  });

  group('titles', () {
    test('several may be chosen, and tapping again removes one', () {
      form()
        ..toggleTitle(TitleType.certificateOfOccupancy)
        ..toggleTitle(TitleType.deedOfAssignment)
        ..toggleTitle(TitleType.certificateOfOccupancy);

      expect(state().titleTypes, {TitleType.deedOfAssignment});
    });

    test('"Not sure" clears the others, and any other clears it', () {
      form()
        ..toggleTitle(TitleType.certificateOfOccupancy)
        ..toggleTitle(TitleType.notSure);
      expect(state().titleTypes, {TitleType.notSure});

      form().toggleTitle(TitleType.powerOfAttorney);
      expect(state().titleTypes, {TitleType.powerOfAttorney});
    });
  });

  group('documents', () {
    test('asks only for what the create accepts, and skips a repeat', () async {
      backend.files = const [
        RawPickedFile(path: '/f/a.pdf', name: 'a.pdf', sizeBytes: 10),
      ];
      await form().pick(SearchDocument.surveyPlan);
      await form().pick(SearchDocument.surveyPlan);

      expect(backend.lastAllowed, {'pdf', 'jpg', 'jpeg', 'png'});
      expect(state().surveyPlans, hasLength(1));
      expect(state().titleDocuments, isEmpty);
    });

    test('hands back a picker failure and keeps what was there', () async {
      backend.files = const [
        RawPickedFile(path: '/f/a.docx', name: 'a.docx', sizeBytes: 10),
      ];

      final failure = await form().pick(SearchDocument.titleDocument);

      expect(failure, AppFailures.unsupportedDocumentType);
      expect(state().titleDocuments, isEmpty);
    });

    test('removes one file', () async {
      backend.files = const [
        RawPickedFile(path: '/f/a.pdf', name: 'a.pdf', sizeBytes: 10),
        RawPickedFile(path: '/f/b.pdf', name: 'b.pdf', sizeBytes: 10),
      ];
      await form().pick(SearchDocument.surveyPlan);

      form().remove(SearchDocument.surveyPlan, state().surveyPlans.first);

      expect(state().surveyPlans.single.fileName, 'b.pdf');
    });
  });

  group('submit', () {
    test(
      'sends nothing and flags the form while a choice is missing',
      () async {
        expect(await submit(), isNull);

        expect(state().showErrors, isTrue);
        verifyNever(() => repository.submit(any()));
      },
    );

    test('sends nothing while a typed field is invalid', () async {
      await fillEverything();

      expect(await submit(textValid: false), isNull);
      verifyNever(() => repository.submit(any()));
    });

    test('files the search with the priced location', () async {
      await fillEverything();
      when(
        () => repository.submit(any()),
      ).thenAnswer((_) async => const Ok(_created));

      final result = await submit();

      expect(result?.valueOrNull, _created);
      final sent =
          verify(() => repository.submit(captureAny())).captured.single
              as SearchRequest;
      expect(sent.location, ikeja);
      expect(sent.titleTypes, {TitleType.certificateOfOccupancy});
      expect(sent.surveyPlans.single.fileName, 'plan.pdf');
      expect(state().isSubmitting, isFalse);
      // Home's counts and the Cases list reload.
      expect(container.read(casesChangedProvider), 1);
    });

    test('returns the failure and is ready to try again', () async {
      await fillEverything();
      const failure = AppFailure(
        type: FailureType.notFound,
        message: 'No price is configured for the selected location.',
      );
      when(
        () => repository.submit(any()),
      ).thenAnswer((_) async => const Err(failure));

      expect((await submit())?.failureOrNull, failure);
      expect(state().isSubmitting, isFalse);
      expect(container.read(casesChangedProvider), 0);
    });
  });
}

const searchRequestFallback = SearchRequest(
  applicantName: '',
  applicantEmail: '',
  applicantPhone: '',
  location: ikeja,
  address: '',
  propertyClass: PropertyClass.land,
  titleTypes: {},
  purposes: {},
  surveyPlans: [],
  titleDocuments: [],
);
