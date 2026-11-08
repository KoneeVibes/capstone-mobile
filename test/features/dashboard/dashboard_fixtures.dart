/// `GET /api/v1/case/track/PI-URF8T7C2` as it answered on 23 Sep 2026, with
/// the assignee ids shortened and the fields added by 8 Nov 2026
/// (`propertyAddress`, `assigneeName`).
const trackingJson = <String, dynamic>{
  '_id': '6a959389aa295796b79bbd8b',
  'trackingId': 'PI-URF8T7C2',
  'propertyAddress': '5 Kayode Abraham, Off Ligali Ayorinde',
  'status': 'assigned',
  'statusHistory': [
    {
      'status': 'submitted',
      'changedAt': '2026-08-31T14:45:29.965Z',
      'assigneeId': null,
      'note': 'Case submitted successfully.',
      'assigneeName': null,
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
      'assigneeName': 'Ada Okafor Regular',
    },
    {
      'status': 'assigned',
      'changedAt': '2026-08-31T19:17:38.580Z',
      'assigneeId': 'staff-2',
      'note': null,
      'assigneeName': null,
    },
  ],
  'updatedAt': '2026-08-31T19:17:38.580Z',
};

/// A `GET /search/history` record, as it answered on 8 Nov 2026.
Map<String, dynamic> historyJson({
  String id = '174160f3-a7fa-49d5-b97c-673ec3acba90',
  String query = 'PI-8APCC9W3',
  String updatedAt = '2026-11-08T07:02:57.019Z',
}) => <String, dynamic>{
  'requester': '77718a9e-1420-4b5b-bdca-90892b8dba26',
  'createdAt': '2026-11-08T06:57:59.768Z',
  'flag': ['case'],
  'id': id,
  'query': query,
  'status': 'active',
  'updatedAt': updatedAt,
};
