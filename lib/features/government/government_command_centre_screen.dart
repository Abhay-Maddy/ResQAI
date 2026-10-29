import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/incident_repository.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';
import 'government_operations_screen.dart';
import '../../shared/models/incident_model.dart';
import '../../data/services/notification_client_service.dart';

class GovernmentCommandCentreScreen extends ConsumerStatefulWidget {
  const GovernmentCommandCentreScreen({super.key});

  @override
  ConsumerState<GovernmentCommandCentreScreen> createState() => _GovernmentCommandCentreScreenState();
}

class _GovernmentCommandCentreScreenState extends ConsumerState<GovernmentCommandCentreScreen> {
  void _openReviewSanctionDialog(BuildContext context, IncidentModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sanctionCtrl = TextEditingController(text: '500000');
    String selectedTeam = item.assignedTeam ?? 'NDRF Team Bravo-3 (Flood Rescue)';
    final availableTeams = [
      'NDRF Team Bravo-3 (Flood Rescue)',
      'NDRF 8th Bn Inflatable Boat Unit',
      'SDRF Heavy Drainage & Pumping Wing',
      'Civil Defence Quick Response Team',
      'CAT Ambulance & Emergency Medical Triage',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.gavel, color: AppColors.primaryGreen, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Magisterial Review & Sanction',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${item.id} • ${item.address}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.emerald50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.emerald200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppColors.emerald700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'SDRF Magisterial Sanction Authority: Priority Score ${item.priorityScore.toStringAsFixed(0)} PTS. Immediate relief allocation eligible.',
                          style: const TextStyle(fontSize: 11, color: AppColors.emerald800),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Sanction SDRF Emergency Relief (₹ INR) *:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: sanctionCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Assign Disaster Response Unit *:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: selectedTeam,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  items: availableTeams
                      .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedTeam = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final amount = sanctionCtrl.text.trim();
                ref.read(incidentsProvider.notifier).updateStatus(
                      item.id,
                      IncidentStatus.helpAssigned,
                      team: selectedTeam,
                    );
                ref.read(notificationsProvider.notifier).addAlertNotification(
                      title: '⚖️ SDRF Sanction: ₹$amount Approved (${item.id})',
                      body: 'Magistrate sanctioned relief funds. Deployed: $selectedTeam.',
                      severity: 'CRITICAL',
                      source: 'District Administration',
                      type: 'SOS',
                      direction: 'SENT',
                      status: 'SANCTIONED',
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ Sanctioned ₹$amount for "${item.title}". Deployed $selectedTeam.'),
                    backgroundColor: AppColors.primaryGreen,
                  ),
                );
              },
              child: const Text('Sanction & Deploy Unit', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _openRoleManagementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final users = ref.watch(systemUsersProvider);
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: AppColors.primaryGreen, size: 24),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Master Role & Access Governance',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: users.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final u = users[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.emerald50,
                              child: const Icon(Icons.person, color: AppColors.primaryGreen, size: 18),
                            ),
                            title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text('${u.role.title} • ${u.email}', style: const TextStyle(fontSize: 11)),
                            trailing: PopupMenuButton<UserRole>(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.emerald200),
                                ),
                                child: Text(
                                  u.role.title,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.emerald800),
                                ),
                              ),
                              itemBuilder: (context) => [
                                UserRole.citizen,
                                UserRole.volunteer,
                                UserRole.ngoLead,
                                UserRole.govtOfficial,
                                UserRole.rescueTeam,
                                UserRole.doctor,
                                UserRole.admin,
                              ].map((r) => PopupMenuItem(value: r, child: Text(r.title))).toList(),
                              onSelected: (newRole) {
                                ref.read(systemUsersProvider.notifier).updateUserRole(u.id, newRole);
                              },
                            ),
                          );
                        },
                      ),
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

  @override
  Widget build(BuildContext context) {
    final incidents = ref.watch(incidentsProvider);
    final currentUser = ref.watch(authProvider);
    final activeRole = ref.watch(activeRoleProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    final isAdmin = currentUser?.role == UserRole.admin || activeRole == UserRole.admin;

    final criticalCount = incidents.where((i) => i.priorityScore >= 80).length;
    final highCount = incidents.where((i) => i.priorityScore >= 60 && i.priorityScore < 80).length;
    final mediumCount = incidents.where((i) => i.priorityScore >= 35 && i.priorityScore < 60).length;
    final lowCount = incidents.where((i) => i.priorityScore < 35).length;

    return AppShell(
      currentRoute: AppRoutes.governmentCommandCentre,
      title: 'ResQAI',
      breadcrumbs: const ['Government', 'District Administration'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Master Admin Switcher Pill (if admin)
            if (isAdmin) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.emerald50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.emerald200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings, color: AppColors.emerald700, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Master Admin Access • Full System Governance Enabled',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.emerald800),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () => _openRoleManagementDialog(context),
                      child: const Text('Manage Roles', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.emerald700)),
                    ),
                  ],
                ),
              ),
            ],

            // 1. Top Deep Emerald Header Card (Screenshot 5 Center & Screenshot 3)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B), // Deep Emerald
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser?.name ?? 'District Administration',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'District National Capital Region (NCR)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'DISTRICT DISASTER MAGISTRATE (IAS) • ID: RQ-ADM-2026-001',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Department: DDMA / Revenue Administration',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.criticalRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.campaign, size: 18),
                      label: const Text(
                        'Issue Official Alert',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GovernmentOperationsScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 2. 4 Severity Summary Counters Row (Screenshot 5 Center)
            Row(
              children: [
                Expanded(
                  child: _buildSeverityCounter(
                    count: '$criticalCount',
                    label: 'Critical',
                    textColor: AppColors.criticalRed,
                    bgColor: AppColors.red50,
                    borderColor: AppColors.red200,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSeverityCounter(
                    count: '$highCount',
                    label: 'High',
                    textColor: AppColors.warningOrange,
                    bgColor: const Color(0xFFFFFBEB),
                    borderColor: const Color(0xFFFDE68A),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSeverityCounter(
                    count: '$mediumCount',
                    label: 'Medium',
                    textColor: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFEF3C7),
                    borderColor: const Color(0xFFFCD34D),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSeverityCounter(
                    count: '$lowCount',
                    label: 'Low',
                    textColor: AppColors.primaryGreen,
                    bgColor: AppColors.emerald50,
                    borderColor: AppColors.emerald200,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // 3. Priority Incident & Case Review Queue Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Priority Incident & Case Review Queue',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.governmentIncidents),
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

            // 4. Incident Stacked Cards List (Fix for Text Wrapping Bug)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: incidents.length,
              itemBuilder: (context, index) {
                final item = incidents[index];
                return _buildIncidentCard(item, isDark);
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityCounter({
    required String count,
    required String label,
    required Color textColor,
    required Color bgColor,
    required Color borderColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : borderColor),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey : textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(IncidentModel item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          // Row 1: Severity Badge Pill + Score + Right Arrow
          Row(
            children: [
              _buildSeverityPill(item.priorityScore),
              const SizedBox(width: 8),
              Text(
                '${item.priorityScore.toStringAsFixed(0)} PTS',
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: Title (Full unconstrained width - NO SQUEEZE)
          Text(
            item.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDark ? Colors.white : AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 4),

          // Row 3: Location
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.address,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 4: Reports Count, Timestamp, and Action Button
          Row(
            children: [
              const Icon(Icons.assignment_outlined, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${item.priorityScore.toInt()} reports',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.access_time, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              const Text(
                '2 hours ago',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const Spacer(),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: const BorderSide(color: AppColors.primaryGreen, width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _openReviewSanctionDialog(context, item),
                child: const Text(
                  'Review & Sanction',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),

          // Row 5: Deployed Unit (if assigned)
          if (item.assignedTeam != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.primaryGreen, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Deployed: ${item.assignedTeam}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeverityPill(double score) {
    if (score >= 80) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.red50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.red200),
        ),
        child: const Text('🔴 Critical', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.criticalRed)),
      );
    } else if (score >= 60) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Text('🟠 High', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.warningOrange)),
      );
    } else if (score >= 35) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCD34D)),
        ),
        child: const Text('🟡 Medium', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.emerald50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.emerald200),
        ),
        child: const Text('🟢 Low', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
      );
    }
  }
}
