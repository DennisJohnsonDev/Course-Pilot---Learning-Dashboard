import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/settings_store.dart';

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// Follows the system until the user picks a side, then remembers it.
class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final saved = ref.read(settingsStoreProvider).read(_key);
    return ThemeMode.values.asNameMap()[saved] ?? ThemeMode.system;
  }

  void toggle(Brightness current) {
    state = current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    unawaited(ref.read(settingsStoreProvider).write(_key, state.name));
  }
}
