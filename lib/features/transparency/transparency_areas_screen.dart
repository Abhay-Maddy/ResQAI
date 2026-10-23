import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';
import 'public_transparency_portal_screen.dart';

class TransparencyAreasScreen extends ConsumerWidget {
  const TransparencyAreasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allocations = ref.watch(areaAllocationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return AppShell(
      currentRoute: AppRoutes.transparencyAreas,
      title: 'Geographical Relief Equity & Gap Matrix',
      breadcrumbs: const ['Public', 'Transparency', 'Area Coverage'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.balance, color: AppColors.primaryBlue, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Anti-Duplication Resource Allocation Matrix', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Prevents relief dumping in easily accessible camps while remote lowland wards remain starved.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            for (final area in allocations) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: area.isAllocationLocked ? AppColors.warningOrange : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(area.areaName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : AppColors.deepNavy)),
                        if (area.isAllocationLocked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.warningOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                            child: const Text('ANTI-DUPLICATION LOCK ACTIVE', style: TextStyle(color: AppColors.warningOrange, fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('District: ${area.district} • Estimated Exposure: ${area.affectedPeopleEstimated} Residents', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildCoverageBar('Food', area.foodCoveragePercent, AppColors.successGreen)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildCoverageBar('Water', area.waterCoveragePercent, AppColors.criticalRed)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildCoverageBar('Medical', area.medicalCoveragePercent, AppColors.warningOrange)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.alt_route, size: 16, color: AppColors.primaryBlue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'AI Recommendation: ${area.recommendedRedirection}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCoverageBar(String label, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            Text('${percent.toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (percent / 100.0).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
