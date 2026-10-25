import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/core/storage/app_flags.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('a fresh install has not seen the intro', () async {
    expect(await AppFlags().introSeen(), isFalse);
  });

  test('once marked, the intro stays seen (also for a new AppFlags, i.e. the next launch)', () async {
    await AppFlags().markIntroSeen();
    expect(await AppFlags().introSeen(), isTrue);
  });
}
