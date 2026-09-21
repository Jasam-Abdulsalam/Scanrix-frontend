import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const String _storageKey = 'user_theme_mode';
  final FlutterSecureStorage _storage;

  ThemeCubit({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        super(ThemeMode.dark) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      if (saved == 'light') {
        emit(ThemeMode.light);
      } else {
        emit(ThemeMode.dark);
      }
    } catch (_) {
      emit(ThemeMode.dark);
    }
  }

  Future<void> setTheme(bool isDark) async {
    final mode = isDark ? ThemeMode.dark : ThemeMode.light;
    emit(mode);
    try {
      await _storage.write(
        key: _storageKey,
        value: isDark ? 'dark' : 'light',
      );
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    await setTheme(state != ThemeMode.dark);
  }

  bool get isDarkMode => state == ThemeMode.dark;
}
