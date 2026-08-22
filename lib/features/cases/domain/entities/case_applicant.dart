import 'package:equatable/equatable.dart';

import '../../../../core/formatting/app_formatters.dart';

/// The person who raised a case.
///
/// The API sends one `applicantName` string rather than name parts, and carries
/// no applicant id or avatar — an applicant is not a user account. So this
/// holds the name whole and derives initials from it, rather than pretending to
/// a structure the wire does not have.
class CaseApplicant extends Equatable {
  const CaseApplicant({required this.name, this.email, this.phone});

  final String name;
  final String? email;
  final String? phone;

  /// `Ofofonono Okon Umoren` -> `OU`.
  ///
  /// First and last word, skipping anything between: initials built from the
  /// first two words would give a middle name's letter, which is not how a
  /// person's initials read.
  String get initials {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '';
    return AppFormatters.initials(
      words.first,
      words.length > 1 ? words.last : null,
    );
  }

  @override
  List<Object?> get props => [name, email, phone];
}
