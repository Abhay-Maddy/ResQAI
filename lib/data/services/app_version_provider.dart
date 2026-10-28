import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import 'storage_service.dart';

class AppVersionNotifier extends StateNotifier<String> {
  AppVersionNotifier() : super(_loadInitialVersion());

  static String _loadInitialVersion() {
    try {
      final saved = StorageService.getString(StorageService.keyInstalledAppVersion);
      if (saved != null && saved.trim().isNotEmpty) {
        return saved.trim();
      }
    } catch (_) {}
    return AppConstants.appVersion;
  }

  void updateVersion(String newVersion) {
    try {
      StorageService.setString(StorageService.keyInstalledAppVersion, newVersion);
    } catch (_) {}
    state = newVersion;
  }
}

final appVersionProvider = StateNotifierProvider<AppVersionNotifier, String>((ref) {
  return AppVersionNotifier();
});

