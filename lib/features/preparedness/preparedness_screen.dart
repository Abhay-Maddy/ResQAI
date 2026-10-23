import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/demo_data_service.dart';

class PreparednessScreen extends StatefulWidget {
  const PreparednessScreen({super.key});

  @override
  State<PreparednessScreen> createState() => _PreparednessScreenState();
}

class _PreparednessScreenState extends State<PreparednessScreen> {
  late List<Map<String, dynamic>> _checklists;

  @override
  void initState() {
    super.initState();
    _checklists = DemoDataService.getPreparednessChecklists();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.primaryLight, size: 28),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Citizen Preparedness Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Official family emergency readiness kits, local helplines, and safe evacuation guidelines.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.verifiedGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: const Text('NDMA VERIFIED PROTOCOLS', style: TextStyle(color: AppColors.verifiedGreen, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Emergency Helpline Cards
          Row(
            children: [
              _HelplineCard(title: 'National Emergency', number: '112', icon: Icons.emergency),
              const SizedBox(width: 12),
              _HelplineCard(title: 'NDRF Disaster Helpline', number: '1078', icon: Icons.flood),
              const SizedBox(width: 12),
              _HelplineCard(title: 'Disaster Medical Control', number: '108', icon: Icons.medical_services),
              const SizedBox(width: 12),
              _HelplineCard(title: 'Fire & Rescue Unit', number: '101', icon: Icons.local_fire_department),
            ],
          ),

          const SizedBox(height: 24),

          // Preparedness Checklists (Feature 24)
          ...List.generate(_checklists.length, (catIdx) {
            final category = _checklists[catIdx];
            final items = category['items'] as List<Map<String, dynamic>>;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category['category'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryLight),
                    ),
                    const Divider(height: 20),
                    ...List.generate(items.length, (itemIdx) {
                      final item = items[itemIdx];
                      final isChecked = item['checked'] as bool;

                      return CheckboxListTile(
                        title: Text(item['name'] as String, style: TextStyle(fontSize: 13, decoration: isChecked ? TextDecoration.lineThrough : null)),
                        value: isChecked,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            item['checked'] = val ?? false;
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HelplineCard extends StatelessWidget {
  final String title;
  final String number;
  final IconData icon;

  const _HelplineCard({required this.title, required this.number, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accent, size: 22),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center, maxLines: 1),
            const SizedBox(height: 2),
            Text(number, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
