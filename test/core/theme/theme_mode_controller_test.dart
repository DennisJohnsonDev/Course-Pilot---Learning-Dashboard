import 'dart:io';

import 'package:course_pilot/core/storage/settings_store.dart';
import 'package:course_pilot/core/theme/theme_mode_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory hiveDirectory;
  late SettingsStore settingsStore;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('settings');
    Hive.init(hiveDirectory.path);
    settingsStore = await SettingsStore.open();
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  ProviderContainer container() => ProviderContainer(
    overrides: [settingsStoreProvider.overrideWithValue(settingsStore)],
  );

  test('follows the system until toggled', () {
    expect(container().read(themeModeProvider), ThemeMode.system);
  });

  test('toggles away from what is showing and remembers it', () async {
    final first = container();
    first.read(themeModeProvider.notifier).toggle(Brightness.light);
    expect(first.read(themeModeProvider), ThemeMode.dark);

    await Future<void>.delayed(Duration.zero);
    expect(container().read(themeModeProvider), ThemeMode.dark);

    first.read(themeModeProvider.notifier).toggle(Brightness.dark);
    expect(first.read(themeModeProvider), ThemeMode.light);
  });
}
