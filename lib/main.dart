import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'app.dart';
import 'core/storage/cache_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  final cacheStore = await CacheStore.open();

  runApp(
    ProviderScope(
      overrides: [cacheStoreProvider.overrideWithValue(cacheStore)],
      child: const CoursePilotApp(),
    ),
  );
}
