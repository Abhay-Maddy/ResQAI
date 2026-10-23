import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/demo_data_service.dart';
import '../../data/repositories/incident_repository.dart';

class SituationSummaryGenerator extends ConsumerWidget {
  const SituationSummaryGenerator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sitrep = DemoDataService.getLatestSitRep();
    final incidents = ref.watch(incidentsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description, color: AppColors.primaryLight, size: 28),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sitrep.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Generated at: ${sitrep.generatedAt.toLocal()} • Data Source: Stored Incident Records', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const Spacer(),
              // Feature 12: PDF and CSV Exports
              OutlinedButton.icon(
                icon: const Icon(Icons.table_chart, size: 16),
                label: const Text('Export CSV', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Situation Report CSV data exported. Download ready.')),
                  );
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.white),
                label: const Text('Download SitRep PDF', style: TextStyle(color: Colors.white, fontSize: 12)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Generating District Collector formatted PDF Situation Report...')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Operational Plain-Language Summary (Feature 19)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Executive Operational Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    sitrep.operationalSummary,
                    style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.white70),
                  ),
                  const Divider(height: 24),

                  // Metrics Row
                  Row(
                    children: [
                      _StatBox(label: 'Total Incidents', value: '${incidents.length}', color: AppColors.infoBlue),
                      const SizedBox(width: 12),
                      _StatBox(label: 'Active Rescue Units', value: '${sitrep.activeFieldTeams}', color: AppColors.primary),
                      const SizedBox(width: 12),
                      _StatBox(label: 'People Sheltered', value: '${sitrep.peopleSheltered}', color: AppColors.verifiedGreen),
                      const SizedBox(width: 12),
                      _StatBox(label: 'Resolved Cases', value: '${sitrep.resolvedIncidents}', color: Colors.purple),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Critical Uncertainties (Feature 19: Avoid invented facts, highlight uncertainties)
          Card(
            color: AppColors.warningAmber.withOpacity(0.08),
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: AppColors.warningAmber),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.help_outline, color: AppColors.warningAmber, size: 20),
                      SizedBox(width: 8),
                      Text('Critical Uncertainties & Data Gaps', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warningAmber, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...sitrep.criticalUncertainties.map((u) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: AppColors.warningAmber, fontWeight: FontWeight.bold)),
                          Expanded(child: Text(u, style: const TextStyle(fontSize: 13, height: 1.4))),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Feature 23: After-Action Review & Response Interval Analytics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history_toggle_off, color: AppColors.primaryLight, size: 22),
                      SizedBox(width: 8),
                      Text('After-Action Review: Response Timeline & Interval Audit', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('Replays chronological incident milestones and audits response latency intervals.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const Divider(height: 24),

                  _TimelineTile(
                    time: '18:45 IST',
                    title: 'Initial Citizen Flood Report RQ-101 Logged',
                    desc: 'Citizen in Yamuna Khadar reported 15 trapped, 3 children. AI flagged high priority (92.5).',
                    latency: '0 min (Instant)',
                    isComplete: true,
                  ),
                  _TimelineTile(
                    time: '18:52 IST',
                    title: 'Duplicate Candidate RQ-102 Received & Triaged',
                    desc: 'SMS gateway parsed proximity match. AI suggested duplicate candidate with 89% confidence.',
                    latency: '7 min interval',
                    isComplete: true,
                  ),
                  _TimelineTile(
                    time: '19:05 IST',
                    title: 'Human Commander Verification Decision',
                    desc: 'Commander verified incident RQ-101 and linked duplicate candidate with human confirmation.',
                    latency: '13 min triage latency',
                    isComplete: true,
                  ),
                  _TimelineTile(
                    time: '19:18 IST',
                    title: 'NDRF Bravo-3 Dispatched & En Route',
                    desc: 'Team dispatched with rescue rafts. Detour calculated around NH-24 structural hazard.',
                    latency: '13 min dispatch delay',
                    isComplete: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final String time;
  final String title;
  final String desc;
  final String latency;
  final bool isComplete;

  const _TimelineTile({required this.time, required this.title, required this.desc, required this.latency, required this.isComplete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 75,
            child: Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryLight)),
          ),
          CircleAvatar(
            radius: 5,
            backgroundColor: isComplete ? AppColors.verifiedGreen : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                      child: Text(latency, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
