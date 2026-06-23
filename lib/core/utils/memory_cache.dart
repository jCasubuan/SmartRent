/// Simple in-memory cache with time-to-live (TTL).
/// Stores data for a configurable duration before expiring.
/// Used to avoid repeated Firestore reads for data that rarely changes.
class MemoryCache<T> {
  final Duration ttl;
  T? _data;
  DateTime? _cachedAt;

  MemoryCache({this.ttl = const Duration(minutes: 5)});

  /// Returns cached data if still valid, otherwise null.
  T? get() {
    if (_data == null || _cachedAt == null) return null;
    if (DateTime.now().difference(_cachedAt!) > ttl) {
      _data = null;
      _cachedAt = null;
      return null;
    }
    return _data;
  }

  /// Stores data with current timestamp.
  void set(T data) {
    _data = data;
    _cachedAt = DateTime.now();
  }

  /// Clears the cache immediately.
  void clear() {
    _data = null;
    _cachedAt = null;
  }

  /// Whether the cache has valid (non-expired) data.
  bool get isValid =>
      _data != null &&
      _cachedAt != null &&
      DateTime.now().difference(_cachedAt!) <= ttl;
}
