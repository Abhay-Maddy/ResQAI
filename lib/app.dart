import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/i18n.dart';
import 'data/repositories/incident_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'features/auth/login_modal.dart';
import 'features/auth/admin_verification_modal.dart';

import 'features/home/home_screen.dart';
import 'features/dashboard/role_based_dashboard_screen.dart';
import 'features/citizen/report_sos_wizard.dart';
import 'features/citizen/public_status_tracker.dart';
import 'features/responder/responder_dashboard.dart';
import 'features/responder/tactical_map_screen.dart';
import 'features/resources/shelter_board_screen.dart';
import 'features/resources/volunteer_matcher_screen.dart';
import 'features/alerts/official_alerts_screen.dart';
import 'features/alerts/rumor_misinformation_tracker.dart';
import 'features/alerts/sms_whatsapp_intake_simulator.dart';
import 'features/ai/silent_zone_detector.dart';
import 'features/preparedness/preparedness_screen.dart';
import 'features/analytics/situation_summary_generator.dart';
import 'features/settings/system_health_screen.dart';
import 'features/transparency/public_transparency_portal_screen.dart';

enum MainNavigationTab {
  home('Home Portal', Icons.home, 'Overview'),
  roleDashboard('Role Dashboard', Icons.dashboard_customize, 'Role Hub'),
  citizenSos('Report & SOS', Icons.emergency, 'Citizen'),
  statusTracker('Public Status', Icons.track_changes, 'Public'),
  commandCenter('Command Center', Icons.dashboard, 'Responder'),
  tacticalMap('Tactical GIS Map', Icons.map, 'Operations'),
  shelterBoard('Shelter & Stocks', Icons.night_shelter, 'Relief'),
  officialAlerts('Official Feeds', Icons.campaign, 'Alerts'),
  smsGateway('SMS/WhatsApp Intake', Icons.sms, 'Intake'),
  silentZone('Silent-Zone Anomaly', Icons.signal_cellular_off, 'AI Sensor'),
  rumorTracker('Rumor Tracker', Icons.fact_check, 'Truth'),
  volunteerMatching('Volunteer Match', Icons.handshake, 'Volunteers'),
  preparedness('Preparedness Mode', Icons.shield, 'Checklists'),
  sitrepAnalytics('SitRep & Review', Icons.analytics, 'Analytics'),
  publicTransparency('Public Transparency', Icons.account_balance, 'Public'),
  systemHealth('System Health', Icons.monitor_heart, 'Admin');

  final String label;
  final IconData icon;
  final String category;
  const MainNavigationTab(this.label, this.icon, this.category);
}

final currentTabProvider = StateProvider<MainNavigationTab>((ref) => MainNavigationTab.home);
final isDarkThemeProvider = StateProvider<bool>((ref) => true);

class ResQAIApp extends ConsumerWidget {
  const ResQAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkThemeProvider);

    return MaterialApp(
      title: 'ResQAI — Disaster Response System',
      debugShowCheckedModeBanner: false,
      theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: const MainLayoutScreen(),
    );
  }
}

