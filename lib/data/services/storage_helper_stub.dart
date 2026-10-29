import 'dart:convert';
import 'dart:io';

// Persistent file & memory storage for non-web environments (mobile, desktop, VM)
class StorageHelper {
  static final Map<String, String> _memoryStorage = {};
  static bool _loaded = false;
  static File? _storageFile;

  static File _resolveStorageFile() {
    // 1. Android internal persistent files directory
    final androidCandidates = [
      Directory('/data/user/0/com.example.resqai/files'),
      Directory('/data/data/com.example.resqai/files'),
      Directory('/data/user/0/com.resqai.app/files'),
      Directory('/data/data/com.resqai.app/files'),
    ];
    for (final d in androidCandidates) {
      try {
        if (d.existsSync()) {
          return File('${d.path}/resqai_local_storage.json');
        }
      } catch (_) {}
    }

    // 2. Desktop / VM user home directory
    try {
      final homeDir = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      if (homeDir != null && homeDir.isNotEmpty) {
        final dir = Directory('$homeDir/.resqai');
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        return File('${dir.path}/resqai_local_storage.json');
      }
    } catch (_) {}

    // 3. Fallback to system temp directory
    return File('${Directory.systemTemp.path}/resqai_local_storage.json');
  }

  static void _ensureLoaded() {
    if (_loaded) return;
    _loaded = true;
    try {
      _storageFile = _resolveStorageFile();
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
    _ensureLoaded();
    _memoryStorage.clear();
    _save();
    try {
      if (_storageFile != null && _storageFile!.existsSync()) {
        _storageFile!.deleteSync();
      }
    } catch (_) {}
  }
}
