import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/injection_container.dart' as di;
import 'features/splash/presentation/pages/splash_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Only what the app's first frame needs; SplashPage does the rest of the
  // startup (.env, DI, start-page check) while its animation plays.
  di.registerEarly();
  runApp(const ScanrixApp(home: SplashPage()));
}
