import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';
import '../../data/repositories/auth_repository.dart';
import 'volunteer_portal_screen.dart';

class VolunteerDashboardScreen extends ConsumerWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(volunteerTasksProvider);
    final user = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    final acceptedTasks = tasks.where((t) => t.isAccepted && !t.isCompleted).toList();
    final completedTasks = tasks.where((t) => t.isCompleted).toList();

    return AppShell(
      currentRoute: AppRoutes.volunteerDashboard,
      title: 'Volunteer Operations Portal',
      breadcrumbs: const ['Volunteer', 'Dashboard'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Welcome & Service Hours
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.volunteer_activism, color: AppColors.primaryBlue, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Volunteer: ${user?.name ?? 'Ananya Deshmukh (Registered Volunteer)'}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Verified Skills: First Aid Certified, Hindi/English Bilingual • Service Radius: 8.0 km',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Service Hours & Missions Stats
            Row(
              children: [
                Expanded(child: _buildStatCard('ACCEPTED TASKS', '${acceptedTasks.length}', AppColors.primaryBlue, isDark)),
                const SizedBox(width: 14),
                Expanded(child: _buildStatCard('COMPLETED MISSIONS', '${completedTasks.length}', AppColors.successGreen, isDark)),
                const SizedBox(width: 14),
                Expanded(child: _buildStatCard('SERVICE HOURS', '${completedTasks.length * 4 + 12} hrs', Colors.purple, isDark)),
              ],
            ),
            const SizedBox(height: 24),

            // Next Immediate Assignment Card
            if (acceptedTasks.isNotEmpty) ...[
              const Text('ACTIVE ASSIGNMENT IN PROGRESS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryBlue.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(acceptedTasks.first.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                          child: const Text('EN ROUTE', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Location: ${acceptedTasks.first.location}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.navigation, size: 16),
                          label: const Text('Navigate Route'),
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.disasterMap),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.successGreen, foregroundColor: Colors.white),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Complete & Upload Proof'),
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.volunteerTasks),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Opportunities Navigator
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.search),
              label: const Text('Discover Nearby Volunteer Opportunities', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.volunteerTasks),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
