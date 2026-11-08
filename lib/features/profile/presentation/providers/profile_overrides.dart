import 'package:flutter_riverpod/misc.dart';

import '../../../../core/session/signed_in_name.dart';
import 'profile_provider.dart';

/// Fills core's profile seam at the composition root (`main.dart`), so the
/// dashboard greets by name without importing this feature.
final List<Override> profileOverrides = [
  signedInFirstNameProvider.overrideWith(
    (ref) => ref.watch(profileProvider).value?.firstName,
  ),
];
