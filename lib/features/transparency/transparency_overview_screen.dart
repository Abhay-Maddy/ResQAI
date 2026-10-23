import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';
import '../ngo/ngo_management_screen.dart';

class TransparencyOverviewScreen extends ConsumerWidget {
  const TransparencyOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(ngoCampaignsProvider);
    final transactions = ref.watch(ngoTransactionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    final totalRaised = campaigns.fold<double>(0, (sum, c) => sum + c.raisedAmount);
    final totalSpent = campaigns.fold<double>(0, (sum, c) => sum + c.spentAmount);

    return AppShell(
      currentRoute: AppRoutes.transparency,
      title: 'Public Transparency Explorer',
      breadcrumbs: const ['Public', 'Transparency Explorer'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top DPDP Act Compliance & Public Trust Banner
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(color: AppColors.primaryBlue.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance, color: AppColors.primaryBlue, size: 36),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Public Relief Transparency & Fund Audit Explorer',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 20,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.deepNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Open access for every citizen. Fully auditable relief flows, verified tax invoices, and zero personal victim PII exposure.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Navigation to Dedicated Sub-Pages
            Row(
              children: [
                Expanded(
                  child: _buildSubPortalCard(
                    context,
                    title: 'Verified Relief NGOs',
                    subtitle: 'DARPAN registered organizations, projects & audit compliance',
                    icon: Icons.domain,
                    route: AppRoutes.transparencyOrgs,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildSubPortalCard(
                    context,
                    title: 'Public Financial Ledger',
                    subtitle: 'Transaction-by-transaction vouchers, bank refs & vendor invoices',
                    icon: Icons.receipt_long,
                    route: AppRoutes.transparencyFunds,
                    isDark: isDark,
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildSubPortalCard(
                      context,
                      title: 'Area Equity & Relief Gaps',
                      subtitle: 'District-by-district coverage matrix & anti-duplication redirects',
                      icon: Icons.map,
                      route: AppRoutes.transparencyAreas,
                      isDark: isDark,
                    ),
                  ),
                ],
              ],
            ),
            if (isMobile) ...[
              const SizedBox(height: 14),
              _buildSubPortalCard(
                context,
                title: 'Area Equity & Relief Gaps',
                subtitle: 'District-by-district coverage matrix & anti-duplication redirects',
                icon: Icons.map,
                route: AppRoutes.transparencyAreas,
                isDark: isDark,
              ),
            ],
            const SizedBox(height: 24),

            // Top Financial Accountability Metrics
            Row(
              children: [
                Expanded(
                  child: _buildFinancialMetric(
                    'TOTAL CITIZEN DONATIONS',
                    '₹${totalRaised.toStringAsFixed(0)}',
                    'Received via Razorpay PG',
                    AppColors.primaryBlue,
                    isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildFinancialMetric(
                    'VERIFIED EXPENDITURE',
                    '₹${totalSpent.toStringAsFixed(0)}',
                    '100% Tax Invoice Backed',
                    AppColors.successGreen,
                    isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildFinancialMetric(
                    'AVAILABLE RELIEF BALANCE',
                    '₹${(totalRaised - totalSpent).toStringAsFixed(0)}',
                    'Active Unspent Reserves',
                    AppColors.warningOrange,
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Public Ledger Activity
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Latest Verified Relief Transactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.transparencyFunds),
                        child: const Text('View Full Financial Ledger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final tx in transactions.take(4)) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.successGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.check_circle, color: AppColors.successGreen, size: 18),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tx.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('Vendor: ${tx.entityName} • Inv #${tx.invoiceNumber}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹${tx.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.primaryBlue)),
                              const Text('AUDITED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.successGreen)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 12),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubPortalCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String route,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 24),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialMetric(String label, String value, String subtitle, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
