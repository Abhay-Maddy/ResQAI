import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/incident_repository.dart';

class MasterAdminDashboardScreen extends ConsumerStatefulWidget {
  const MasterAdminDashboardScreen({super.key});

  @override
  ConsumerState<MasterAdminDashboardScreen> createState() =>
      _MasterAdminDashboardScreenState();
}

class _MasterAdminDashboardScreenState
    extends ConsumerState<MasterAdminDashboardScreen> {
  void _openManageUsersDialog(BuildContext context) {
    final systemUsers = ref.read(systemUsersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.people_alt, color: AppColors.primaryBlue, size: 22),
            SizedBox(width: 8),
            Text('Manage Platform Users',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total registered accounts: ${systemUsers.length}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: systemUsers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final u = systemUsers[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            AppColors.primaryBlue.withOpacity(0.12),
                        child: Text(
                          u.name.isNotEmpty ? u.name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                      title: Text(u.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(
                          '${u.role.name} • ${u.phoneRaw ?? u.phoneMasked}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('ACTIVE',
                            style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white),
            icon: const Icon(Icons.person_add, size: 16),
            label: const Text('Add User'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Create user workflow opened.'),
                    backgroundColor: AppColors.primaryGreen),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openRolesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.purple, size: 22),
            SizedBox(width: 8),
            Text('Roles & Permissions Matrix',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('RBAC Security & Role Hierarchy:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            _roleTile(
                'Master Admin',
                'Unrestricted administrative control & system config',
                Colors.purple),
            _roleTile(
                'Government Official',
                'Incident verification & SDRF financial sanctions',
                Colors.indigo),
            _roleTile(
                'NGO Lead',
                'Relief campaign fund accounting & inventory distribution',
                AppColors.primaryGreen),
            _roleTile(
                'Field Responder',
                'Tactical SAR dispatch and triage execution',
                AppColors.emergencyRed),
            _roleTile(
                'Volunteer',
                'Community aid logistics & local kit handovers',
                AppColors.warningOrange),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
        ],
      ),
    );
  }

  Widget _roleTile(String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: color)),
                Text(desc,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openNgoVerificationDialog(BuildContext context) {
    final pending = ref.read(pendingApprovalsProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: AppColors.primaryGreen, size: 22),
            SizedBox(width: 8),
            Text('NGO Verification Queue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Organizations Pending DARPAN & FCRA Audit:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hope Relief Foundation (DARPAN: DL/2023/001928)',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(height: 2),
                  Text('Jurisdiction: East Delhi • 80G Certified',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('NGO credentials verified & approved.'),
                    backgroundColor: AppColors.primaryGreen),
              );
            },
            child: const Text('Approve NGO'),
          ),
        ],
      ),
    );
  }

  void _openSystemSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.settings, color: Colors.blueGrey, size: 22),
            SizedBox(width: 8),
            Text('System Configuration',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('API Environment: Production (0.0.0.0:5000)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            SizedBox(height: 6),
            Text('Database: SQLite / Persistent WAL Disk Mount',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            SizedBox(height: 6),
            Text('SMS Provider: Pluggable (Twilio/MSG91 fallback active)',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            SizedBox(height: 6),
            Text('Push Gateway: FCM High-Priority Emergency Channel',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incidents = ref.watch(incidentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return AppShell(
      currentRoute: AppRoutes.masterAdmin,
      title: 'Master Admin Control Console',
      breadcrumbs: const ['Administration', 'Master Admin'],
      child: SingleChildScrollView(
        padding:
            EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Top Master Admin Header Card (Matching Screenshot 5 Right)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface
                    : const Color(0xFF064E3B), // Deep emerald
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
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
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_user,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Master Admin',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Full System Control',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'ResQAI Disaster Response Platform',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Metrics Grid (2x2) Matching Screenshot 5 Right
            LayoutBuilder(
              builder: (context, constraints) {
                final double cardWidth = isMobile
                    ? (constraints.maxWidth - 12) / 2
                    : (constraints.maxWidth - 36) / 4;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildMetricCard(
                      icon: Icons.people_alt,
                      iconBg: Colors.blue.withOpacity(0.12),
                      iconColor: Colors.blue.shade700,
                      label: 'Total Users',
                      value: '1,258',
                      subtext: 'All Roles',
                      width: cardWidth,
                      isDark: isDark,
                    ),
                    _buildMetricCard(
                      icon: Icons.warning_amber_rounded,
                      iconBg: Colors.red.withOpacity(0.12),
                      iconColor: AppColors.emergencyRed,
                      label: 'Active Incidents',
                      value: '${incidents.isNotEmpty ? incidents.length : 52}',
                      subtext: 'Across 8 Districts',
                      width: cardWidth,
                      isDark: isDark,
                    ),
                    _buildMetricCard(
                      icon: Icons.corporate_fare,
                      iconBg: AppColors.primaryGreen.withOpacity(0.12),
                      iconColor: AppColors.primaryGreen,
                      label: 'Registered NGOs',
                      value: '186',
                      subtext: 'Verified Organizations',
                      width: cardWidth,
                      isDark: isDark,
                    ),
                    _buildMetricCard(
                      icon: Icons.volunteer_activism,
                      iconBg: Colors.teal.withOpacity(0.12),
                      iconColor: Colors.teal.shade700,
                      label: 'Active Volunteers',
                      value: '3,420',
                      subtext: 'Across NCR',
                      width: cardWidth,
                      isDark: isDark,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // 3. System Management Section
            const Text(
              'System Management',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                final double itemWidth = isMobile
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 12) / 2;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildManagementTile(
                      icon: Icons.person_outline,
                      iconBg: Colors.blue.withOpacity(0.12),
                      iconColor: Colors.blue.shade700,
                      title: 'Manage Users',
                      subtitle: 'Create, edit and manage user accounts',
                      width: itemWidth,
                      isDark: isDark,
                      onTap: () => _openManageUsersDialog(context),
                    ),
                    _buildManagementTile(
                      icon: Icons.security,
                      iconBg: Colors.purple.withOpacity(0.12),
                      iconColor: Colors.purple.shade700,
                      title: 'Roles & Permissions',
                      subtitle: 'Assign roles and control access',
                      width: itemWidth,
                      isDark: isDark,
                      onTap: () => _openRolesDialog(context),
                    ),
                    _buildManagementTile(
                      icon: Icons.corporate_fare,
                      iconBg: Colors.orange.withOpacity(0.12),
                      iconColor: Colors.orange.shade800,
                      title: 'NGO Verification',
                      subtitle: 'Verify and manage organizations',
                      width: itemWidth,
                      isDark: isDark,
                      onTap: () => _openNgoVerificationDialog(context),
                    ),
                    _buildManagementTile(
                      icon: Icons.settings_outlined,
                      iconBg: Colors.blueGrey.withOpacity(0.12),
                      iconColor: Colors.blueGrey.shade800,
                      title: 'System Settings',
                      subtitle: 'Configure alerts, regions and integrations',
                      width: itemWidth,
                      isDark: isDark,
                      onTap: () => _openSystemSettingsDialog(context),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // 4. Recent Activities Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activities',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All',
                      style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  _buildActivityRow(
                    icon: Icons.corporate_fare,
                    iconBg: AppColors.primaryGreen.withOpacity(0.12),
                    iconColor: AppColors.primaryGreen,
                    title: 'New NGO Registration',
                    subtitle: 'Hope Relief Foundation • 2 hours ago',
                    isDark: isDark,
                    onTap: () => _openNgoVerificationDialog(context),
                  ),
                  const Divider(height: 1),
                  _buildActivityRow(
                    icon: Icons.warning_amber_rounded,
                    iconBg: Colors.red.withOpacity(0.12),
                    iconColor: AppColors.emergencyRed,
                    title: 'Incident Updated',
                    subtitle:
                        'Yamuna Flood - Status changed to High • 4 hours ago',
                    isDark: isDark,
                    onTap: () => Navigator.pushNamed(
                        context, AppRoutes.governmentIncidents),
                  ),
                  const Divider(height: 1),
                  _buildActivityRow(
                    icon: Icons.person_add,
                    iconBg: Colors.blue.withOpacity(0.12),
                    iconColor: Colors.blue.shade700,
                    title: 'User Role Assigned',
                    subtitle: 'NDRF Team Bravo-3 • 6 hours ago',
                    isDark: isDark,
                    onTap: () => _openRolesDialog(context),
                  ),
                  const Divider(height: 1),
                  _buildActivityRow(
                    icon: Icons.inventory_2_outlined,
                    iconBg: Colors.orange.withOpacity(0.12),
                    iconColor: Colors.orange.shade800,
                    title: 'New Resource Request',
                    subtitle: '20 Water Pumps - Delhi NCR • 1 day ago',
                    isDark: isDark,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.ngoResources),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required String subtext,
    required double width,
    required bool isDark,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: iconBg, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required double width,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : AppColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
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
                  color: iconBg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : AppColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
