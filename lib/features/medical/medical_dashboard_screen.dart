import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';
import 'medical_doctor_portal_screen.dart';

class MedicalDashboardScreen extends ConsumerWidget {
  const MedicalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final triageCases = ref.watch(triageCasesProvider);
    final hospitals = ref.watch(hospitalsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    final immediateRed = triageCases.where((t) => t.triageCategory.contains('RED')).length;
    final totalIcuBeds = hospitals.fold<int>(0, (sum, h) => sum + h.icuBedsAvailable);

    return AppShell(
      currentRoute: AppRoutes.medicalDashboard,
      title: 'Emergency Medical & Trauma Operations',
      breadcrumbs: const ['Medical', 'Dashboard'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Medical Doctor Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.criticalRed.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.medical_services, color: AppColors.criticalRed, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Emergency Casualty Triage & Referral Command', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('START Protocol Triage (Red/Yellow/Green/Black) • Bed Registry & Trauma Centers', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                  _buildMetricCard('IMMEDIATE RED (TRIAGE)', '$immediateRed Patients', AppColors.criticalRed, isDark),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard('AVAILABLE ICU BEDS', '$totalIcuBeds Beds', AppColors.primaryBlue, isDark)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildMetricCard('EMERGENCY HOSPITALS', '${hospitals.length} Centers', AppColors.successGreen, isDark)),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(child: _buildMetricCard('IMMEDIATE RED (TRIAGE)', '$immediateRed Patients', AppColors.criticalRed, isDark)),
                  const SizedBox(width: 14),
                  Expanded(child: _buildMetricCard('AVAILABLE ICU BEDS', '$totalIcuBeds Beds', AppColors.primaryBlue, isDark)),
                  const SizedBox(width: 14),
                  Expanded(child: _buildMetricCard('EMERGENCY HOSPITALS', '${hospitals.length} Centers', AppColors.successGreen, isDark)),
                ],
              ),
            const SizedBox(height: 24),

            // Triage Cases Queue
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
                  const Text('Active Casualty Intake Queue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 14),
                  for (final item in triageCases) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: item.triageCategory.contains('RED') ? AppColors.criticalRed.withOpacity(0.12) : AppColors.warningOrange.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.triageCategory,
                                        style: TextStyle(
                                          color: item.triageCategory.contains('RED') ? AppColors.criticalRed : AppColors.warningOrange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '${item.patientAgeGender} • ${item.conditionSummary}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('Location: ${item.location} • Required: ${item.urgencyNeeds}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Assigned Dr. Referral to ${hospitals.first.name}')),
                                      );
                                    },
                                    child: const Text('Refer Hospital Bed'),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: item.triageCategory.contains('RED') ? AppColors.criticalRed.withOpacity(0.12) : AppColors.warningOrange.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.triageCategory,
                                    style: TextStyle(
                                      color: item.triageCategory.contains('RED') ? AppColors.criticalRed : AppColors.warningOrange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${item.patientAgeGender} • ${item.conditionSummary}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text('Location: ${item.location} • Required: ${item.urgencyNeeds}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Assigned Dr. Referral to ${hospitals.first.name}')),
                                    );
                                  },
                                  child: const Text('Refer Hospital Bed'),
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

  Widget _buildMetricCard(String label, String value, Color color, bool isDark) {
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
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
