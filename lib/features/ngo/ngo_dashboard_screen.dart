import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';
import 'ngo_management_screen.dart';

class NgoDashboardScreen extends ConsumerWidget {
  const NgoDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(ngoCampaignsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    final totalRaised = campaigns.fold<double>(0, (sum, c) => sum + c.raisedAmount);
    final totalSpent = campaigns.fold<double>(0, (sum, c) => sum + c.spentAmount);

    return AppShell(
      currentRoute: AppRoutes.ngoDashboard,
      title: 'NGO Operations Command',
      breadcrumbs: const ['NGO', 'Dashboard'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top DARPAN Verification Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_user, color: AppColors.successGreen, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Goonj Foundation Relief Mission (DARPAN: DL/2021/0088192)',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Authorized Relief Operator • Designated Operation Zones: East Delhi & Yamuna Basin',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Metrics
            if (isMobile)
              Column(
                children: [
                  _buildKpiCard('TOTAL DONATIONS', '₹${totalRaised.toStringAsFixed(0)}', AppColors.primaryBlue, isDark),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildKpiCard('AUDITED EXPENDITURE', '₹${totalSpent.toStringAsFixed(0)}', AppColors.successGreen, isDark)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildKpiCard('ACTIVE CAMPAIGNS', '${campaigns.length}', Colors.purple, isDark)),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(child: _buildKpiCard('TOTAL DONATIONS', '₹${totalRaised.toStringAsFixed(0)}', AppColors.primaryBlue, isDark)),
                  const SizedBox(width: 14),
                  Expanded(child: _buildKpiCard('AUDITED EXPENDITURE', '₹${totalSpent.toStringAsFixed(0)}', AppColors.successGreen, isDark)),
                  const SizedBox(width: 14),
                  Expanded(child: _buildKpiCard('ACTIVE CAMPAIGNS', '${campaigns.length}', Colors.purple, isDark)),
                ],
              ),
            const SizedBox(height: 24),

            // Quick Operations Navigation
            if (isMobile)
              Column(
                children: [
                  _buildNavCard(
                    context,
                    title: 'Active Campaigns',
                    subtitle: 'Manage fundraising & target relief packets',
                    icon: Icons.volunteer_activism,
                    route: AppRoutes.ngoCampaigns,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildNavCard(
                    context,
                    title: 'Financial Ledger & Invoices',
                    subtitle: 'Log tax invoices, vendor receipts & GSTIN proof',
                    icon: Icons.receipt_long,
                    route: AppRoutes.ngoFinances,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildNavCard(
                    context,
                    title: 'Supply Warehouse',
                    subtitle: 'Inventory counts, rations & medical reserves',
                    icon: Icons.inventory_2,
                    route: AppRoutes.ngoResources,
                    isDark: isDark,
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _buildNavCard(
                      context,
                      title: 'Active Campaigns',
                      subtitle: 'Manage fundraising & target relief packets',
                      icon: Icons.volunteer_activism,
                      route: AppRoutes.ngoCampaigns,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildNavCard(
                      context,
                      title: 'Financial Ledger & Invoices',
                      subtitle: 'Log tax invoices, vendor receipts & GSTIN proof',
                      icon: Icons.receipt_long,
                      route: AppRoutes.ngoFinances,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildNavCard(
                      context,
                      title: 'Supply Warehouse',
                      subtitle: 'Inventory counts, rations & medical reserves',
                      icon: Icons.inventory_2,
                      route: AppRoutes.ngoResources,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, Color color, bool isDark) {
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
        ],
      ),
    );
  }

  Widget _buildNavCard(
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
}
