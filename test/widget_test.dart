import 'package:flutter_test/flutter_test.dart';

import 'package:scanrix_frontend/app.dart';
import 'package:scanrix_frontend/core/di/injection_container.dart' as di;

void main() {
  setUpAll(() async {
    await di.init();
  });

  testWidgets('App builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const ScanrixApp(isAuthenticated: false));
    expect(find.byType(ScanrixApp), findsOneWidget);
  });
}
