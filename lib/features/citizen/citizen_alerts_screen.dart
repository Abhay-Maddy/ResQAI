import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';
import '../../data/repositories/incident_repository.dart';

class CitizenAlertsScreen extends ConsumerStatefulWidget {
  const CitizenAlertsScreen({super.key});

  @override
  ConsumerState<CitizenAlertsScreen> createState() => _CitizenAlertsScreenState();
}

class _CitizenAlertsScreenState extends ConsumerState<CitizenAlertsScreen> {
  String _selectedTab = 'ALL'; // 'ALL', 'OFFICIAL', 'ADVISORY'
  bool _smsAlerts = true;
  bool _pushAlerts = true;
  bool _whatsappAlerts = true;

  void _showNotificationPreferences() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Notification Preferences',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select channels for official life-safety broadcasts from NDMA and district authorities.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Critical Push Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Bypasses Do Not Disturb for immediate evacuation alerts'),
                    value: _pushAlerts,
                    activeColor: AppColors.primaryBlue,
                    onChanged: (val) {
                      setModalState(() => _pushAlerts = val);
                      setState(() => _pushAlerts = val);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('SMS Early Warnings', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Fallback alerts when mobile data coverage is interrupted'),
                    value: _smsAlerts,
                    activeColor: AppColors.primaryBlue,
                    onChanged: (val) {
                      setModalState(() => _smsAlerts = val);
                      setState(() => _smsAlerts = val);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('WhatsApp Disaster Bulletins', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Daily flood maps, relief camp locations, and water levels'),
                    value: _whatsappAlerts,
                    activeColor: AppColors.successGreen,
                    onChanged: (val) {
                      setModalState(() => _whatsappAlerts = val);
                      setState(() => _whatsappAlerts = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Emergency notification preferences saved.'),
                            backgroundColor: AppColors.successGreen,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Save Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final alerts = ref.watch(alertsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return AppShell(
      currentRoute: AppRoutes.citizenAlerts,
      title: 'Emergency Warnings & Feed',
      breadcrumbs: const ['Citizen', 'Emergency Alerts'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Open Header (No decorative box)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Emergency Feed',
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.deepNavy,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Direct broadcasts from IMD, Central Water Commission & District Disaster Management Authorities',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _showNotificationPreferences,
                  icon: const Icon(Icons.tune, size: 16),
                  label: Text(isMobile ? 'Settings' : 'Preferences'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Tab Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabChip('All Bulletins (${alerts.length + 3})', _selectedTab == 'ALL', () => setState(() => _selectedTab = 'ALL')),
                  const SizedBox(width: 8),
                  _buildTabChip('Official Warnings (2)', _selectedTab == 'OFFICIAL', () => setState(() => _selectedTab = 'OFFICIAL'), color: AppColors.emergencyRed),
                  const SizedBox(width: 8),
                  _buildTabChip('Advisories & Relief (1)', _selectedTab == 'ADVISORY', () => setState(() => _selectedTab = 'ADVISORY'), color: AppColors.warningOrange),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Group 1: Urgent Official Warnings
            if (_selectedTab == 'ALL' || _selectedTab == 'OFFICIAL') ...[
              const Text(
                'URGENT BROADCASTS (DELHI-NCR)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.emergencyRed),
              ),
              const SizedBox(height: 10),

              // Alert 1: Hindon River
              _buildAlertDetailCard(
                context,
                title: 'Flood Watch • Hindon River Basin',
                severity: 'HIGH RISK',
                source: 'Central Water Commission (CWC) & IMD Delhi-NCR',
                time: '14 mins ago',
                description: 'Rising water levels in Hindon River due to upstream barrage discharge. Avoid low-lying riverbanks, Vaishali Sector 4 lowlands, and Kaushambi embankment zones. Follow official district evacuation instructions immediately.',
                actions: [
                  'Do not attempt to cross submerged roads or underpasses along NH-9.',
                  'Move valuable property and livestock to higher elevation sectors (Vasundhara / Indirapuram).',
                  'Keep emergency power banks, drinking water, and dry rations ready.',
                ],
                severityColor: AppColors.criticalRed,
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              // Alert 2: Yamuna River
              _buildAlertDetailCard(
                context,
                title: 'Yamuna Water Level Exceeded Danger Mark (205.33m)',
                severity: 'CRITICAL',
                source: 'Delhi Disaster Management Authority (DDMA)',
                time: '42 mins ago',
                description: 'Yamuna water level has surpassed the danger mark at Old Railway Bridge. Evacuation of floodplains in East Delhi (Yamuna Khadar) underway to designated relief camps.',
                actions: [
                  'All boat movement and recreational activities on riverbanks strictly prohibited under Section 144.',
                  'Evacuees are requested to report to the nearest verified relief shelter.',
                ],
                severityColor: AppColors.criticalRed,
                isDark: isDark,
              ),
              const SizedBox(height: 20),
            ],

            // Group 2: Advisories
            if (_selectedTab == 'ALL' || _selectedTab == 'ADVISORY') ...[
              const Text(
                'WEATHER ADVISORIES & RELIEF UPDATES',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.warningOrange),
              ),
              const SizedBox(height: 10),

              // Alert 3: Heavy Rain Yellow Alert
              _buildAlertDetailCard(
                context,
                title: 'Heavy Rainfall & Thunderstorm Yellow Alert',
                severity: 'MODERATE',
                source: 'IMD Meteorological Center, Safdarjung',
                time: '2 hours ago',
                description: 'Widespread moderate to heavy showers expected across NCR, Ghaziabad, Gautam Buddha Nagar, and East Delhi. Waterlogging possible in underpasses.',
                actions: [
                  'Avoid parking under old trees or unstable structures.',
                  'Check municipal pump station updates before traveling.',
                ],
                severityColor: AppColors.warningOrange,
                isDark: isDark,
              ),
              const SizedBox(height: 20),
            ],

            // Group 3: Statutory Emergency Helplines
            const Text(
              'STATUTORY 24X7 EMERGENCY HELPLINES',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildHelplineTile('112', 'National Emergency Response', AppColors.emergencyRed),
                  _buildHelplineTile('1077', 'District Disaster Control Room', AppColors.primaryBlue),
                  _buildHelplineTile('1070', 'State Disaster Management Control', AppColors.primaryBlue),
                  _buildHelplineTile('108', 'Free Emergency Ambulance', AppColors.successGreen),
                  _buildHelplineTile('101', 'Fire & Rescue Service', AppColors.warningOrange),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(String label, bool isSelected, VoidCallback onTap, {Color? color}) {
    final chipColor = color ?? AppColors.primaryBlue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : chipColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? chipColor : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : chipColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor.withOpacity(0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: severityColor.withOpacity(0.04),
            blurRadius: 8,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded, color: severityColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  severity,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? AppColors.darkTextPrimary : AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          const Text('Recommended Actions:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
