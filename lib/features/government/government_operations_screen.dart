import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/incident_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/models/incident_model.dart';
import '../../shared/models/alert_model.dart';
import '../../shared/widgets/truth_badge_widget.dart';

class GovernmentOperationsScreen extends ConsumerStatefulWidget {
  const GovernmentOperationsScreen({super.key});

  @override
  ConsumerState<GovernmentOperationsScreen> createState() => _GovernmentOperationsScreenState();
}

class _GovernmentOperationsScreenState extends ConsumerState<GovernmentOperationsScreen> {
  // Relief Fund State
  final double _allocatedFunds = 5000000.0; // ₹50 Lakh SDRF Grant
  final double _releasedFunds = 3500000.0;  // ₹35 Lakh Released to District Collector
  final double _receivedFunds = 2800000.0;  // ₹28 Lakh Received by Implementation Agencies
  final double _spentFunds = 1945000.0;     // ₹19.45 Lakh Verified Invoices

  void _publishOfficialAlertDialog() {
    final headlineCtrl = TextEditingController(text: 'IMD Red Warning: Flash Flood Inundation along Yamuna Plains');
    final descCtrl = TextEditingController(text: 'Water level crossed 206.5m. Lowland wards 3, 4, 5 instructed to evacuate immediately to designated safe camps.');
    final regionCtrl = TextEditingController(text: 'District East Delhi & Trans-Yamuna Corridor');
    AlertSeverity selectedSeverity = AlertSeverity.red;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.darkSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.criticalRed),
            ),
            title: const Row(
              children: [
                Icon(Icons.campaign, color: AppColors.criticalRed, size: 24),
                SizedBox(width: 8),
                Text('Issue Statutory Government Emergency Alert', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Statutory Authority Notice (Part 10): Only authorized District Disaster Magistrates / State Officers may publish official alerts.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 12),

                  const Text('Alert Severity *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<AlertSeverity>(
                    value: selectedSeverity,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    items: AlertSeverity.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label, style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedSeverity = v);
                    },
                  ),
                  const SizedBox(height: 10),

                  const Text('Alert Headline *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(controller: headlineCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 10),

                  const Text('Public Directive & Precautions *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder())),
                  const SizedBox(height: 10),

                  const Text('Target Geographical Jurisdiction *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(controller: regionCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.criticalRed, foregroundColor: Colors.white),
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Publish & Broadcast Alert', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  final newAlert = AlertModel(
                    id: 'ALT-GOV-${DateTime.now().millisecondsSinceEpoch % 1000}',
                    agency: AlertAgency.ndma,
                    severity: selectedSeverity,
                    headline: headlineCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    affectedRegion: regionCtrl.text.trim(),
                    issuedAt: DateTime.now(),
                    lastFetchedAt: DateTime.now(),
                    isOfficial: true,
                  );

                  ref.read(alertsProvider.notifier).state = [newAlert, ...ref.read(alertsProvider)];
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.criticalRed,
                      content: Text('✓ Official Statutory Alert published and pushed to citizen location feeds!'),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _recordAssistanceBenefitDialog(IncidentModel inc) {
    final amountCtrl = TextEditingController(text: '25000');
    final schemeCtrl = TextEditingController(text: 'SDRF Immediate Family Evacuation & Ration Ex-Gratia');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.verifiedGreen),
        ),
        title: const Row(
          children: [
            Icon(Icons.currency_rupee, color: AppColors.verifiedGreen, size: 22),
            SizedBox(width: 8),
            Text('Approve Relief Benefit / Ex-Gratia', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Case ID: ${inc.id} (${inc.title})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryLight)),
            const SizedBox(height: 10),
            const Text('Relief Scheme / Category *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(controller: schemeCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 10),
            const Text('Sanctioned Amount (₹ INR) *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.verifiedGreen, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.verifiedGreen,
                  content: Text('✓ Relief sanction of ₹${amountCtrl.text} recorded for case ${inc.id}. Audit log updated.'),
                ),
              );
            },
            child: const Text('Approve Sanction', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider);
    final incidents = ref.watch(incidentsProvider);
    final shelters = ref.watch(sheltersProvider);
    final pendingCases = incidents.where((i) => i.status == IncidentStatus.received || i.status == IncidentStatus.pendingReview || i.status == IncidentStatus.underReview).toList();
    final verifiedCases = incidents.where((i) => i.status == IncidentStatus.verified || i.status == IncidentStatus.helpAssigned || i.status == IncidentStatus.inProgress).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Console
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.darkSurfaceCard],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryLight.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryLight,
                  child: const Icon(Icons.account_balance, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            currentUser?.name ?? 'Dr. Sunita Rao (IAS)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.primaryLight),
                            ),
                            child: const Text('DISTRICT DISASTER MAGISTRATE (IAS)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Jurisdiction: District East Delhi NCR • Department: DDMA / Revenue Administration • ID: ${currentUser?.citizenId ?? "RQ-GOV-2026-001"}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.criticalRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  icon: const Icon(Icons.campaign, size: 18),
                  label: const Text('Issue Official Alert', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: _publishOfficialAlertDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Government Funding Transparency Ledger (Part 10: Allocated vs Released vs Spent)
          Card(
            color: AppColors.darkSurfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.darkBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: AppColors.verifiedGreen, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'State Disaster Response Fund (SDRF) Financial Ledger',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      TruthBadgeWidget(type: TruthBadgeType.officialAlert),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Audit Principle: Clearly delineating Allocated vs Released vs Received vs Spent funds to eliminate relief duplication and fund misuse.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Divider(height: 24),

                  // Financial Matrix
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      final cardWidth = isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildFinanceStat('SDRF Allocated', '₹${(_allocatedFunds / 100000).toStringAsFixed(1)} L', 'State Govt Sanction', Colors.blue, cardWidth),
                          _buildFinanceStat('District Released', '₹${(_releasedFunds / 100000).toStringAsFixed(1)} L', 'Transferred to Collector', Colors.indigoAccent, cardWidth),
                          _buildFinanceStat('Agency Received', '₹${(_receivedFunds / 100000).toStringAsFixed(1)} L', 'DDMA / NDRF / Camps', Colors.orange, cardWidth),
                          _buildFinanceStat('Verified Spent', '₹${(_spentFunds / 100000).toStringAsFixed(2)} L', 'Audited Invoices (100%)', AppColors.verifiedGreen, cardWidth),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // District Operations Queue (Part 10)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pending Incident Verifications & Inspections (${pendingCases.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('${verifiedCases.length} Active Dispatches', style: const TextStyle(fontSize: 12, color: AppColors.verifiedGreen, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),

          if (pendingCases.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('All reported cases in your jurisdiction have been verified or resolved.', style: TextStyle(color: Colors.grey)),
                ),
              ),
            )
          else
            ...pendingCases.map((inc) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: AppColors.darkSurfaceCard,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                              child: Text(inc.id, style: const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            Text(inc.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                          child: Text(inc.status.label, style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(inc.descriptionOriginal, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    if (inc.estimatedLossInr != null) ...[
                      const SizedBox(height: 6),
                      Text('Claimed Economic Loss: ₹${inc.estimatedLossInr!.toStringAsFixed(0)} • Family Size: ${inc.householdMembersCount ?? 1} members', style: const TextStyle(fontSize: 11, color: AppColors.warningAmber, fontWeight: FontWeight.bold)),
                    ],
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(child: Text(inc.address, style: const TextStyle(fontSize: 11, color: Colors.grey))),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.currency_rupee, size: 14),
                          label: const Text('Sanction Relief', style: TextStyle(fontSize: 11)),
                          onPressed: () => _recordAssistanceBenefitDialog(inc),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.verifiedGreen),
                          icon: const Icon(Icons.verified, size: 14),
                          label: const Text('Verify & Assign', style: TextStyle(fontSize: 11, color: Colors.white)),
                          onPressed: () {
                            ref.read(incidentsProvider.notifier).recordVerificationDecision(
                                  inc.id,
                                  newStatus: IncidentStatus.verified,
                                  reviewerId: currentUser?.citizenId ?? 'GOV-IAS-001',
                                  reviewerName: currentUser?.name ?? 'Dr. Sunita Rao (IAS)',
                                  reviewerRole: 'District Disaster Magistrate',
                                  notes: 'Approved for immediate disaster assistance dispatch.',
                                  reason: 'Administrative and aerial surveillance confirmed disaster impact.',
                                  departmentAssigned: 'NDRF 8th Battalion Flood Unit',
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.verifiedGreen,
                                content: Text('✓ Case ${inc.id} officially verified and assigned to NDRF.'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),

          const SizedBox(height: 20),

          // District Infrastructure Readiness (Shelters & Hospitals)
          const Text('District Infrastructure Readiness:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          ...shelters.map((s) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: AppColors.darkSurfaceCard,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: s.hasMedicalUnit ? AppColors.verifiedGreen : AppColors.primary,
                child: Icon(s.hasMedicalUnit ? Icons.local_hospital : Icons.night_shelter, color: Colors.white, size: 18),
              ),
              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text('Capacity: ${s.totalCapacity} • Occupancy: ${s.occupiedBeds} (${s.remainingBeds} beds free) • Water: ${s.waterLitersStock}L', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.verifiedGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                child: Text('${s.remainingBeds} Free Beds', style: const TextStyle(color: AppColors.verifiedGreen, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFinanceStat(String label, String amount, String sub, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(amount, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 9, color: Colors.white60)),
        ],
      ),
    );
  }
}
