class CacheStoreRecord {
  final String payload;
  final DateTime cachedAt;

  const CacheStoreRecord({required this.payload, required this.cachedAt});
}

abstract class CacheStoreBackend {
  Future<CacheStoreRecord?> read(String key);
  Future<void> write(String key, String payload, DateTime cachedAt);
  Future<void> invalidate(String key);
  Future<void> invalidatePrefix(String prefix);
}
