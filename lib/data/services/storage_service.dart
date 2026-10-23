import 'storage_helper_stub.dart'
    if (dart.library.html) 'storage_helper_web.dart';

class StorageService {
  static const String keyCurrentUser = 'resqai_user_session';
  static const String keyActiveRole = 'resqai_active_role';
  static const String keySelectedDistrict = 'resqai_district';
  static const String keyLanguage = 'resqai_language';
  static const String keyTheme = 'resqai_theme';
  static const String keyPendingRegistrations = 'resqai_pending_regs';

  static String? getString(String key) {
    return StorageHelper.getItem(key);
  }

  static void setString(String key, String value) {
    StorageHelper.setItem(key, value);
  }

  static void remove(String key) {
    StorageHelper.removeItem(key);
  }

  static void clear() {
    StorageHelper.clear();
  }
}
