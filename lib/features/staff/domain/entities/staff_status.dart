/// Account state of a staff member.
///
/// Set entirely by the backend. Neither the create nor the update endpoint
/// accepts a status, and deleting a staff member is a soft delete that sets
/// [inactive] — there is no endpoint that restores [active], so the mobile app
/// only ever reads this.
enum StaffStatus {
  active('active'),
  inactive('inactive'),

  /// A status this build does not recognise. See [StaffRole.unknown].
  unknown('');

  const StaffStatus(this.apiValue);

  final String apiValue;

  static StaffStatus fromApi(String? value) {
    if (value == null) return unknown;
    final normalised = value.trim().toLowerCase();
    for (final status in values) {
      if (status != unknown && status.apiValue == normalised) return status;
    }
    return unknown;
  }

  bool get isKnown => this != unknown;
}
