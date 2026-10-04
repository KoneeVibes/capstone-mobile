import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/auth/presentation/providers/auth_overrides.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait only. Also enforced in the Android manifest and the iOS plist so
  // the app never briefly renders in landscape before this call takes effect.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Auth supplies the session, token and 401 handling to core here, so
  // nothing else has to import it.
  runApp(
    ProviderScope(overrides: authOverrides, child: const PropertyIntelApp()),
  );
}
