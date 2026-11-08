import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The signed-in user's first name, or null until their profile has loaded.
///
/// A seam like `sessionProvider`: core declares it empty, and the profile
/// feature fills it at the composition root (`profileOverrides`), so the
/// dashboard can greet by name without importing profile (ADR 0030).
final signedInFirstNameProvider = Provider.autoDispose<String?>((ref) => null);

/// The signed-in user's full name, or null until their profile has loaded.
/// The property search locks a client's applicant name to it.
final signedInFullNameProvider = Provider.autoDispose<String?>((ref) => null);

/// The signed-in user's phone, or null until their profile has loaded (or when
/// it has none). The property search prefills a client's applicant phone.
final signedInPhoneProvider = Provider.autoDispose<String?>((ref) => null);
