import 'package:equatable/equatable.dart';

import '../../../../core/formatting/app_formatters.dart';

/// The property a case is about, and the paperwork filed with it.
///
/// Every field below `type` is optional because the API models them that way;
/// a request raised from a partly filled web form still has to render.
class CaseProperty extends Equatable {
  const CaseProperty({
    required this.type,
    this.address,
    this.city,
    this.lga,
    this.state,
    this.titleTypes = const [],
    this.surveyPlans = const [],
    this.titleDocuments = const [],
  });

  /// The API's own word — `building` or `land`. Left as a string rather than an
  /// enum because nothing branches on it; it is only ever displayed, so a value
  /// the backend adds tomorrow renders correctly today.
  final String type;

  final String? address;
  final String? city;
  final String? lga;
  final String? state;

  /// `certificate-of-occupancy`, `deed-of-assignment`, and so on.
  final List<String> titleTypes;

  /// Uploaded survey plans, as URLs.
  final List<String> surveyPlans;

  /// Uploaded title documents, as URLs.
  final List<String> titleDocuments;

  /// `Victoria Island, Lagos` — the coarse location, for the list row.
  String get location => _join([city, state]);

  /// `5 Kayode Abraham, Victoria Island, Eti-Osa, Lagos` — the full address,
  /// for the detail screen.
  String get fullAddress => _join([address, city, lga, state]);

  bool get hasDocuments => surveyPlans.isNotEmpty || titleDocuments.isNotEmpty;

  /// `Building` — the type as a label.
  String get typeLabel => AppFormatters.apiLabel(type);

  /// Joins address parts, dropping blanks and anything already said.
  ///
  /// `propertyAddress` is free text from a web form and routinely repeats the
  /// fields beside it — a real record reads `12 Allen Avenue, Ikeja, Lagos`
  /// with `propertyCity: Ikeja`, `propertyLGA: Ikeja` and
  /// `propertyState: Lagos`, which appended naively renders `12 Allen Avenue,
  /// Ikeja, Lagos, Ikeja, Ikeja, Lagos`. Comparing comma-separated segments
  /// rather than whole fields is what lets a city already inside the address be
  /// recognised. A record that does not repeat itself is unaffected.
  static String _join(List<String?> parts) {
    final seen = <String>{};
    final kept = <String>[];

    for (final part in parts) {
      for (final segment in (part ?? '').split(',')) {
        final piece = segment.trim();
        if (piece.isEmpty) continue;
        if (seen.add(piece.toLowerCase())) kept.add(piece);
      }
    }

    return kept.join(', ');
  }

  @override
  List<Object?> get props => [
    type,
    address,
    city,
    lga,
    state,
    titleTypes,
    surveyPlans,
    titleDocuments,
  ];
}
