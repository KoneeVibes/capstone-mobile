/// The roles the API recognises.
///
/// Lives in core because the session, the router and more than one feature
/// read it. The backend is the source of truth; the role names in the original
/// designs (Administrator, Property Agent, Legal Reviewer, Support Agent) do
/// not exist server-side and are not used.
enum StaffRole {
  superAdmin('super-admin'),
  admin('admin'),
  manager('manager'),
  regular('regular'),

  /// A role the API returned that this build does not know about.
  ///
  /// Kept so one unrecognised record cannot break the whole list. It is never
  /// offered as a choice, never sent back to the server, and grants nothing.
  unknown('');

  const StaffRole(this.apiValue);

  /// The exact string the API expects and returns.
  final String apiValue;

  /// Parses an API value, falling back to [unknown] rather than throwing.
  static StaffRole fromApi(String? value) {
    if (value == null) return unknown;
    final normalised = value.trim().toLowerCase();
    for (final role in values) {
      if (role != unknown && role.apiValue == normalised) return role;
    }
    return unknown;
  }

  /// The roles a user may pick in the form. Super-admin is granted outside
  /// the app, so it is shown on a record that has it but never offered.
  static List<StaffRole> get assignable =>
      values.where((role) => role.isAssignable).toList();

  bool get isKnown => this != unknown;

  bool get isAssignable => this != unknown && this != superAdmin;
}
