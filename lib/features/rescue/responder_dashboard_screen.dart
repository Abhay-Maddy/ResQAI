import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';
import 'rescue_team_operations_screen.dart';

class ResponderDashboardScreen extends ConsumerWidget {
  const ResponderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missions = ref.watch(rescueMissionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    final activeMissions = missions.where((m) => m.stage != RescueMissionStage.resolved).toList();
    final resolvedMissions = missions.where((m) => m.stage == RescueMissionStage.resolved).toList();

    return AppShell(
      currentRoute: AppRoutes.responderDashboard,
      title: 'NDRF / SDRF Rescue Operations Command',
      breadcrumbs: const ['Rescue', 'Dashboard'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Rescue Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.criticalRed.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.directions_boat, color: AppColors.criticalRed, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('8th Battalion NDRF Quick Response Team', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('4-Stage Mission Dispatch (Dispatched → En Route → On Scene → Resolved) • Life Safety Rescue', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Missions Status
            Row(
              children: [
                Expanded(child: _buildMetricCard('ACTIVE MISSIONS', '${activeMissions.length}', AppColors.criticalRed, isDark)),
                const SizedBox(width: 14),
                Expanded(child: _buildMetricCard('SURVIVORS RESCUED', '38 Persons', AppColors.successGreen, isDark)),
                const SizedBox(width: 14),
                Expanded(child: _buildMetricCard('RESOLVED CALLS', '${resolvedMissions.length}', AppColors.primaryBlue, isDark)),
              ],
            ),
            const SizedBox(height: 24),

            // Active Missions Queue
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Assigned Rescue Operations Queue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 14),
                  for (final item in missions) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.criticalRed.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.stage.name.toUpperCase(),
                              style: const TextStyle(color: AppColors.criticalRed, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('Location: ${item.location} • Stranded: ${item.strandedVictimsCount} persons', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                            icon: const Icon(Icons.navigation, size: 14),
                            label: const Text('Open Mission Map'),
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.disasterMap),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 12),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color, bool isDark) {
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
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
