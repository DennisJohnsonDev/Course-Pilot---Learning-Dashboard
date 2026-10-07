import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'app.dart';
import 'core/network/mock/mock_routes.dart';
import 'core/storage/cache_store.dart';
import 'features/auth/data/auth_mock_routes.dart';
import 'features/auth/presentation/session_controller.dart';
import 'features/courses/data/course_mock_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  final cacheStore = await CacheStore.open();
  final courseMockStorage = await Hive.openBox<bool>(courseMockStorageBox);

  final container = ProviderContainer(
    overrides: [
      cacheStoreProvider.overrideWithValue(cacheStore),
      mockRoutesProvider.overrideWithValue([
        ...authMockRoutes,
        ...courseMockRoutes(storage: courseMockStorage),
      ]),
    ],
  );
  await container.read(sessionControllerProvider.notifier).restore();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CoursePilotApp(),
    ),
  );
}
