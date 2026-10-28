import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';
import '../../data/repositories/auth_repository.dart';

class AccessDeniedScreen extends ConsumerWidget {
  final String attemptedPath;
  final String requiredRoleDescription;

  const AccessDeniedScreen({
    super.key,
    required this.attemptedPath,
    required this.requiredRoleDescription,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShell(
      currentRoute: attemptedPath,
      title: 'Access Restricted',
      breadcrumbs: const ['Security', 'Authorization Required'],
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.emergencyRed.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.emergencyRed.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 36,
                      color: AppColors.emergencyRed,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Access Restricted (403)',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You do not possess the required security authorization to view this disaster command module.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface2 : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildRow('Target Route', attemptedPath),
                        const Divider(height: 16),
                        _buildRow(
                          'Current Role',
                          currentUser?.role.title ?? 'Unauthenticated Guest',
                          highlightValue: currentUser?.role.title,
                        ),
                        const Divider(height: 16),
                        _buildRow(
                          'Required Authority',
                          requiredRoleDescription,
                          isWarning: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text('Back'),
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.citizenDashboard,
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.home, size: 18),
                          label: const Text(
                            'My Workspace',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            final role = currentUser?.role ?? UserRole.citizen;
                            switch (role) {
                              case UserRole.citizen:
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.citizenDashboard,
                                );
                                break;
                              case UserRole.volunteer:
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.volunteerDashboard,
                                );
                                break;
                              case UserRole.ngoLead:
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.ngoDashboard,
                                );
                                break;
                              case UserRole.govtOfficial:
                              case UserRole.incidentCommander:
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.governmentCommandCentre,
                                );
                                break;
                              default:
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.citizenDashboard,
                                );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {String? highlightValue, bool isWarning = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isWarning ? AppColors.emergencyRed : null,
            ),
          ),
        ),
      ],
    );
  }
}

