import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';
import '../../data/repositories/incident_repository.dart';

class CitizenAlertsScreen extends ConsumerWidget {
  const CitizenAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return AppShell(
      currentRoute: AppRoutes.citizenAlerts,
      title: 'Active Emergency Alerts',
      breadcrumbs: const ['Citizen', 'Emergency Alerts'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Prominent official warning bulletin banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.criticalRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.criticalRed.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.criticalRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.campaign, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Official Disaster Early Warning System (${alerts.length + 3} Active Bulletins)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.criticalRed,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Directly broadcast from IMD (India Meteorological Department), CWC (Central Water Commission), and NDMA.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Top Alert: Flood Watch Hindon River
            _buildAlertDetailCard(
              context,
              title: 'Flood Watch • 2.4 km away',
              severity: 'HIGH RISK',
              source: 'Central Water Commission (CWC) & IMD Delhi-NCR',
              time: 'Updated 14 mins ago',
              description: 'Rising water levels in Hindon River due to upstream barrage discharge. Avoid low-lying riverbanks, Vaishali Sector 4 lowlands, and Kaushambi embankment zones. Follow official district evacuation instructions immediately.',
              actions: [
                'Do not attempt to cross submerged roads or underpasses along NH-9.',
                'Move valuable property and livestock to higher elevation sectors (Vasundhara / Indirapuram).',
                'Keep emergency power banks, drinking water, and dry rations ready.',
              ],
              severityColor: AppColors.criticalRed,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Secondary Alert: Yamuna Khadar Inundation Advisory
            _buildAlertDetailCard(
              context,
              title: 'Yamuna River Level Advisory (Level 3 Warning)',
              severity: 'CRITICAL',
              source: 'Delhi Disaster Management Authority (DDMA)',
              time: 'Updated 42 mins ago',
              description: 'Yamuna water level has surpassed the danger mark of 205.33 meters at Old Railway Bridge. Evacuation of floodplains in East Delhi (Yamuna Khadar) underway to designated relief camps.',
              actions: [
                'All boat movement and recreational activities on riverbanks strictly prohibited under Section 144.',
                'Evacuees are requested to report to the nearest verified relief shelter.',
              ],
              severityColor: AppColors.criticalRed,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // General Weather Alert: Heavy Rainfall Yellow Alert
            _buildAlertDetailCard(
              context,
              title: 'Heavy Rainfall & Thunderstorm Warning',
              severity: 'MODERATE',
              source: 'IMD Meteorological Center',
              time: 'Valid next 24 hours',
              description: 'Widespread moderate to heavy showers expected across NCR, Ghaziabad, Gautam Buddha Nagar, and East Delhi. Waterlogging possible in underpasses.',
              actions: [
                'Avoid parking under old trees or unstable structures.',
                'Check municipal pump station updates before traveling.',
              ],
              severityColor: AppColors.warningOrange,
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // Emergency Helplines Card
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
                  const Row(
                    children: [
                      Icon(Icons.phone_in_talk, color: AppColors.primaryBlue, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Statutory Emergency Helplines (24x7 Toll-Free)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      _buildHelplineTile('112', 'National Emergency Response', AppColors.emergencyRed),
                      _buildHelplineTile('1077', 'District Disaster Control Room', AppColors.primaryBlue),
                      _buildHelplineTile('1070', 'State Disaster Management Control', AppColors.primaryBlue),
                      _buildHelplineTile('108', 'Free Emergency Medical Ambulance', AppColors.successGreen),
                      _buildHelplineTile('101', 'Fire & Rescue Service', AppColors.warningOrange),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertDetailCard(
    BuildContext context, {
    required String title,
    required String severity,
    required String source,
    required String time,
    required String description,
    required List<String> actions,
    required Color severityColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: severityColor.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: severityColor.withOpacity(0.06),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded, color: severityColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.deepNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$source • $time',
                      style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  severity,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: isDark ? AppColors.darkTextPrimary : AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 14),
          const Text('Recommended Protective Actions:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ...actions.map(
            (act) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: 14, color: severityColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(act, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelplineTile(String number, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.phone, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            number,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
