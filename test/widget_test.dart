import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scanrix_frontend/app.dart';
import 'package:scanrix_frontend/core/di/injection_container.dart' as di;
import 'package:scanrix_frontend/features/auth/presentation/pages/login_page.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // di.init() -> ApiClient.loadPersistedToken() -> TokenStorage reads
    // from flutter_secure_storage, which has no platform implementation
    // under plain `flutter test` unless its channel is mocked. Returning
    // null everywhere means "no persisted token", which is the correct
    // behavior for a fresh test environment anyway.
    const secureStorageChannel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async => null);

    // di.init() builds DioClient synchronously, which reads
    // ApiConstants.baseUrl -> dotenv.get('BASE_URL') immediately — needs a
    // loaded env before that, and there's no real .env file to read in a
    // test environment.
    dotenv.testLoad(fileInput: 'BASE_URL=http://localhost:8000/api/v1');
    await di.init();
  });

  testWidgets('App builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const ScanrixApp(home: LoginPage()));
    expect(find.byType(ScanrixApp), findsOneWidget);
  });
}
