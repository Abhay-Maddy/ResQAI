import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';
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
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Dialog(
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.criticalRed, width: 1.5),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.criticalRed.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.campaign, color: AppColors.criticalRed, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Issue Statutory Emergency Alert',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : AppColors.deepNavy,
                                ),
                              ),
                              const Text(
                                'Disaster Management Act 2005 • Section 78',
                                style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                      ),
                      child: const Text(
                        'Statutory Notice: Only authorized District Disaster Magistrates and state officers may broadcast official red/amber alerts to citizen feeds.',
                        style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('Alert Severity *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<AlertSeverity>(
                      value: selectedSeverity,
                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                      items: AlertSeverity.values
                          .map((s) => DropdownMenuItem(value: s, child: Text(s.label, style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => selectedSeverity = v);
                      },
                    ),
                    const SizedBox(height: 12),

                    const Text('Alert Headline *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: headlineCtrl,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        hintText: 'Headline of the alert',
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('Public Directive & Precautions *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Evacuation instructions, contact helplines...',
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('Target Geographical Jurisdiction *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: regionCtrl,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        hintText: 'District / Tehsils affected',
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.criticalRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          icon: const Icon(Icons.send, size: 16),
                          label: const Text('Broadcast Alert Now', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            if (headlineCtrl.text.trim().isEmpty) return;
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
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _recordAssistanceBenefitDialog(IncidentModel inc) {
    final amountCtrl = TextEditingController(
      text: inc.estimatedLossInr != null
          ? (inc.estimatedLossInr! * 0.4).clamp(10000, 150000).toStringAsFixed(0)
          : '25000',
    );
    final schemeCtrl = TextEditingController(
      text: inc.reliefAssistanceCategory ?? 'SDRF Immediate Family & Ration Ex-Gratia',
    );
    final currentUser = ref.read(authProvider);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.verifiedGreen, width: 1.5),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.currency_rupee, color: AppColors.verifiedGreen, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sanction Statutory Relief Benefit',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Case Ref: ${inc.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('Claim: ${inc.title}', style: const TextStyle(fontSize: 12)),
                      if (inc.estimatedLossInr != null)
                        Text(
                          'Claimed Loss: ₹${inc.estimatedLossInr!.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.warningOrange, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Relief Scheme / Purpose *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: schemeCtrl,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 12),
                const Text('Sanctioned Amount (₹ INR) *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, prefixText: '₹ '),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.verifiedGreen, foregroundColor: Colors.white),
                      onPressed: () {
                        final amt = double.tryParse(amountCtrl.text) ?? 25000.0;
                        ref.read(incidentsProvider.notifier).recordAssistanceSanction(
                              inc.id,
                              amount: amt,
                              category: schemeCtrl.text.trim(),
                              reviewerName: currentUser?.name ?? 'Dr. Sunita Rao (IAS)',
                              reviewerId: currentUser?.citizenId ?? 'GOV-IAS-001',
                            );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.verifiedGreen,
                            content: Text('✓ Sanction of ₹${amt.toStringAsFixed(0)} recorded for ${inc.id}. Status: SANCTIONED.'),
                          ),
                        );
                      },
                      child: const Text('Approve Sanction', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _recordDisbursalDialog(IncidentModel inc) {
    final amt = inc.sanctionedAmountInr ?? 25000.0;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.verifiedGreen),
            SizedBox(width: 8),
            Text('Disburse DBT Direct Benefit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Confirm PFMS / DBT direct bank transfer of ₹${amt.toStringAsFixed(0)} to the claimant for Case ${inc.id} (${inc.title})?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.verifiedGreen, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(incidentsProvider.notifier).recordAssistanceDisbursal(
                    inc.id,
                    amt,
                    bankRef: 'PFMS-DBT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                  );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.verifiedGreen,
                  content: Text('✓ DBT payment of ₹${amt.toStringAsFixed(0)} disbursed to ${inc.id}. Status: DISBURSED.'),
                ),
              );
            },
            child: const Text('Confirm DBT Disbursal', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _recordRejectionDialog(IncidentModel inc) {
    final reasonCtrl = TextEditingController(text: 'Ineligible under SDRF norms; address falls outside demarcated inundation zone.');
    final currentUser = ref.read(authProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.criticalRed),
            SizedBox(width: 8),
            Text('Reject Assistance Claim', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Case: ${inc.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 10),
            const Text('Reason for Rejection *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Enter formal rejection reason...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.criticalRed, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(incidentsProvider.notifier).recordAssistanceRejection(
                    inc.id,
                    reason: reasonCtrl.text.trim(),
                    reviewerName: currentUser?.name ?? 'Dr. Sunita Rao (IAS)',
                  );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.criticalRed,
                  content: Text('Claim ${inc.id} rejected. Reason logged in audit trail.'),
                ),
              );
            },
            child: const Text('Reject Claim', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    final pendingCases = incidents.where((i) => i.status == IncidentStatus.received || i.status == IncidentStatus.pendingReview || i.status == IncidentStatus.underReview).toList();
    final verifiedCases = incidents.where((i) => i.status == IncidentStatus.verified || i.status == IncidentStatus.helpAssigned || i.status == IncidentStatus.inProgress).toList();

    return AppShell(
      currentRoute: AppRoutes.governmentIncidents,
      title: 'District Administration Operations Console',
      breadcrumbs: const ['Government', 'Operations & Verification'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Administrator Profile Card
            _buildAdministratorProfileCard(currentUser, isMobile, isDark),
            const SizedBox(height: 18),

            // 2. State Disaster Response Fund (SDRF) Financial Ledger
            _buildSdrfFinancialCard(isMobile, isDark),
            const SizedBox(height: 22),

            // 3. District Operations & Verification Queue
            _buildPendingVerificationsSection(pendingCases, verifiedCases, currentUser, isMobile, isDark),
            const SizedBox(height: 22),

            // 4. District Infrastructure Readiness
            _buildInfrastructureReadinessSection(shelters, isMobile, isDark),
          ],
        ),
      ),
    );
  }

  // 1. ADMINISTRATOR PROFILE CARD (Responsive Mobile & Desktop)
  Widget _buildAdministratorProfileCard(dynamic currentUser, bool isMobile, bool isDark) {
    final adminName = currentUser?.name ?? 'Dr. Sunita Rao (IAS)';
    final jurisdiction = currentUser?.district != null ? 'District ${currentUser.district} NCR' : 'District East Delhi NCR';
    final adminId = currentUser?.citizenId ?? 'RQ-GOV-2026-001';

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF064E3B),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryLight,
                      child: const Icon(Icons.account_balance, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            adminName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Jurisdiction: $jurisdiction',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primaryLight.withOpacity(0.6)),
                      ),
                      child: const Text(
                        'DISTRICT DISASTER MAGISTRATE (IAS)',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ID: $adminId',
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Department: DDMA / Revenue Administration',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.criticalRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.campaign, size: 18),
                    label: const Text('Issue Official Alert', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: _publishOfficialAlertDialog,
                  ),
                ),
              ],
            )
          : Row(
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            adminName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.primaryLight),
                            ),
                            child: const Text(
                              'DISTRICT DISASTER MAGISTRATE (IAS)',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Jurisdiction: $jurisdiction • Department: DDMA / Revenue Administration • ID: $adminId',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.criticalRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.campaign, size: 18),
                  label: const Text('Issue Official Alert', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: _publishOfficialAlertDialog,
                ),
              ],
            ),
    );
  }

  // 2. STATE DISASTER RESPONSE FUND (SDRF) FINANCIAL LEDGER
  Widget _buildSdrfFinancialCard(bool isMobile, bool isDark) {
    return Card(
      color: isDark ? AppColors.darkSurface : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: AppColors.verifiedGreen, size: 20),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'State Disaster Response Fund (SDRF) Financial Ledger',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                const TruthBadgeWidget(type: TruthBadgeType.officialAlert),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Audit Principle: Clearly delineating Allocated vs Released vs Received vs Spent funds to eliminate relief duplication and fund misuse.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Divider(height: 24),

            // Responsive 4-metric matrix
            LayoutBuilder(
              builder: (context, constraints) {
                final double cardWidth;
                if (constraints.maxWidth >= 720) {
                  cardWidth = (constraints.maxWidth - 36) / 4;
                } else if (constraints.maxWidth >= 440) {
                  cardWidth = (constraints.maxWidth - 12) / 2;
                } else {
                  cardWidth = constraints.maxWidth;
                }

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildFinanceStat('SDRF Allocated', '₹${(_allocatedFunds / 100000).toStringAsFixed(1)} L', 'State Govt Sanction', Colors.blue, cardWidth, isDark),
                    _buildFinanceStat('District Released', '₹${(_releasedFunds / 100000).toStringAsFixed(1)} L', 'Transferred to Collector', Colors.indigoAccent, cardWidth, isDark),
                    _buildFinanceStat('Agency Received', '₹${(_receivedFunds / 100000).toStringAsFixed(1)} L', 'DDMA / NDRF / Camps', Colors.orange, cardWidth, isDark),
                    _buildFinanceStat('Verified Spent', '₹${(_spentFunds / 100000).toStringAsFixed(2)} L', 'Audited Invoices (100%)', AppColors.verifiedGreen, cardWidth, isDark),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceStat(String label, String amount, String sub, Color color, double width, bool isDark) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? color.withOpacity(0.35) : color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
            ),
          ),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.grey[700])),
        ],
      ),
    );
  }

  // 3. PENDING INCIDENT VERIFICATION & INSPECTIONS
  Widget _buildPendingVerificationsSection(
    List<IncidentModel> pendingCases,
    List<IncidentModel> verifiedCases,
    dynamic currentUser,
    bool isMobile,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Pending Incident Verifications & Inspections (${pendingCases.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.verifiedGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${verifiedCases.length} Active Dispatches',
                style: const TextStyle(fontSize: 11, color: AppColors.verifiedGreen, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

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
                color: isDark ? AppColors.darkSurface : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: ID + Title + Status Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              inc.id,
                              style: const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              inc.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              inc.status.label,
                              style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Description
                      Text(
                        inc.descriptionOriginal,
                        style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.white70),
                      ),

                      if (inc.missingPersonsCount > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.red.withOpacity(0.35)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person_search, color: AppColors.criticalRed, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'RESTRICTED: ${inc.missingPersonsCount} Missing Person(s) reported (${inc.missingPersonsDetails ?? "Tactical search requested"})',
                                  style: const TextStyle(fontSize: 11, color: AppColors.criticalRed, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (inc.lostDocuments.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.file_copy_outlined, size: 13, color: AppColors.warningOrange),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Lost / Submerged Documents: ${inc.lostDocuments.join(", ")}',
                                style: const TextStyle(fontSize: 11, color: AppColors.warningOrange, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (inc.estimatedLossInr != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Claimed Economic Loss: ₹${inc.estimatedLossInr!.toStringAsFixed(0)} • Family Size: ${inc.householdMembersCount ?? 1} members',
                          style: const TextStyle(fontSize: 12, color: AppColors.warningAmber, fontWeight: FontWeight.bold),
                        ),
                      ],

                      if (inc.assistanceDeliveryStatus != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: inc.assistanceDeliveryStatus == 'DISBURSED'
                                ? AppColors.verifiedGreen.withOpacity(0.2)
                                : (inc.assistanceDeliveryStatus == 'REJECTED'
                                    ? Colors.red.withOpacity(0.2)
                                    : Colors.amber.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'SDRF Grant Status: ${inc.assistanceDeliveryStatus} • ₹${(inc.sanctionedAmountInr ?? 0).toStringAsFixed(0)} (${inc.reliefAssistanceCategory ?? "Ex-Gratia"})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: inc.assistanceDeliveryStatus == 'DISBURSED'
                                  ? AppColors.verifiedGreen
                                  : (inc.assistanceDeliveryStatus == 'REJECTED' ? Colors.redAccent : Colors.amber),
                            ),
                          ),
                        ),
                      ],
                      const Divider(height: 20),

                      // Location Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              inc.address,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Action Buttons (Wrap to prevent horizontal overflow on mobile)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (inc.assistanceDeliveryStatus == 'SANCTIONED')
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.verifiedGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.send_to_mobile, size: 14),
                              label: Text(
                                'Disburse DBT (₹${inc.sanctionedAmountInr?.toStringAsFixed(0) ?? "25000"})',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () => _recordDisbursalDialog(inc),
                            )
                          else if (inc.assistanceDeliveryStatus != 'DISBURSED' && inc.assistanceDeliveryStatus != 'REJECTED') ...[
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryLight,
                                side: BorderSide(color: AppColors.primaryLight.withOpacity(0.5)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.currency_rupee, size: 14),
                              label: const Text('Sanction Relief', style: TextStyle(fontSize: 12)),
                              onPressed: () => _recordAssistanceBenefitDialog(inc),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.close, size: 14),
                              label: const Text('Reject Claim', style: TextStyle(fontSize: 12)),
                              onPressed: () => _recordRejectionDialog(inc),
                            ),
                          ],
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.verified, size: 14),
                            label: const Text('Verify & Assign', style: TextStyle(fontSize: 12)),
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
      ],
    );
  }

  // 4. DISTRICT INFRASTRUCTURE READINESS
  Widget _buildInfrastructureReadinessSection(List<dynamic> shelters, bool isMobile, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('District Infrastructure Readiness:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        ...shelters.map((s) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: isDark ? AppColors.darkSurface : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: s.hasMedicalUnit ? AppColors.verifiedGreen : AppColors.primary,
                      radius: 18,
                      child: Icon(s.hasMedicalUnit ? Icons.local_hospital : Icons.night_shelter, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  s.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.verifiedGreen.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${s.remainingBeds} Free Beds',
                                  style: const TextStyle(color: AppColors.verifiedGreen, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Capacity: ${s.totalCapacity} • Occupancy: ${s.occupiedBeds} • Water: ${s.waterLitersStock}L',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
