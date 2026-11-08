import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The signed-in user's first name, or null until their profile has loaded.
///
/// A seam like `sessionProvider`: core declares it empty, and the profile
/// feature fills it at the composition root (`profileOverrides`), so the
/// dashboard can greet by name without importing profile (ADR 0030).
final signedInFirstNameProvider = Provider<String?>((ref) => null);
