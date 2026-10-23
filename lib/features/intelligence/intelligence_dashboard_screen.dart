import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';

class IntelligenceDashboardScreen extends ConsumerWidget {
  const IntelligenceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return AppShell(
      currentRoute: AppRoutes.intelligenceDashboard,
      title: 'AI Intelligence & Predictive Analytics',
      breadcrumbs: const ['AI Intelligence', 'Command Overview'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 32,
          vertical: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Overview Banner
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(color: AppColors.primaryBlue.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.psychology, color: AppColors.primaryBlue, size: 36),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ResQAI Decision Intelligence Engine v2.4',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 20,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.deepNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Ensemble Random Forest & Spatial Bayesian Network • 12 Active District Gauges Connected',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // AI Capabilities Navigation Grid
            Text(
              'SPECIALIZED AI PREDICTION WORKSPACES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 14),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isMobile ? 1 : 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isMobile ? 2.2 : 1.35,
              children: [
                _buildAiModuleCard(
                  context,
                  title: 'Geospatial Risk Forecast',
                  description: 'Area vulnerability, river basin flood depth, and 48-hour probabilistic horizon.',
                  icon: Icons.thunderstorm_outlined,
                  route: AppRoutes.intelligenceRiskForecast,
                  color: AppColors.primaryBlue,
                  badge: 'MODEL v2.4',
                  isDark: isDark,
                ),
                _buildAiModuleCard(
                  context,
                  title: 'Predictive Relief Demand',
                  description: 'Forecasts potable water litres, food packets, and medical kits vs staged inventory.',
                  icon: Icons.inventory_2_outlined,
                  route: AppRoutes.intelligenceNeedsForecast,
                  color: AppColors.successGreen,
                  badge: '±8.4% MARGIN',
                  isDark: isDark,
                ),
                _buildAiModuleCard(
                  context,
                  title: 'Explainable Resource Allocation',
                  description: 'Multi-objective heuristic matching NDRF boats, teams, and ambulances with audit explanations.',
                  icon: Icons.alt_route_outlined,
                  route: AppRoutes.intelligenceResourceOptimization,
                  color: Colors.purple,
                  badge: 'OPTIMIZER ACTIVE',
                  isDark: isDark,
                ),
                _buildAiModuleCard(
                  context,
                  title: 'Anomalies & Silent Zones',
                  description: 'Identifies telecommunications blackout zones and detects duplicate financial vouchers.',
                  icon: Icons.signal_cellular_off_outlined,
                  route: AppRoutes.intelligenceAnomalies,
                  color: AppColors.criticalRed,
                  badge: '2 ALERTS',
                  isDark: isDark,
                ),
                _buildAiModuleCard(
                  context,
                  title: 'ResponseTwin Simulation',
                  description: 'What-if scenarios: bridge impassability, +50mm cloudburst, or additional shelter openings.',
                  icon: Icons.science_outlined,
                  route: AppRoutes.intelligenceSimulation,
                  color: Colors.teal,
                  badge: 'SANDBOX',
                  isDark: isDark,
                ),
                _buildAiModuleCard(
                  context,
                  title: 'Model Validation & Reliability',
                  description: 'Precision-Recall curves, historical calibration, false-negative logs, and drift monitor.',
                  icon: Icons.verified_outlined,
                  route: AppRoutes.intelligenceModelPerformance,
                  color: AppColors.warningOrange,
                  badge: '94.2% ACCURACY',
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiModuleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required String route,
    required Color color,
    required String badge,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Launch Workspace',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 14, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
