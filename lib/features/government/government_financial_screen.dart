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
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 32,
          vertical: isMobile ? 16 : 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A1. Main Heading & Statutory Accounting Card
            _buildStatutoryHeadingCard(isDark, isMobile),
            const SizedBox(height: 20),

            // A2 & A3. 4-Part Responsive Financial Metric Matrix
            _buildResponsiveMetricGrid(isDark, width),
            const SizedBox(height: 24),

            // A4. District Administration Grant Allocations Section
            _buildDistrictAllocationsSection(isDark, isMobile),
            const SizedBox(height: 80), // Avoid mobile bottom nav occlusion
          ],
        ),
      ),
    );
  }

  // A1. MAIN STATUTORY HEADING CARD
  Widget _buildStatutoryHeadingCard(bool isDark, bool isMobile) {
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance,
              color: AppColors.primaryBlue,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SDRF / NDRF Statutory Disaster Fund Accounting',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: isMobile ? 15 : 18,
                    letterSpacing: -0.2,
                    color: isDark ? Colors.white : AppColors.deepNavy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Statutory public financial ledger mandated under Section 48 of the Disaster Management Act 2005. Complete 4-part tracking of Approved State Budget, Allocated Funds, Released District Tranches, and Tax-Audited Relief Expenditure.',
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    height: 1.4,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // A2 & A3. 4-PART FINANCIAL METRIC GRID (Responsive & Tabular Numerals)
  Widget _buildResponsiveMetricGrid(bool isDark, double screenWidth) {
    final metrics = [
      _MetricData(
        label: 'APPROVED BUDGET',
        value: '₹ 50,00,000',
        subtitle: 'State Executive Sanction',
        color: AppColors.primaryBlue,
        icon: Icons.gavel,
      ),
      _MetricData(
        label: 'ALLOCATED FUNDS',
        value: '₹ 35,00,000',
        subtitle: 'To District Magistrate',
        color: Colors.purple,
        icon: Icons.account_balance_wallet,
      ),
      _MetricData(
        label: 'RELEASED TRANCHE',
        value: '₹ 28,00,000',
        subtitle: 'To Line Agencies & NGOs',
        color: AppColors.warningOrange,
        icon: Icons.send_to_mobile,
      ),
      _MetricData(
        label: 'AUDITED SPENT',
        value: '₹ 19,45,000',
        subtitle: 'Verified GST Vouchers',
        color: AppColors.successGreen,
        icon: Icons.verified_user,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        // Desktop: 4 columns
        if (availableWidth >= 880) {
          return Row(
            children: metrics
                .map((m) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _buildMetricCard(m, isDark),
                      ),
                    ))
                .toList(),
          );
        }

        // Tablet / Large Phone: 2 columns
        if (availableWidth >= 440) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildMetricCard(metrics[0], isDark)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildMetricCard(metrics[1], isDark)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildMetricCard(metrics[2], isDark)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildMetricCard(metrics[3], isDark)),
                ],
              ),
            ],
          );
        }

        // Compact Phone: 1 column
        return Column(
          children: metrics.map((m) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildMetricCard(m, isDark),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMetricCard(_MetricData data, bool isDark) {
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Colors.grey,
                  ),
                ),
              ),
              Icon(data.icon, size: 16, color: data.color.withOpacity(0.8)),
            ],
          ),
          const SizedBox(height: 8),
          // Currency Value with scale-down & tabular numbers
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: data.color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  // A4. DISTRICT ADMINISTRATION GRANT ALLOCATIONS
  Widget _buildDistrictAllocationsSection(bool isDark, bool isMobile) {
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final allocations = [
      _DistrictGrant(
        district: 'East Delhi District Disaster Management Authority (DDMA)',
        sanctioned: '₹ 22,00,000',
        released: '₹ 18,00,000',
        disbursed: '₹ 12,50,000',
        auditStatus: 'AUDITED & VERIFIED',
        details: 'Gratuitous relief, dry rations & temporary shelter tarp distribution across 4 flood evacuation staging sites.',
        vouchersCount: 38,
      ),
      _DistrictGrant(
        district: 'North East Delhi District Disaster Authority',
        sanctioned: '₹ 15,00,000',
        released: '₹ 10,00,000',
        disbursed: '₹ 6,95,000',
        auditStatus: 'AUDITED & VERIFIED',
        details: 'Medical trauma kits, water purification pouches, and ex-gratia bank transfers to 230 evacuated families.',
        vouchersCount: 22,
      ),
      _DistrictGrant(
        district: 'Shahdara District Relief & Rescue Operations Center',
        sanctioned: '₹ 13,00,000',
        released: '₹ 7,00,000',
        disbursed: '₹ 4,80,000',
        auditStatus: 'INTERIM AUDIT PASS',
        details: 'Mobile ambulance diesel ex-gratia and 150 community kitchen provisions verified by Sub-Divisional Magistrate.',
        vouchersCount: 16,
      ),
    ];

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'District Administration Grant Allocations',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: isMobile ? 15 : 17,
                    letterSpacing: -0.2,
                    color: isDark ? Colors.white : AppColors.deepNavy,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'FY 2025–26',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Audited inter-governmental transfers to District Magistrates under statutory SDRF allocations.',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // District Entries
          ...allocations.asMap().entries.map((entry) {
            final isLast = entry.key == allocations.length - 1;
            final item = entry.value;

            return Column(
              children: [
                _buildDistrictGrantCard(item, isDark, isMobile),
                if (!isLast) ...[
                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDistrictGrantCard(_DistrictGrant item, bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // District Name & Audit Badge Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.district,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: isMobile ? 13 : 14,
                  height: 1.3,
                  color: isDark ? Colors.white : AppColors.deepNavy,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.successGreen.withOpacity(0.4)),
              ),
              child: Text(
                item.auditStatus,
                style: const TextStyle(
                  color: AppColors.successGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 3 Pillars: Sanctioned, Released, Disbursed
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: isMobile
              ? Column(
                  children: [
                    _buildPillarRow('Sanctioned:', item.sanctioned, AppColors.primaryBlue),
                    const SizedBox(height: 6),
                    _buildPillarRow('Released Tranche:', item.released, AppColors.warningOrange),
                    const SizedBox(height: 6),
                    _buildPillarRow('Relief Disbursed:', item.disbursed, AppColors.successGreen),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildPillarColumn('Sanctioned Amount', item.sanctioned, AppColors.primaryBlue)),
                    Container(height: 28, width: 1, color: Colors.grey.withOpacity(0.2)),
                    Expanded(child: _buildPillarColumn('Released Tranche', item.released, AppColors.warningOrange)),
                    Container(height: 28, width: 1, color: Colors.grey.withOpacity(0.2)),
                    Expanded(child: _buildPillarColumn('Relief Disbursed', item.disbursed, AppColors.successGreen)),
                  ],
                ),
        ),
        const SizedBox(height: 8),

        // Supporting Details & Vouchers
        Row(
          children: [
            Expanded(
              child: Text(
                item.details,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${item.vouchersCount} Tax Vouchers',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPillarRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildPillarColumn(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  _MetricData({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });
}

class _DistrictGrant {
  final String district;
  final String sanctioned;
  final String released;
  final String disbursed;
  final String auditStatus;
  final String details;
  final int vouchersCount;

  _DistrictGrant({
    required this.district,
    required this.sanctioned,
    required this.released,
    required this.disbursed,
    required this.auditStatus,
    required this.details,
    required this.vouchersCount,
  });
}

