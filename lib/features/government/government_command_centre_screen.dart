import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/incident_repository.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';
import 'government_operations_screen.dart';

class GovernmentCommandCentreScreen extends ConsumerWidget {
  const GovernmentCommandCentreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidents = ref.watch(incidentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    final criticalQueue = incidents.where((i) => i.priorityScore >= 80).toList();
    final pendingVerifications = incidents.where((i) => i.status == IncidentStatus.received || i.status == IncidentStatus.pendingReview).toList();

    return AppShell(
      currentRoute: AppRoutes.governmentCommandCentre,
      title: 'State Disaster Management Authority (SDMA) Command',
      breadcrumbs: const ['Government', 'Command Centre'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Authority Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.criticalRed.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.criticalRed.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield, color: AppColors.criticalRed, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delhi Disaster Management Authority (DDMA) Operations Command',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'District Magistrate / ADM Relief Jurisdiction • 24/7 Live Incident Verification & SDRF Dispatch',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Command Metrics
            if (isMobile)
              Column(
                children: [
                  _buildKpiCard('CRITICAL EMERGENCIES', '${criticalQueue.length}', AppColors.criticalRed, isDark),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildKpiCard('PENDING REVIEWS', '${pendingVerifications.length}', AppColors.warningOrange, isDark)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildKpiCard('ACTIVE TEAMS', '12 Units', AppColors.primaryBlue, isDark)),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(child: _buildKpiCard('CRITICAL EMERGENCIES', '${criticalQueue.length}', AppColors.criticalRed, isDark)),
                  const SizedBox(width: 14),
                  Expanded(child: _buildKpiCard('PENDING VERIFICATIONS', '${pendingVerifications.length}', AppColors.warningOrange, isDark)),
                  const SizedBox(width: 14),
                  Expanded(child: _buildKpiCard('ACTIVE DISPATCH TEAMS', '12 Units', AppColors.primaryBlue, isDark)),
                ],
              ),
            const SizedBox(height: 24),

            // Quick Actions & Navigation
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.criticalRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.campaign),
                    label: const Text('Issue Official Alert', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GovernmentOperationsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.account_balance, size: 16),
                          label: const Text('SDRF Ledger', style: TextStyle(fontSize: 12)),
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.governmentFinancialTransparency),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.radar, size: 16),
                          label: const Text('Tactical Map', style: TextStyle(fontSize: 12)),
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.disasterMap),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.criticalRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.campaign),
                      label: const Text('Issue Official Alert', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GovernmentOperationsScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.account_balance),
                      label: const Text('SDRF Financial Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.governmentFinancialTransparency),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.radar),
                      label: const Text('Live Tactical Map', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.disasterMap),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Live Priority Incident Queue
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
                  const Text('Priority Intake & Case Review Queue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 14),
                  for (final item in incidents) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: isMobile
                          ? InkWell(
                              onTap: () {
                                Navigator.pushNamed(context, '${AppRoutes.citizenReports}/${item.id}');
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: item.priorityScore >= 80 ? AppColors.criticalRed.withOpacity(0.12) : AppColors.primaryBlue.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${item.priorityScore.toStringAsFixed(0)} PTS',
                                          style: TextStyle(
                                            color: item.priorityScore >= 80 ? AppColors.criticalRed : AppColors.primaryBlue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('ID: ${item.id}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      const Spacer(),
                                      const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.address,
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: item.priorityScore >= 80 ? AppColors.criticalRed.withOpacity(0.12) : AppColors.primaryBlue.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${item.priorityScore.toStringAsFixed(0)} PTS',
                                    style: TextStyle(
                                      color: item.priorityScore >= 80 ? AppColors.criticalRed : AppColors.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text('ID: ${item.id} • ${item.address}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '${AppRoutes.citizenReports}/${item.id}');
                                  },
                                  child: const Text('Review & Sanction Grant'),
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
}
