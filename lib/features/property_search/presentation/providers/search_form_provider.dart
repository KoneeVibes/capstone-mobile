import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/session/cases_changed.dart';
import '../../../../core/utils/error/app_failure.dart';
import '../../../../core/utils/media_picker.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/property_location.dart';
import '../../domain/entities/search_options.dart';
import '../../domain/entities/search_request.dart';
import 'property_search_providers.dart';

/// Which upload a file belongs to.
enum SearchDocument { surveyPlan, titleDocument }

/// Everything on the search form that is not typed text; the screen owns the
/// text controllers.
class SearchFormState extends Equatable {
  const SearchFormState({
    this.state,
    this.lga,
    this.city,
    this.propertyClass,
    this.titleTypes = const {},
    this.purposes = const {},
    this.surveyPlans = const [],
    this.titleDocuments = const [],
    this.showErrors = false,
    this.isSubmitting = false,
  });

  final String? state;
  final String? lga;
  final String? city;
  final PropertyClass? propertyClass;
  final Set<TitleType> titleTypes;
  final Set<InquiryPurpose> purposes;
  final List<PickedMedia> surveyPlans;
  final List<PickedMedia> titleDocuments;

  /// Set by the first submit attempt, so untouched sections are not flagged
  /// before the user has tried.
  final bool showErrors;
  final bool isSubmitting;

  bool get hasLocation => state != null && lga != null && city != null;

  List<PickedMedia> filesFor(SearchDocument kind) => switch (kind) {
    SearchDocument.surveyPlan => surveyPlans,
    SearchDocument.titleDocument => titleDocuments,
  };

  /// Every choice the API requires has been made.
  bool get isComplete =>
      hasLocation &&
      propertyClass != null &&
      titleTypes.isNotEmpty &&
      purposes.isNotEmpty &&
      surveyPlans.isNotEmpty &&
      titleDocuments.isNotEmpty;

  SearchFormState copyWith({
    String? Function()? state,
    String? Function()? lga,
    String? Function()? city,
    PropertyClass? propertyClass,
    Set<TitleType>? titleTypes,
    Set<InquiryPurpose>? purposes,
    List<PickedMedia>? surveyPlans,
    List<PickedMedia>? titleDocuments,
    bool? showErrors,
    bool? isSubmitting,
  }) => SearchFormState(
    state: state == null ? this.state : state(),
    lga: lga == null ? this.lga : lga(),
    city: city == null ? this.city : city(),
    propertyClass: propertyClass ?? this.propertyClass,
    titleTypes: titleTypes ?? this.titleTypes,
    purposes: purposes ?? this.purposes,
    surveyPlans: surveyPlans ?? this.surveyPlans,
    titleDocuments: titleDocuments ?? this.titleDocuments,
    showErrors: showErrors ?? this.showErrors,
    isSubmitting: isSubmitting ?? this.isSubmitting,
  );

  @override
  List<Object?> get props => [
    state,
    lga,
    city,
    propertyClass,
    titleTypes,
    purposes,
    surveyPlans,
    titleDocuments,
    showErrors,
    isSubmitting,
  ];
}

/// The search form's choices and its submit. Disposed with the screen, so a
/// new search starts blank.
class SearchFormNotifier extends Notifier<SearchFormState> {
  @override
  SearchFormState build() => const SearchFormState();

  /// A new state empties the LGA and city under it, as on the website.
  void selectState(String? value) {
    if (value == state.state) return;
    state = state.copyWith(
      state: () => value,
      lga: () => null,
      city: () => null,
    );
  }

  void selectLga(String? value) {
    if (value == state.lga) return;
    state = state.copyWith(lga: () => value, city: () => null);
  }

  void selectCity(String? value) => state = state.copyWith(city: () => value);

  void selectClass(PropertyClass value) =>
      state = state.copyWith(propertyClass: value);

  /// "Not sure" stands alone: choosing it clears the others, and choosing any
  /// other clears it.
  void toggleTitle(TitleType value) {
    final current = state.titleTypes;
    final Set<TitleType> next;
    if (current.contains(value)) {
      next = {...current}..remove(value);
    } else if (value == TitleType.notSure) {
      next = {TitleType.notSure};
    } else {
      next = {...current.where((type) => type != TitleType.notSure), value};
    }
    state = state.copyWith(titleTypes: next);
  }

  void togglePurpose(InquiryPurpose value) {
    final current = state.purposes;
    state = state.copyWith(
      purposes: current.contains(value)
          ? ({...current}..remove(value))
          : {...current, value},
    );
  }

  /// Adds the picked files to [kind]; a file already there is not added twice.
  /// Returns the failure to show, or null — including when the user backed
  /// out.
  Future<AppFailure?> pick(SearchDocument kind) async {
    final result = await ref
        .read(mediaPickerProvider)
        .pickDocuments(allowedExtensions: AppConstants.caseDocumentExtensions);
    if (!ref.mounted) return null;

    switch (result) {
      case Err(:final failure):
        return failure;
      case Ok(:final value):
        final existing = state.filesFor(kind);
        final paths = existing.map((file) => file.path).toSet();
        _setFiles(kind, [
          ...existing,
          ...value.where((file) => paths.add(file.path)),
        ]);
        return null;
    }
  }

  void remove(SearchDocument kind, PickedMedia file) =>
      _setFiles(kind, [...state.filesFor(kind)]..remove(file));

  void _setFiles(SearchDocument kind, List<PickedMedia> files) =>
      state = switch (kind) {
        SearchDocument.surveyPlan => state.copyWith(surveyPlans: files),
        SearchDocument.titleDocument => state.copyWith(titleDocuments: files),
      };

  /// Files the search. Returns null without a request when a choice is
  /// missing — the form then shows which — or while a submit is running.
  ///
  /// [textValid] is the result of validating the typed fields.
  Future<Result<SubmittedSearch>?> submit({
    required bool textValid,
    required String applicantName,
    required String applicantEmail,
    required String applicantPhone,
    required String address,
  }) async {
    if (state.isSubmitting) return null;
    state = state.copyWith(showErrors: true);

    final location = ref
        .read(propertyLocationsProvider)
        .value
        ?.find(state.state, state.lga, state.city);
    final propertyClass = state.propertyClass;
    if (!textValid ||
        !state.isComplete ||
        location == null ||
        propertyClass == null) {
      return null;
    }

    state = state.copyWith(isSubmitting: true);
    final result = await ref
        .read(propertySearchRepositoryProvider)
        .submit(
          SearchRequest(
            applicantName: applicantName,
            applicantEmail: applicantEmail,
            applicantPhone: applicantPhone,
            location: location,
            address: address,
            propertyClass: propertyClass,
            titleTypes: state.titleTypes,
            purposes: state.purposes,
            surveyPlans: state.surveyPlans,
            titleDocuments: state.titleDocuments,
          ),
        );
    if (result.isOk) ref.read(casesChangedProvider.notifier).bump();
    if (ref.mounted) state = state.copyWith(isSubmitting: false);
    return result;
  }
}

final searchFormProvider =
    NotifierProvider.autoDispose<SearchFormNotifier, SearchFormState>(
      SearchFormNotifier.new,
    );
