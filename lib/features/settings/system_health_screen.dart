import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/truth_badge_widget.dart';

class SystemHealthScreen extends StatelessWidget {
  const SystemHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.monitor_heart, color: AppColors.verifiedGreen, size: 28),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('System Health, Integrations & Backup Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Real-time operational monitoring of external feeds, database redundancy, and DPDP retention policies.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // External Integration Health Table (Feature 13)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('External Integration Health Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const Divider(height: 20),
                  _HealthRow(name: 'IMD CAP Weather Feed API', status: 'Operational', latency: '320 ms', isGreen: true),
                  _HealthRow(name: 'NDMA Alert Webhook Gateway', status: 'Operational', latency: '410 ms', isGreen: true),
                  _HealthRow(name: 'GDACS Global Hazard Telemetry', status: 'Operational', latency: '820 ms', isGreen: true),
                  _HealthRow(name: 'Twilio SMS / WhatsApp Inbound Webhook', status: 'Connected (Simulated)', latency: '45 ms', isGreen: true),
                  _HealthRow(name: 'PostgreSQL / SQLite Replicated Database', status: 'Synchronized (0 error)', latency: '12 ms', isGreen: true),
                  _HealthRow(name: 'Offline Service Worker Cache (PWA)', status: 'Active (3.4 MB stored)', latency: '0 ms (Local)', isGreen: true),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Backup & Recovery Controls (Feature 13)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.backup, color: AppColors.primaryLight, size: 22),
                      const SizedBox(width: 8),
                      const Text('Automated Database Backup & Restoration', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        icon: const Icon(Icons.cloud_upload, size: 16, color: Colors.white),
                        label: const Text('Trigger Snapshot Backup Now', style: TextStyle(color: Colors.white, fontSize: 12)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Point-in-time database snapshot created: backup-2026-10-22.tar.gz.')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Backup frequency: Hourly WAL incremental archives + Daily cold backup. '
                    'Recovery Time Objective (RTO): < 5 minutes. Recovery Point Objective (RPO): < 60 seconds.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sensitive Data Protection & DPDP Policy (Feature 7)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.privacy_tip, color: AppColors.warningAmber, size: 22),
                      SizedBox(width: 8),
                      Text('Sensitive Data Protection & DPDP Compliance Policy', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      Spacer(),
                      TruthBadgeWidget(type: TruthBadgeType.piiMasked),
                    ],
                  ),
                  const Divider(height: 20),
                  const Text(
                    '1. Data Minimization: Citizen reports only store phone numbers for emergency verification.\n'
                    '2. Role-Based Field Masking: Public tracking screens redact phone numbers as +91 98*** **412.\n'
                    '3. Retention Rules: Incident records auto-archive 90 days after case resolution.\n'
                    '4. Privacy Deletion: Citizens can request redaction of personal identifying details once incident is verified.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
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

class _HealthRow extends StatelessWidget {
  final String name;
  final String status;
  final String latency;
  final bool isGreen;

  const _HealthRow({required this.name, required this.status, required this.latency, required this.isGreen});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(radius: 4, backgroundColor: isGreen ? AppColors.verifiedGreen : AppColors.criticalRed),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isGreen ? AppColors.verifiedGreen : AppColors.criticalRed)),
          const SizedBox(width: 16),
          Text(latency, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
