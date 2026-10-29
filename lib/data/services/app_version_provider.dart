import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import 'app_update_service.dart';
import 'storage_service.dart';

class AppVersionNotifier extends StateNotifier<String> {
  AppVersionNotifier() : super(_loadInitialVersion());

  static String _loadInitialVersion() {
    try {
      final saved = StorageService.getString(StorageService.keyInstalledAppVersion);
      if (saved != null && saved.trim().isNotEmpty) {
        final trimmed = saved.trim();
        // If the compiled APK binary is newer than the cached version on disk,
        // automatically promote to the binary version and persist.
        if (AppUpdateService.compareVersions(AppConstants.appVersion, trimmed) > 0) {
          StorageService.setString(StorageService.keyInstalledAppVersion, AppConstants.appVersion);
          return AppConstants.appVersion;
        }
        return trimmed;
      }
    } catch (_) {}
    StorageService.setString(StorageService.keyInstalledAppVersion, AppConstants.appVersion);
    return AppConstants.appVersion;
  }

  void updateVersion(String newVersion) {
    try {
      StorageService.setString(StorageService.keyInstalledAppVersion, newVersion);
    } catch (_) {}
    state = newVersion;
  }

  void resetVersion(String version) {
    try {
      StorageService.setString(StorageService.keyInstalledAppVersion, version);
      StorageService.setString(StorageService.keyServerLatestVersion, version);
    } catch (_) {}
    state = version;
  }
}

final appVersionProvider = StateNotifierProvider<AppVersionNotifier, String>((ref) {
  return AppVersionNotifier();
});
