import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

final cacheStoreProvider = Provider<CacheStore>(
  (ref) => throw UnimplementedError('cacheStoreProvider must be overridden'),
);

class CacheEntry {
  const CacheEntry({required this.data, required this.savedAt});

  final Object? data;
  final DateTime savedAt;
}

/// Persists API payloads as JSON so features can serve them while offline.
class CacheStore {
  CacheStore(this._box);

  static const boxName = 'api_cache';

  static Future<CacheStore> open() async =>
      CacheStore(await Hive.openBox<String>(boxName));

  final Box<String> _box;

  Future<void> write(String key, Object? data) {
    final entry = {'savedAt': DateTime.now().toIso8601String(), 'data': data};
    return _box.put(key, jsonEncode(entry));
  }

  /// Returns null on a miss or when the stored entry is unreadable.
  CacheEntry? read(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;

    try {
      final entry = jsonDecode(raw) as Map<String, Object?>;
      return CacheEntry(
        data: entry['data'],
        savedAt: DateTime.parse(entry['savedAt']! as String),
      );
    } on Object {
      return null;
    }
  }

  Future<void> remove(String key) => _box.delete(key);

  Future<void> clear() => _box.clear();
}
