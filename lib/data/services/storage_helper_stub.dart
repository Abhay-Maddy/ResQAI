// Fallback memory storage for non-web environments (such as VM unit tests)
class StorageHelper {
  static final Map<String, String> _memoryStorage = {};

  static String? getItem(String key) {
    return _memoryStorage[key];
  }

  static void setItem(String key, String value) {
    _memoryStorage[key] = value;
  }

  static void removeItem(String key) {
    _memoryStorage.remove(key);
  }

  static void clear() {
    _memoryStorage.clear();
  }
}
