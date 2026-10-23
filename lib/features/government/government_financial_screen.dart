import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';

class GovernmentFinancialScreen extends StatelessWidget {
  const GovernmentFinancialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return AppShell(
      currentRoute: AppRoutes.governmentFinancialTransparency,
      title: 'State Disaster Response Fund (SDRF) Accounting',
      breadcrumbs: const ['Government', 'Finance', 'SDRF Ledger'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Description
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.account_balance, color: AppColors.primaryBlue, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SDRF / NDRF Statutory Disaster Fund Accounting', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('4-Part accounting tracking Approved Budget, Allocated Funds, Released Tranches, and Audited Expenditure.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // 4-Part SDRF Accounting Cards
            Row(
              children: [
                Expanded(child: _buildFundCard('APPROVED BUDGET', '₹50,00,000', 'State Sanctioned', AppColors.primaryBlue, isDark)),
                const SizedBox(width: 12),
                Expanded(child: _buildFundCard('ALLOCATED FUNDS', '₹35,00,000', 'To District Collector', Colors.purple, isDark)),
                const SizedBox(width: 12),
                Expanded(child: _buildFundCard('RELEASED TRANCHE', '₹28,00,000', 'To Line Departments', AppColors.warningOrange, isDark)),
                const SizedBox(width: 12),
                Expanded(child: _buildFundCard('AUDITED SPENT', '₹19,45,000', 'Verified Tax Bills', AppColors.successGreen, isDark)),
              ],
            ),
            const SizedBox(height: 24),

            // District Allocation Breakdown Table
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('District Administration Grant Allocations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 14),
                  ListTile(
                    title: Text('East Delhi District Disaster Authority', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('Sanctioned: ₹22,00,000 • Released: ₹18,00,000 • Gratuitous Relief Disbursed: ₹12,50,000'),
                    trailing: Text('AUDITED', style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  Divider(),
                  ListTile(
                    title: Text('North East Delhi Disaster Authority', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('Sanctioned: ₹15,00,000 • Released: ₹10,00,000 • Gratuitous Relief Disbursed: ₹6,95,000'),
                    trailing: Text('AUDITED', style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFundCard(String label, String value, String subtitle, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
