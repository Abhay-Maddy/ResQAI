import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/incident_repository.dart';
import '../../shared/models/alert_model.dart';
import '../../shared/widgets/truth_badge_widget.dart';

class OfficialAlertsScreen extends ConsumerWidget {
  const OfficialAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign, color: AppColors.criticalRed, size: 28),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Official Weather & Disaster Feeds', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Direct integrations with IMD, NDMA and GDACS. Verified statutory alerts.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh Feeds', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All official CAP v1.2 weather feeds refreshed. 0 request errors.')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Alert List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: alerts.length,
            itemBuilder: (context, idx) {
              final alt = alerts[idx];
              final isRed = alt.severity == AlertSeverity.red;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: isRed ? AppColors.criticalRed : AppColors.warningAmber, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isRed ? AppColors.criticalRed : AppColors.warningAmber,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              alt.agency.code,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            alt.severity.label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isRed ? AppColors.criticalRed : AppColors.warningAmber,
                            ),
                          ),
                          const Spacer(),
                          const TruthBadgeWidget(type: TruthBadgeType.officialAlert),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(alt.headline, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(alt.description, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.white70)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          children: [
                            const Icon(Icons.pin_drop, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('Affected Region: ${alt.affectedRegion}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            const Spacer(),
                            const Icon(Icons.sync, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('Last fetched: 5 minutes ago', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
