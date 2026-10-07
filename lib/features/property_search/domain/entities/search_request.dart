import 'package:equatable/equatable.dart';

import '../../../../core/utils/media_picker.dart';
import 'property_location.dart';
import 'search_options.dart';

/// A complete property search, ready for `POST /case`.
class SearchRequest extends Equatable {
  const SearchRequest({
    required this.applicantName,
    required this.applicantEmail,
    required this.applicantPhone,
    required this.location,
    required this.address,
    required this.propertyClass,
    required this.titleTypes,
    required this.purposes,
    required this.surveyPlans,
    required this.titleDocuments,
  });

  final String applicantName;
  final String applicantEmail;
  final String applicantPhone;
  final PropertyLocation location;
  final String address;
  final PropertyClass propertyClass;
  final Set<TitleType> titleTypes;
  final Set<InquiryPurpose> purposes;
  final List<PickedMedia> surveyPlans;
  final List<PickedMedia> titleDocuments;

  @override
  List<Object?> get props => [
    applicantName,
    applicantEmail,
    applicantPhone,
    location,
    address,
    propertyClass,
    titleTypes,
    purposes,
    surveyPlans,
    titleDocuments,
  ];
}

/// What a create returns: the case's public reference and its unpaid invoice.
class SubmittedSearch extends Equatable {
  const SubmittedSearch({required this.trackingId, required this.invoiceId});

  final String trackingId;
  final String invoiceId;

  @override
  List<Object?> get props => [trackingId, invoiceId];
}
