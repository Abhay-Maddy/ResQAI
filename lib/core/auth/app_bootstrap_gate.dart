import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../router/app_router.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/incident_repository.dart';
import '../../data/services/app_update_service.dart';
import '../../data/services/storage_service.dart';
import '../../shared/models/user_model.dart';

class AppBootstrapGate extends ConsumerStatefulWidget {
  const AppBootstrapGate({super.key});

  @override
  ConsumerState<AppBootstrapGate> createState() => _AppBootstrapGateState();
}

class _AppBootstrapGateState extends ConsumerState<AppBootstrapGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    // 1. Authoritative version sync: if binary is newer than stored version, upgrade
    try {
      final savedVersion = StorageService.getString(StorageService.keyInstalledAppVersion);
      if (savedVersion == null ||
          savedVersion.isEmpty ||
          AppUpdateService.compareVersions(AppConstants.appVersion, savedVersion) > 0) {
        StorageService.setString(StorageService.keyInstalledAppVersion, AppConstants.appVersion);
      }
    } catch (_) {}

    // 2. Read stored user session
    UserModel? user;
    try {
      final userJson = StorageService.getString(StorageService.keyCurrentUser);
      if (userJson != null && userJson.isNotEmpty) {
        user = UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      }
    } catch (_) {}

    if (!mounted) return;

    if (user != null) {
      // Restore authenticated user and active role
      ref.read(authProvider.notifier).setUser(user);
      ref.read(activeRoleProvider.notifier).state = user.role;
      StorageService.setString(StorageService.keyActiveRole, user.role.name);

      final targetRoute = AppRouter.getHomeRouteForRole(user.role);
      Navigator.pushReplacementNamed(context, targetRoute);
    } else {
      // Guest / unauthenticated state: safe citizen default, route to home
      ref.read(activeRoleProvider.notifier).state = UserRole.citizen;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.deepNavy : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield,
                size: 64,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: isDark ? Colors.white : AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppConstants.appFullName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
