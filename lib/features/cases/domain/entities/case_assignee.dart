import 'package:equatable/equatable.dart';

import '../../../../core/formatting/app_formatters.dart';

/// A team member a case can be given to.
///
/// Deliberately not the staff feature's `Staff`: features do not import each
/// other, and assignment needs only a name and a face. The duplication is one
/// small entity and one fetch, which is cheaper than coupling two features or
/// pushing domain data into `shared/`.
class CaseAssignee extends Equatable {
  const CaseAssignee({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;

  String get fullName => AppFormatters.fullName(firstName, null, lastName);

  String get initials => AppFormatters.initials(firstName, lastName);

  @override
  List<Object?> get props => [id, firstName, lastName, avatarUrl];
}
