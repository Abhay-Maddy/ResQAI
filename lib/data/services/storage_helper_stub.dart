import 'dart:convert';
import 'dart:io';

// Persistent file & memory storage for non-web environments (mobile, desktop, VM)
class StorageHelper {
  static final Map<String, String> _memoryStorage = {};
  static bool _loaded = false;
  static File? _storageFile;

  static void _ensureLoaded() {
    if (_loaded) return;
    _loaded = true;
    try {
      final dir = Directory.systemTemp;
      _storageFile = File('${dir.path}/resqai_local_storage.json');
      if (_storageFile!.existsSync()) {
        final content = _storageFile!.readAsStringSync();
        final map = jsonDecode(content) as Map<String, dynamic>;
        map.forEach((k, v) => _memoryStorage[k] = v.toString());
      }
    } catch (_) {}
  }

  static void _save() {
    try {
      if (_storageFile != null) {
        _storageFile!.writeAsStringSync(jsonEncode(_memoryStorage), flush: true);
      }
    } catch (_) {}
  }

  static String? getItem(String key) {
    _ensureLoaded();
    return _memoryStorage[key];
  }

  static void setItem(String key, String value) {
    _ensureLoaded();
    _memoryStorage[key] = value;
    _save();
  }

  static void removeItem(String key) {
    _ensureLoaded();
    _memoryStorage.remove(key);
    _save();
  }

  static void clear() {
    _memoryStorage.clear();
    _save();
  }
}