class MainLayoutScreen extends ConsumerWidget {
  const MainLayoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);
    final activeRole = ref.watch(activeRoleProvider);
    final currentLang = ref.watch(languageProvider);
    final isDark = ref.watch(isDarkThemeProvider);
    final currentUser = ref.watch(authProvider);
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => ref.read(currentTabProvider.notifier).state = MainNavigationTab.home,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield, color: AppColors.primaryLight, size: 22),
                SizedBox(width: 8),
                Text(
                  AppConstants.appName,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.8),
                ),
              ],
            ),
          ),
        ),
        actions: [
          // DDMA Admin Authorization Queue Shortcut (Part 4-D)
          if (currentUser?.role == UserRole.admin) ...[
            Builder(
              builder: (context) {
                final pendingCount = ref.watch(pendingApprovalsProvider).where((u) => u.verificationStatus == 'PENDING').length;
                return IconButton(
                  icon: Badge(
                    isLabelVisible: pendingCount > 0,
                    label: Text('$pendingCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                    backgroundColor: AppColors.criticalRed,
                    child: const Icon(Icons.admin_panel_settings, color: Colors.purpleAccent, size: 20),
                  ),
                  tooltip: 'DDMA Authorization Queue ($pendingCount pending)',
                  onPressed: () => AdminVerificationModal.show(context),
                );
              },
            ),
            const SizedBox(width: 4),
          ],

          // Login / Profile Button for Every User
          if (currentUser == null)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              icon: const Icon(Icons.login, size: 14),
              label: const Text('Login', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: () => LoginModal.show(context),
            )
          else
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => LoginModal.show(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: currentUser.verificationStatus == 'APPROVED' 
                        ? AppColors.primary.withOpacity(0.5)
                        : AppColors.warningAmber,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: currentUser.verificationStatus == 'APPROVED' ? AppColors.primary : AppColors.warningAmber,
                      child: Text(
                        currentUser.name.isNotEmpty ? currentUser.name[0].toUpperCase() : 'U',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: currentUser.verificationStatus == 'APPROVED' ? Colors.white : Colors.black),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      currentUser.name.split(' ').first,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      currentUser.verificationStatus == 'APPROVED' ? Icons.arrow_drop_down : Icons.hourglass_top,
                      size: 16,
                      color: currentUser.verificationStatus == 'APPROVED' ? Colors.grey : AppColors.warningAmber,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 6),

          // Role Switcher Dropdown (Feature 11 & Role-based Access)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: DropdownButton<UserRole>(
              value: activeRole,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryLight, size: 18),
              items: UserRole.values.map((r) {
                return DropdownMenuItem(
                  value: r,
                  child: Text(r.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                );
              }).toList(),
              onChanged: (newRole) {
                if (newRole != null) {
                  ref.read(activeRoleProvider.notifier).state = newRole;
                  ref.read(currentTabProvider.notifier).state = MainNavigationTab.roleDashboard;
                }
              },
            ),
          ),
          const SizedBox(width: 6),

          // Bilingual Language Toggle Button (Feature 1: Multilingual Reporting)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              side: const BorderSide(color: AppColors.primary),
            ),
            icon: const Icon(Icons.translate, size: 14, color: AppColors.primaryLight),
            label: Text(
              currentLang == 'en' ? 'हिंदी' : 'EN',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
            ),
            onPressed: () {
              ref.read(languageProvider.notifier).state = currentLang == 'en' ? 'hi' : 'en';
            },
          ),
          const SizedBox(width: 4),

          // Dark/Light Theme Toggle
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 18),
            tooltip: 'Toggle Theme',
            onPressed: () => ref.read(isDarkThemeProvider.notifier).state = !isDark,
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildAppDrawer(context, ref, currentTab),
      body: Column(
        children: [
          // Persistent Pending Verification Alert Banner (Part 4-D)
          if (currentUser?.verificationStatus == 'PENDING')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.warningAmber.withOpacity(0.92),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top, color: Colors.black, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Account Verification Pending: Your credentials as ${currentUser!.role.title} (${currentUser.organization ?? currentUser.badgeOrJurisdiction}) are awaiting DDMA review. Read-only preview enabled.',
                      style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  InkWell(
                    onTap: () => LoginModal.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Review Slip', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildCurrentView(currentTab)),
        ],
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = MediaQuery.of(context).size.width < 768;
          if (!isMobile) {
            return Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: AppColors.darkSurfaceCard,
              child: Row(
                children: [
                  const Icon(Icons.wifi, size: 14, color: AppColors.verifiedGreen),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Connected to Secure Emergency Command Network',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${activeRole.title} Console • All Systems Operational',
                    style: const TextStyle(fontSize: 11, color: AppColors.primaryLight, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }

          // Mobile App-Like Bottom Navigation Bar
          return NavigationBar(
            height: 64,
            backgroundColor: AppColors.darkSurfaceCard,
            indicatorColor: AppColors.primary.withOpacity(0.3),
            selectedIndex: _getMobileNavIndex(currentTab),
            onDestinationSelected: (index) {
              _handleMobileNavSelection(context, ref, scaffoldKey, index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: AppColors.primaryLight),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.emergency_outlined, color: AppColors.criticalRed),
                selectedIcon: Icon(Icons.emergency, color: AppColors.criticalRed),
                label: 'SOS Report',
              ),
              NavigationDestination(
                icon: Icon(Icons.track_changes_outlined),
                selectedIcon: Icon(Icons.track_changes, color: AppColors.primaryLight),
                label: 'Track',
              ),
              NavigationDestination(
                icon: Icon(Icons.dashboard_customize_outlined),
                selectedIcon: Icon(Icons.dashboard_customize, color: AppColors.primaryLight),
                label: 'Role Hub',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu),
                selectedIcon: Icon(Icons.menu_open, color: AppColors.primaryLight),
                label: 'More',
              ),
            ],
          );
        },
      ),
    );
  }

  int _getMobileNavIndex(MainNavigationTab tab) {
    switch (tab) {
      case MainNavigationTab.home:
        return 0;
      case MainNavigationTab.citizenSos:
        return 1;
      case MainNavigationTab.statusTracker:
        return 2;
      case MainNavigationTab.roleDashboard:
        return 3;
      default:
        return 4; // 'More'
    }
  }

  void _handleMobileNavSelection(BuildContext context, WidgetRef ref, GlobalKey<ScaffoldState> scaffoldKey, int index) {
    switch (index) {
      case 0:
        ref.read(currentTabProvider.notifier).state = MainNavigationTab.home;
        break;
      case 1:
        ref.read(currentTabProvider.notifier).state = MainNavigationTab.citizenSos;
        break;
      case 2:
        ref.read(currentTabProvider.notifier).state = MainNavigationTab.statusTracker;
        break;
      case 3:
        ref.read(currentTabProvider.notifier).state = MainNavigationTab.roleDashboard;
        break;
      case 4:
        scaffoldKey.currentState?.openDrawer();
        break;
    }
  }

  Widget _buildAppDrawer(BuildContext context, WidgetRef ref, MainNavigationTab currentTab) {
    final currentUser = ref.watch(authProvider);

    return Drawer(
      backgroundColor: AppColors.darkSurface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primaryDark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield, size: 28, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text(
                      'ResQAI Portal',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.manage_accounts, color: Colors.white),
                      tooltip: 'Login / Switch Account',
                      onPressed: () {
                        Navigator.pop(context);
                        LoginModal.show(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          currentUser?.name.isNotEmpty == true ? currentUser!.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser?.name ?? 'Guest User',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              currentUser != null ? '${currentUser.role.title} • ${currentUser.badgeOrJurisdiction}' : 'Not Signed In',
                              style: const TextStyle(color: Colors.white70, fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.login, color: AppColors.primaryLight, size: 20),
            title: Text(
              currentUser == null ? 'Sign In / Register' : 'Switch Account / Role',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
            ),
            subtitle: Text(
              currentUser == null ? 'Sign in to access authorized tools' : 'Logged in as ${currentUser.role.title}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            onTap: () {
              Navigator.pop(context);
              LoginModal.show(context);
            },
          ),
          const Divider(color: AppColors.darkBorder, height: 1),
          ...MainNavigationTab.values.map((tab) {
            final isSelected = tab == currentTab;
            return ListTile(
              leading: Icon(tab.icon, color: isSelected ? AppColors.primaryLight : Colors.grey, size: 20),
              title: Text(
                tab.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primaryLight : Colors.white70,
                ),
              ),
              trailing: Text(tab.category, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              selected: isSelected,
              selectedTileColor: AppColors.primary.withOpacity(0.12),
              onTap: () {
                ref.read(currentTabProvider.notifier).state = tab;
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCurrentView(MainNavigationTab tab) {
    switch (tab) {
      case MainNavigationTab.home:
        return const HomeScreen();
      case MainNavigationTab.roleDashboard:
        return const RoleBasedDashboardScreen();
      case MainNavigationTab.citizenSos:
        return const ReportSosWizard();
      case MainNavigationTab.statusTracker:
        return const PublicStatusTracker();
      case MainNavigationTab.commandCenter:
        return const ResponderDashboard();
      case MainNavigationTab.tacticalMap:
        return const TacticalMapScreen();
      case MainNavigationTab.shelterBoard:
        return const ShelterBoardScreen();
      case MainNavigationTab.officialAlerts:
        return const OfficialAlertsScreen();
      case MainNavigationTab.smsGateway:
        return const SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: SmsWhatsappIntakeSimulator(),
        );
      case MainNavigationTab.silentZone:
        return const SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: SilentZoneDetector(),
        );
      case MainNavigationTab.rumorTracker:
        return const RumorMisinformationTracker();
      case MainNavigationTab.volunteerMatching:
        return const VolunteerMatcherScreen();
      case MainNavigationTab.preparedness:
        return const PreparednessScreen();
      case MainNavigationTab.sitrepAnalytics:
        return const SituationSummaryGenerator();
      case MainNavigationTab.publicTransparency:
        return const PublicTransparencyPortalScreen();
      case MainNavigationTab.systemHealth:
        return const SystemHealthScreen();
    }
  }
}
