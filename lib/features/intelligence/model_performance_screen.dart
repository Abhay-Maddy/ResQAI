import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';

class ModelPerformanceScreen extends StatelessWidget {
  const ModelPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return AppShell(
      currentRoute: AppRoutes.intelligenceModelPerformance,
      title: 'AI Model Performance & Calibration Audit',
      breadcrumbs: const ['AI Intelligence', 'Model Performance'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Model Validation Summary
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Inundation & Distress Classification Metrics (v2.4)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.successGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                        child: const Text('CALIBRATED (Brier Score: 0.082)', style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildMetricItem('PRECISION', '92.4%', 'Low false alarms', isDark)),
                      Expanded(child: _buildMetricItem('RECALL (LIFE-SAFETY)', '96.8%', 'Minimized missed distress', isDark)),
                      Expanded(child: _buildMetricItem('F1 SCORE', '0.945', 'Harmonic balance', isDark)),
                      Expanded(child: _buildMetricItem('DATA FRESHNESS', '3 mins ago', 'CWC Gauge telemetry', isDark)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Temporal Validation & Confusion Matrix
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Confusion Matrix (Holdout Validation on 2023-2025 Monsoons)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          tileColor: Color(0x1516A34A),
                          title: Text('True Positives (Verified Distress)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          subtitle: Text('1,420 cases correctly classified & escalated'),
                          trailing: Icon(Icons.check_circle, color: AppColors.successGreen),
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: ListTile(
                          tileColor: Color(0x15DC2626),
                          title: Text('False Negatives (Missed Life-Threats)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          subtitle: Text('8 cases (Flagged for manual review rule update)'),
                          trailing: Icon(Icons.error_outline, color: AppColors.criticalRed),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Missing-input and Drift Warnings
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.monitor_heart, color: AppColors.primaryBlue, size: 24),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Automated Sensor Drift Monitor: Gauge Sensor #CW-09 at Okhla Barrage shows +1.2% calibration deviation. Heuristic bias correction active.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, String subtitle, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primaryBlue)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
