/// `GET /api/v1/case/track/PI-URF8T7C2` as it answered on 23 Sep 2026, with
/// the assignee ids shortened.
const trackingJson = <String, dynamic>{
  '_id': '6a959389aa295796b79bbd8b',
  'trackingId': 'PI-URF8T7C2',
  'status': 'assigned',
  'statusHistory': [
    {
      'status': 'submitted',
      'changedAt': '2026-08-31T14:45:29.965Z',
      'assigneeId': null,
      'note': 'Case submitted successfully.',
    },
    {
      'status': 'payment-validated',
      'changedAt': '2026-08-31T14:45:50.991Z',
      'assigneeId': null,
      'note': 'Case validated successfully.',
    },
    {
      'status': 'assigned',
      'changedAt': '2026-08-31T17:16:42.436Z',
      'assigneeId': 'staff-1',
      'note': null,
    },
    {
      'status': 'assigned',
      'changedAt': '2026-08-31T19:17:38.580Z',
      'assigneeId': 'staff-2',
      'note': null,
    },
  ],
  'updatedAt': '2026-08-31T19:17:38.580Z',
};

/// A `GET /case` row, trimmed to what the dashboard reads plus some noise.
Map<String, dynamic> caseRowJson({
  String trackingId = 'PI-URF8T7C2',
  String? address = '5 Kayode Abraham, Off Ligali Ayorinde',
}) => <String, dynamic>{
  '_id': '6a959389aa295796b79bbd8b',
  'id': '914ae488-1b1c-4eb8-8798-bc511b175d9f',
  'trackingId': trackingId,
  'propertyAddress': address,
  'propertyCity': 'Victoria Island',
  'propertyState': 'Lagos',
  'status': 'assigned',
};

/// A `GET /staff` row.
Map<String, dynamic> staffRowJson({
  String id = 'staff-1',
  String firstName = 'Ada',
  String lastName = 'Okafor',
}) => <String, dynamic>{
  '_id': 'mongo-$id',
  'id': id,
  'firstName': firstName,
  'middleName': '',
  'lastName': lastName,
  'status': 'active',
};
