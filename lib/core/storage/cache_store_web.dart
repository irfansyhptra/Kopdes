import 'dart:convert';

import 'package:web/web.dart' as web;

import 'cache_store_contract.dart';

CacheStoreBackend createCacheStore() => _WebCacheStore();

class _WebCacheStore implements CacheStoreBackend {
  static const _prefix = 'komit.api-cache.';

  String _storageKey(String key) => '$_prefix${Uri.encodeComponent(key)}';

  @override
  Future<CacheStoreRecord?> read(String key) async {
    final raw = web.window.localStorage.getItem(_storageKey(key));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final payload = json['payload'] as String?;
      final cachedAt = DateTime.tryParse('${json['cachedAt']}');
      if (payload == null || cachedAt == null) return null;
      return CacheStoreRecord(payload: payload, cachedAt: cachedAt);
    } catch (_) {
      await invalidate(key);
      return null;
    }
  }

  @override
  Future<void> write(String key, String payload, DateTime cachedAt) async {
    web.window.localStorage.setItem(
      _storageKey(key),
      jsonEncode({'payload': payload, 'cachedAt': cachedAt.toIso8601String()}),
    );
  }

  @override
  Future<void> invalidate(String key) async {
    web.window.localStorage.removeItem(_storageKey(key));
  }

  @override
  Future<void> invalidatePrefix(String prefix) async {
    final keys = <String>[];
    for (var index = 0; index < web.window.localStorage.length; index++) {
      final storageKey = web.window.localStorage.key(index);
      if (storageKey == null || !storageKey.startsWith(_prefix)) continue;
      final encoded = storageKey.substring(_prefix.length);
      if (Uri.decodeComponent(encoded).startsWith(prefix)) keys.add(storageKey);
    }
    for (final key in keys) {
      web.window.localStorage.removeItem(key);
    }
  }
}
