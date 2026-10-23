import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/incident_repository.dart';
import '../../shared/widgets/truth_badge_widget.dart';

class VolunteerMatcherScreen extends ConsumerWidget {
  const VolunteerMatcherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volunteers = ref.watch(volunteersProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volunteer_activism, color: AppColors.primaryLight, size: 28),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Volunteer Skill & Proximity Matching', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Matches registered civilian skills (medical, boating, chainsaw) against active disaster requests.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const Spacer(),
              const TruthBadgeWidget(type: TruthBadgeType.piiMasked),
            ],
          ),
          const SizedBox(height: 16),

          // Safety Guidance Callout
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.infoBlue),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield, color: AppColors.infoBlue, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rule: Volunteer phone numbers are masked to prevent unauthorized contact. '
                    'All skill match recommendations require Field Commander authorization before task dispatch.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Volunteer Cards
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: volunteers.length,
            itemBuilder: (context, idx) {
              final vol = volunteers[idx];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: vol.isAvailable ? AppColors.verifiedGreen.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                        child: Icon(Icons.person, color: vol.isAvailable ? AppColors.verifiedGreen : Colors.grey),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(vol.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: vol.isAvailable ? AppColors.verifiedGreen.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    vol.isAvailable ? 'AVAILABLE FOR DISPATCH' : 'ASSIGNED (ON MISSION)',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: vol.isAvailable ? AppColors.verifiedGreen : Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Contact: ${vol.phoneMasked} • District: ${vol.district}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              children: vol.skills.map((s) {
                                return Chip(
                                  label: Text(s, style: const TextStyle(fontSize: 11)),
                                  backgroundColor: AppColors.primary.withOpacity(0.15),
                                  padding: EdgeInsets.zero,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Match Action
                      if (vol.isAvailable)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          icon: const Icon(Icons.handshake, size: 16, color: Colors.white),
                          label: const Text('Match to Incident', style: TextStyle(color: Colors.white, fontSize: 12)),
                          onPressed: () {
                            ref.read(volunteersProvider.notifier).assignVolunteer(vol.id, 'RQ-101');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${vol.name} matched to RQ-101 (Waterlogging Sector 4) based on skill profile.')),
                            );
                          },
                        )
                      else
                        OutlinedButton(
                          onPressed: null,
                          child: Text('Matched to ${vol.matchedIncidentId}', style: const TextStyle(fontSize: 11)),
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
