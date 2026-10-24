import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';
import '../../data/repositories/donation_repository.dart';
import '../../features/ngo/ngo_management_screen.dart';
import '../../shared/widgets/truth_badge_widget.dart';

class CitizenCampaignsScreen extends ConsumerStatefulWidget {
  const CitizenCampaignsScreen({super.key});

  @override
  ConsumerState<CitizenCampaignsScreen> createState() => _CitizenCampaignsScreenState();
}

class _CitizenCampaignsScreenState extends ConsumerState<CitizenCampaignsScreen> {
  String _searchQuery = '';
  String? _selectedCategory;

  void _openDonateModal(NgoCampaign campaign) {
    final amountCtrl = TextEditingController(text: '1000');
    final donorNameCtrl = TextEditingController(text: 'Citizen Donor');
    final emailCtrl = TextEditingController(text: 'citizen@resqai.org');
    bool isAnonymous = false;
    String paymentMethod = 'UPI';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.volunteer_activism, color: AppColors.primaryBlue, size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Direct Relief Contribution',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Donating to: ${campaign.title}\nBeneficiary Target: ${campaign.targetBeneficiaries} Families (${campaign.targetSector})',
                      style: const TextStyle(fontSize: 12, height: 1.35, color: AppColors.successGreen, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Select Donation Amount (₹ INR) *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [500, 1000, 2500, 5000].map((amt) {
                      return ActionChip(
                        label: Text('₹$amt'),
                        onPressed: () => setDialogState(() => amountCtrl.text = amt.toString()),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text('Donor Name (for Section 80G Tax Exemption) *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: donorNameCtrl,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Text('Email Address (for instant receipt) *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),

                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isAnonymous,
                    activeColor: AppColors.primaryBlue,
                    title: const Text('Keep my identity anonymous on public ledger', style: TextStyle(fontSize: 12)),
                    onChanged: (v) => setDialogState(() => isAnonymous = v ?? false),
                  ),
                  const SizedBox(height: 8),

                  const Text('Payment Method:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    items: const [
                      DropdownMenuItem(value: 'UPI', child: Text('UPI (Google Pay, PhonePe, Paytm, BHIM)')),
                      DropdownMenuItem(value: 'NetBanking', child: Text('NetBanking (Instant Bank Transfer)')),
                      DropdownMenuItem(value: 'Card', child: Text('Debit / Credit Card (RuPay, Visa, Mastercard)')),
                    ],
                    onChanged: (v) => setDialogState(() => paymentMethod = v ?? 'UPI'),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final amt = double.tryParse(amountCtrl.text) ?? 1000.0;
                  final donation = ref.read(donationsProvider.notifier).createVerifiedDonation(
                        campaignId: campaign.id,
                        campaignTitle: campaign.title,
                        ngoName: 'Goonj Disaster Relief Wing',
                        ngoId: 'NGO-DARPAN-DL-024810',
                        amount: amt,
                        donorName: donorNameCtrl.text.trim(),
                        donorEmail: emailCtrl.text.trim(),
                        donorPhone: '+91 98*** **210',
                        isAnonymous: isAnonymous,
                        paymentMethod: paymentMethod,
                      );

                  // Update campaign raised funds and transaction record
                  ref.read(ngoCampaignsProvider.notifier).recordDonation(campaign.id, amt);

                  Navigator.pop(ctx);
                  _showReceiptSuccessDialog(donation);
                },
                child: const Text('Complete Verified Donation', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showReceiptSuccessDialog(dynamic donation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.verifiedGreen, size: 24),
            SizedBox(width: 8),
            Text('Donation Receipt Verified', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction Reference: ${donation.transactionRef}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Amount Paid: ₹${donation.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.verifiedGreen)),
            Text('Receipt Number: ${donation.receiptNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Campaign: ${donation.campaignTitle}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Section 80G Tax Exemption: 50% deduction applicable under Income Tax Act 1961. Permanent digital receipt saved to your Donation History.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, AppRoutes.citizenDonations);
            },
            child: const Text('View My Donation History'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = ref.watch(ngoCampaignsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    final filtered = campaigns.where((c) {
      final matchesSearch = c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.objective.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.targetSector.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat = _selectedCategory == null || c.categories.contains(_selectedCategory);
      return matchesSearch && matchesCat;
    }).toList();

    return AppShell(
      currentRoute: AppRoutes.citizenDonate,
      title: 'Disaster Relief Campaigns & Giving',
      breadcrumbs: const ['Citizen', 'Relief Giving'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 28, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryBlue.withOpacity(0.15), isDark ? AppColors.darkSurface : Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.volunteer_activism, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verified Humanitarian Relief Campaigns',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '100% of contributions are tracked on the public immutable ledger with audited GST vendor invoices and Section 80G tax receipts.',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Search & Filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search campaigns, relief sectors, or food drives...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('My Giving History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.citizenDonations),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Categories Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Campaigns'),
                    selected: _selectedCategory == null,
                    onSelected: (v) => setState(() => _selectedCategory = null),
                  ),
                  const SizedBox(width: 8),
                  for (final cat in ['Emergency Rations', 'Temporary Shelter', 'Clean Drinking Water', 'Sanitation Kits']) ...[
                    ChoiceChip(
                      label: Text(cat),
                      selected: _selectedCategory == cat,
                      onSelected: (v) => setState(() => _selectedCategory = v ? cat : null),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Campaigns List
            if (filtered.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No matching campaigns found.', style: TextStyle(color: Colors.grey)),
                  ),
                ),
              )
            else
              ...filtered.map((c) {
                final percentRaised = (c.raisedAmount / c.targetAmount * 100).clamp(0, 100).toInt();

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                              child: Text(c.id, style: const TextStyle(color: AppColors.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            const TruthBadgeWidget(type: TruthBadgeType.verifiedSafe, customText: 'DARPAN VERIFIED'),
                            const Spacer(),
                            Text('Goal: ₹${(c.targetAmount / 100000).toStringAsFixed(1)}L', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(c.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(c.objective, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText, height: 1.4)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.place, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(child: Text(c.targetSector, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Progress
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (c.raisedAmount / c.targetAmount).clamp(0.0, 1.0),
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation(AppColors.primaryLight),
                            minHeight: 7,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            Text('₹${(c.raisedAmount / 100000).toStringAsFixed(1)}L Raised ($percentRaised%)', style: const TextStyle(fontSize: 11, color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
                            Text('Audited Spent: ₹${(c.spentAmount / 100000).toStringAsFixed(1)}L • ${c.verifiedBeneficiariesReached} Families Reached', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: c.inKindNeeds.map((need) => Chip(
                            label: Text(need, style: const TextStyle(fontSize: 10)),
                            padding: EdgeInsets.zero,
                            backgroundColor: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                          )).toList(),
                        ),
                        const SizedBox(height: 14),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                              icon: const Icon(Icons.account_balance, size: 14),
                              label: const Text('View Transparency', style: TextStyle(fontSize: 12)),
                              onPressed: () => Navigator.pushNamed(context, AppRoutes.transparency),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.volunteer_activism, size: 16),
                              label: const Text('Donate Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              onPressed: () => _openDonateModal(c),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
