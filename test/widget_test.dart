import 'dart:io';

import 'package:course_pilot/app.dart';
import 'package:course_pilot/core/storage/settings_store.dart';
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

  testWidgets('signed-out users land on Login and see validation', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsStoreProvider.overrideWithValue(settingsStore)],
        child: const CoursePilotApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
  });
}
