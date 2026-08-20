/// In-memory cache with TTL support.
class Cache {
  Cache();

  final Map<String, _Entry> _store = {};

  T? get<T>(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (entry.expiresAt != null && DateTime.now().isAfter(entry.expiresAt!)) {
      _store.remove(key);
      return null;
    }
    return entry.value as T;
  }

  void set(String key, dynamic value, {Duration? ttl}) {
    _store[key] = _Entry(
      value,
      ttl != null ? DateTime.now().add(ttl) : null,
    );
  }

  void delete(String key) => _store.remove(key);

  void clear() => _store.clear();

  bool has(String key) => get(key) != null;
}

class _Entry {
  _Entry(this.value, this.expiresAt);
  final dynamic value;
  final DateTime? expiresAt;
}

/// Memoize async function results.
Future<T> cached<T>(Cache cache, String key, Future<T> Function() fn,
    {Duration? ttl}) async {
  final hit = cache.get<T>(key);
  if (hit != null) return hit;
  final result = await fn();
  cache.set(key, result, ttl: ttl);
  return result;
}
