import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/incident_repository.dart';
import '../../shared/models/rumor_model.dart';

class RumorMisinformationTracker extends ConsumerWidget {
  const RumorMisinformationTracker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rumors = ref.watch(rumorsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check, color: AppColors.accent, size: 28),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rumor & Misinformation Tracker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Corroborates viral claims, tracks WhatsApp forwards, and publishes official debunking notices.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                icon: const Icon(Icons.add_alert, size: 16, color: Colors.white),
                label: const Text('Submit Viral Claim for Fact-Check', style: TextStyle(color: Colors.white, fontSize: 12)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Claim submitted to District Information Officer verification queue.')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rumors.length,
            itemBuilder: (context, idx) {
              final rum = rumors[idx];
              final isDebunked = rum.status == RumorStatus.debunked;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDebunked ? AppColors.criticalRed.withOpacity(0.2) : AppColors.warningAmber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: isDebunked ? AppColors.criticalRed : AppColors.warningAmber),
                            ),
                            child: Text(
                              rum.status.label.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDebunked ? AppColors.criticalRed : AppColors.warningAmber,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('Source: ${rum.sourceChannel}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const Spacer(),
                          Text('${rum.reportsCount} Community Reports Flagged', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Claim: "${rum.claimText}"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDebunked ? AppColors.criticalRed.withOpacity(0.08) : Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDebunked ? AppColors.criticalRed.withOpacity(0.3) : Colors.white12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(isDebunked ? Icons.cancel : Icons.hourglass_top, color: isDebunked ? AppColors.criticalRed : AppColors.warningAmber, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                rum.officialFactCheck,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  fontWeight: isDebunked ? FontWeight.w600 : FontWeight.normal,
                                  color: isDebunked ? Colors.red.shade200 : Colors.amber.shade200,
                                ),
                              ),
                            ),
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
