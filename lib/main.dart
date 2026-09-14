import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/injection_container.dart' as di;
import 'core/network/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  final isAuthenticated = di.sl<ApiClient>().isAuthenticated;
  runApp(ScanrixApp(isAuthenticated: isAuthenticated));
}

