import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';
import '../../data/repositories/incident_repository.dart';
import 'ngo_management_screen.dart';

class NgoDashboardScreen extends ConsumerStatefulWidget {
  const NgoDashboardScreen({super.key});

  @override
  ConsumerState<NgoDashboardScreen> createState() => _NgoDashboardScreenState();
}

class _NgoDashboardScreenState extends ConsumerState<NgoDashboardScreen> {
  int _selectedFilterIndex = 0; // 0: Campaigns, 1: Finance Ledger, 2: Relief Inventory

  void _showNewActionSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'NGO Relief Actions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.campaign, color: AppColors.primaryGreen, size: 22),
                ),
                title: const Text('Launch Relief Campaign', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Publish verified relief drive with target budget', style: TextStyle(fontSize: 12, color: Colors.grey)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.ngoCampaigns, arguments: 0);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warningOrange.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long, color: AppColors.warningOrange, size: 22),
                ),
                title: const Text('Record Audited Expense', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Attach vendor invoice and GSTIN verification', style: TextStyle(fontSize: 12, color: Colors.grey)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.ngoFinances, arguments: 1);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_shipping, color: AppColors.primaryBlue, size: 22),
                ),
                title: const Text('Log Delivery Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Record household aid handover with signed challan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.ngoBeneficiaries, arguments: 5);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.emerald600.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.inventory_2, color: AppColors.emerald600, size: 22),
                ),
                title: const Text('Update Warehouse Inventory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Add rations, tarpaulins, water purification units', style: TextStyle(fontSize: 12, color: Colors.grey)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.ngoResources, arguments: 2);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = ref.watch(ngoCampaignsProvider);
    final incidents = ref.watch(incidentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    final totalRaised = campaigns.fold<double>(0, (sum, c) => sum + c.raisedAmount);
    final totalSpent = campaigns.fold<double>(0, (sum, c) => sum + c.spentAmount);
    final totalCommitted = campaigns.fold<double>(0, (sum, c) => sum + c.committedAmount);
    final totalAvailable = (totalRaised - (totalSpent + totalCommitted)).clamp(0.0, double.infinity);

    final openRequests = incidents.take(3).toList();

    return AppShell(
      currentRoute: AppRoutes.ngoDashboard,
      title: 'ResQAI',
      breadcrumbs: const ['NGO', 'Transparency Portal'],
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('New Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        onPressed: () => _showNewActionSheet(context),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Top DARPAN Verification Header Card (Screenshot 5 Left)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.emerald50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.corporate_fare, color: AppColors.primaryGreen, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NGO Transparency Portal',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 15 : 17,
                            color: isDark ? Colors.white : AppColors.deepNavy,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'DARPAN: DL/2019/0001234 • Goonj Wing',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.emerald50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.emerald200),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: AppColors.emerald700, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'DARPAN VERIFIED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.emerald700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Interactive Filter Tabs (Campaigns, Finance Ledger, Relief Inventory)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1.2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  _buildFilterTab(
                    label: 'Campaigns (${campaigns.length})',
                    icon: Icons.campaign_outlined,
                    isSelected: _selectedFilterIndex == 0,
                    onTap: () {
                      setState(() => _selectedFilterIndex = 0);
                    },
                  ),
                  _buildFilterTab(
                    label: 'Finance Ledger (5)',
                    icon: Icons.receipt_long_outlined,
                    isSelected: _selectedFilterIndex == 1,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.ngoFinances, arguments: 1);
                    },
                  ),
                  _buildFilterTab(
                    label: 'Relief Inventory',
                    icon: Icons.inventory_2_outlined,
                    isSelected: _selectedFilterIndex == 2,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.ngoResources, arguments: 2);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Hero Campaign Card (Yamuna Flood Relief 2024)
            InkWell(
              onTap: () => Navigator.pushNamed(context, AppRoutes.ngoCampaigns, arguments: 0),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Thumbnail Box
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 64,
                            height: 64,
                            color: AppColors.emerald50,
                            child: const Icon(
                              Icons.volunteer_activism,
                              color: AppColors.primaryGreen,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Yamuna Flood Relief 2024',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.emerald50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.emerald200),
                                    ),
                                    child: const Text(
                                      'Active',
                                      style: TextStyle(
                                        color: AppColors.emerald700,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  const Text('Delhi NCR', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  const Expanded(
                                    child: Text(
                                      'Jan 10, 2024 – Mar 31, 2024',
                                      style: TextStyle(fontSize: 11, color: Colors.grey),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 3 Metric Pills
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricPill(
                            icon: Icons.people_outline,
                            label: '2,590',
                            sub: 'Families Assisted',
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricPill(
                            icon: Icons.person_outline,
                            label: '12',
                            sub: 'Active Volunteers',
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricPill(
                            icon: Icons.night_shelter_outlined,
                            label: '18',
                            sub: 'Relief Camps',
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 4. Financial Summary (Screenshot 5 Left)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Financial Summary',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.ngoFinances, arguments: 1),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 2x2 Grid of Financial Cards
            Row(
              children: [
                Expanded(
                  child: _buildFinanceCard(
                    title: 'Verified Received',
                    amount: '₹${(totalRaised / 100000).toStringAsFixed(1)} L',
                    sub: 'Grants & Donations',
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: AppColors.emerald600,
                    bgColor: AppColors.emerald50,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFinanceCard(
                    title: 'Verified Spent',
                    amount: '₹${(totalSpent / 100000).toStringAsFixed(1)} L',
                    sub: 'Field Expenses',
                    icon: Icons.payment_outlined,
                    iconColor: AppColors.criticalRed,
                    bgColor: const Color(0xFFFEF2F2),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildFinanceCard(
                    title: 'Committed Orders',
                    amount: '₹${(totalCommitted / 100000).toStringAsFixed(1)} L',
                    sub: 'Purchase Orders',
                    icon: Icons.shopping_bag_outlined,
                    iconColor: AppColors.warningOrange,
                    bgColor: const Color(0xFFFFFBEB),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFinanceCard(
                    title: 'Uncommitted Cash',
                    amount: '₹${(totalAvailable / 100000).toStringAsFixed(1)} L',
                    sub: 'Available for Relief',
                    icon: Icons.account_balance_outlined,
                    iconColor: AppColors.primaryGreen,
                    bgColor: AppColors.emerald50,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // 5. Recent Activities Section (Screenshot 5 Left)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activities',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.ngoBeneficiaries, arguments: 5),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  _buildActivityTile(
                    icon: Icons.local_shipping_outlined,
                    iconColor: AppColors.primaryBlue,
                    bgColor: const Color(0xFFEFF6FF),
                    title: '500 Relief Kits Delivered',
                    subtitle: 'Shahdara, Delhi',
                    time: '2 hours ago',
                    isDark: isDark,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.ngoBeneficiaries, arguments: 5),
                  ),
                  const Divider(height: 1),
                  _buildActivityTile(
                    icon: Icons.person_add_outlined,
                    iconColor: AppColors.primaryGreen,
                    bgColor: AppColors.emerald50,
                    title: 'New Volunteer Joined',
                    subtitle: 'Ananya Sharma',
                    time: '5 hours ago',
                    isDark: isDark,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.ngoVolunteers),
                  ),
                  const Divider(height: 1),
                  _buildActivityTile(
                    icon: Icons.receipt_long_outlined,
                    iconColor: AppColors.warningOrange,
                    bgColor: const Color(0xFFFFFBEB),
                    title: 'Donation Received',
                    subtitle: '₹50,000 from CSR Partner',
                    time: '1 day ago',
                    isDark: isDark,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.ngoFinances, arguments: 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 6. Citizen Humanitarian Aid Request Queue
            if (openRequests.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Aid Intake Queue',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${openRequests.length} Pending Delivery',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final inc in openRequests) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.inventory_2_outlined, color: AppColors.primaryGreen, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inc.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              inc.address,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          ref.read(incidentsProvider.notifier).updateStatus(
                                inc.id,
                                IncidentStatus.helpAssigned,
                                team: 'Goonj Foundation Relief Mission',
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Accepted aid request "${inc.title}". Logistics dispatched.'),
                              backgroundColor: AppColors.primaryGreen,
                            ),
                          );
                        },
                        child: const Text('Accept & Supply', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            const SizedBox(height: 70), // Spacing for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primaryGreen : Colors.transparent,
              width: 2.4,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primaryGreen : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primaryGreen : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricPill({
    required IconData icon,
    required String label,
    required String sub,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: AppColors.primaryGreen),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceCard({
    required String title,
    required String amount,
    required String sub,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? iconColor.withOpacity(0.15) : bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required String time,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? iconColor.withOpacity(0.15) : bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(
              time,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
