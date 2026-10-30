import 'package:propertyintelmobileapp/core/navigation/app_session.dart';

/// Someone signed in: providers of one user's data fetch nothing without one.
final signedIn = sessionProvider.overrideWithValue(
  const SessionUser(id: 'user-1', role: AppRole.staff),
);
