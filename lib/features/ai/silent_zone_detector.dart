import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/demo_data_service.dart';

class SilentZoneDetector extends StatelessWidget {
  const SilentZoneDetector({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = DemoDataService.getSilentZoneAnalytics();
    final double dropPercentage = analytics['dropPercentage'] as double;
    final bool isBlackout = analytics['isBlackoutSuspected'] as bool;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.signal_cellular_connected_no_internet_4_bar, color: AppColors.criticalRed, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Silent-Zone Anomaly Detector',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.criticalRed.withOpacity(0.15),
                    border: Border.all(color: AppColors.criticalRed),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning, size: 14, color: AppColors.criticalRed),
                      const SizedBox(width: 4),
                      Text(
                        isBlackout ? 'COMMUNICATION BLACKOUT SUSPECTED (-$dropPercentage%)' : 'REPORTING NORMAL',
                        style: const TextStyle(color: AppColors.criticalRed, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monitored Sector: ${analytics['monitoredArea']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    analytics['explanation'] as String,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatPill(
                          label: 'Historical Baseline',
                          value: '${analytics['baselineHourlyReports']} reports/hr',
                          icon: Icons.history,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatPill(
                          label: 'Current Volume (Past 90m)',
                          value: '${analytics['currentHourlyReports']} reports/hr',
                          icon: Icons.trending_down,
                          isAlert: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.warningAmber),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Safety Rule: A drop in reporting is treated as an infrastructure failure, NOT as proof that the zone is safe.',
                    style: TextStyle(color: Colors.amber.shade200, fontSize: 12),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                  icon: const Icon(Icons.satellite_alt, size: 16, color: Colors.white),
                  label: const Text('Dispatch SAT Recon', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Satellite communication reconnaissance team alert broadcasted.')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isAlert;

  const _StatPill({required this.label, required this.value, required this.icon, this.isAlert = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isAlert ? AppColors.criticalRed.withOpacity(0.1) : Colors.black26,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isAlert ? AppColors.criticalRed : Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isAlert ? AppColors.criticalRed : AppColors.primaryLight),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isAlert ? AppColors.criticalRed : Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}
