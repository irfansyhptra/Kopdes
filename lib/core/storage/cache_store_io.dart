import 'package:isar/isar.dart';

import 'cache_store_contract.dart';
import 'isar_service.dart';
import 'models/cached_response.dart';

CacheStoreBackend createCacheStore() => _IsarCacheStore();

class _IsarCacheStore implements CacheStoreBackend {
  static final Map<String, CacheStoreRecord> _memory = {};

  Isar? get _isar => IsarService.instanceOrNull;

  @override
  Future<CacheStoreRecord?> read(String key) async {
    final isar = _isar;
    if (isar == null) return _memory[key];
    final row = await isar.cachedResponses.where().keyEqualTo(key).findFirst();
    if (row == null) return null;
    return CacheStoreRecord(payload: row.payload, cachedAt: row.cachedAt);
  }

  @override
  Future<void> write(String key, String payload, DateTime cachedAt) async {
    final isar = _isar;
    if (isar == null) {
      _memory[key] = CacheStoreRecord(payload: payload, cachedAt: cachedAt);
      return;
    }
    final row = CachedResponse()
      ..key = key
      ..payload = payload
      ..cachedAt = cachedAt;
    await isar.writeTxn(() => isar.cachedResponses.put(row));
  }

  @override
  Future<void> invalidate(String key) async {
    final isar = _isar;
    if (isar == null) {
      _memory.remove(key);
      return;
    }
    await isar.writeTxn(
      () => isar.cachedResponses.where().keyEqualTo(key).deleteAll(),
    );
  }

  @override
  Future<void> invalidatePrefix(String prefix) async {
    final isar = _isar;
    if (isar == null) {
      _memory.removeWhere((key, _) => key.startsWith(prefix));
      return;
    }
    await isar.writeTxn(
      () => isar.cachedResponses.filter().keyStartsWith(prefix).deleteAll(),
    );
  }
}
