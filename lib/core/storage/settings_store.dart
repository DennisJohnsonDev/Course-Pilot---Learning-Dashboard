import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => throw UnimplementedError('settingsStoreProvider must be overridden'),
);

/// Device preferences. Kept apart from [CacheStore] so signing out keeps them.
class SettingsStore {
  SettingsStore(this._box);

  static const boxName = 'settings';

  static Future<SettingsStore> open() async =>
      SettingsStore(await Hive.openBox<String>(boxName));

  final Box<String> _box;

  String? read(String key) => _box.get(key);

  Future<void> write(String key, String value) => _box.put(key, value);
}
