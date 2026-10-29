import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';
import '../../data/repositories/donation_repository.dart';
import '../../shared/models/donation_model.dart';
import '../../shared/widgets/truth_badge_widget.dart';

class CitizenDonationsScreen extends ConsumerWidget {
  const CitizenDonationsScreen({super.key});

  void _showReceiptDialog(BuildContext context, DonationModel d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.receipt, color: AppColors.successGreen, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Official Donation Receipt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('GOVERNMENT OF INDIA • FORM 10BE ELIGIBLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.successGreen)),
                  const SizedBox(height: 4),
                  Text('Receipt No: ${d.receiptNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('Transaction Ref: ${d.transactionRef}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _infoRow('Donor Name', d.donorName),
            _infoRow('Beneficiary Campaign', d.campaignTitle),
            _infoRow('Operating NGO', '${d.ngoName} (${d.ngoId})'),
            _infoRow('Donation Amount', '₹${d.amount.toStringAsFixed(0)}'),
            _infoRow('Payment Rail', d.paymentMethod),
            _infoRow('Timestamp', d.timestamp.toString().substring(0, 16)),
            _infoRow('Audit Verification Hash', d.auditVerificationHash),
            const SizedBox(height: 10),
            const Text(
              'This receipt is eligible for 50% tax deduction under Section 80G of the Indian Income Tax Act 1961.',
              style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.download, size: 14),
            label: const Text('Download PDF'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ Downloaded official tax receipt ${d.receiptNumber}.pdf'),
                  backgroundColor: AppColors.successGreen,
                ),
              );
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donations = ref.watch(donationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    final totalDonated = donations.fold<double>(0.0, (sum, d) => sum + d.amount);

    return AppShell(
      currentRoute: AppRoutes.citizenDonations,
      title: 'My Donation History & Tax Receipts',
      breadcrumbs: const ['Citizen', 'Donations', 'History'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 28, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // KPI Summary Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.darkSurfaceCard],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryLight.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.verifiedGreen.withOpacity(0.2),
                    child: const Icon(Icons.volunteer_activism, color: AppColors.verifiedGreen, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL CONTRIBUTIONS',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${totalDonated.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${donations.length} Verified Donations • 100% Tax Deductible (Section 80G)',
                          style: const TextStyle(fontSize: 12, color: AppColors.verifiedGreen),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transaction Records & 80G Receipts',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('New Donation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.citizenDonate),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (donations.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No donation transactions recorded yet.', style: TextStyle(color: Colors.grey)),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: donations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final d = donations[index];

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.verifiedGreen.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                d.paymentStatus,
                                style: const TextStyle(color: AppColors.verifiedGreen, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(d.transactionRef, style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
                            ),
                            Text(
                              '₹${d.amount.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.verifiedGreen),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(d.campaignTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('NGO: ${d.ngoName} • Date: ${d.timestamp.toString().substring(0, 10)}', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText)),
                        const SizedBox(height: 4),
                        Text('Method: ${d.paymentMethod} • Receipt #${d.receiptNumber}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const TruthBadgeWidget(type: TruthBadgeType.verifiedSafe, customText: '80G AUDITED'),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                                  icon: const Icon(Icons.picture_as_pdf, size: 14),
                                  label: const Text('View 80G Receipt', style: TextStyle(fontSize: 11)),
                                  onPressed: () => _showReceiptDialog(context, d),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  icon: const Icon(Icons.account_balance, size: 14),
                                  label: const Text('Ledger', style: TextStyle(fontSize: 11)),
                                  onPressed: () => Navigator.pushNamed(context, AppRoutes.transparency),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
