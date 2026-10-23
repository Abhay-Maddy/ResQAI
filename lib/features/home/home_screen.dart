import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/incident_repository.dart';
import '../../app.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidents = ref.watch(incidentsProvider);
    final shelters = ref.watch(sheltersProvider);
    final volunteers = ref.watch(volunteersProvider);
    final currentUser = ref.watch(authProvider);

    final criticalCount = incidents.where((i) => i.priorityScore >= 80).length;
    final totalShelterCapacity = shelters.fold<int>(0, (sum, s) => sum + s.totalCapacity);
    final totalOccupancy = shelters.fold<int>(0, (sum, s) => sum + s.occupiedBeds);
    final availableBeds = totalShelterCapacity - totalOccupancy;
    final availableVolunteers = volunteers.where((v) => v.isAvailable).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. HERO BANNER
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryDark,
                  const Color(0xFF1E293B),
                  AppColors.darkSurfaceCard,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryLight),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.military_tech, size: 14, color: AppColors.primaryLight),
                          SizedBox(width: 6),
                          Text(
                            'College InnoTech Exhibition 2026 Edition',
                            style: TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (currentUser != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.verifiedGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Authenticated: ${currentUser.name} (${currentUser.role.title})',
                          style: const TextStyle(color: AppColors.verifiedGreen, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'AI-Powered Disaster Response &\nNeeds-Based Relief Management',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'One trusted platform that predicts disaster severity, verifies citizen emergencies, '
                  'coordinates rescue missions, and matches the right relief supplies to the right shelters with full auditability.',
                  style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
                ),
                const SizedBox(height: 24),

                // Hero Quick Buttons
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.criticalRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.emergency, size: 20),
                      label: const Text('1-Tap Emergency SOS', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        ref.read(currentTabProvider.notifier).state = MainNavigationTab.citizenSos;
                      },
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.dashboard, size: 20),
                      label: const Text('Command Center', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        ref.read(currentTabProvider.notifier).state = MainNavigationTab.commandCenter;
                      },
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.map, size: 20),
                      label: const Text('Live Tactical GIS'),
                      onPressed: () {
                        ref.read(currentTabProvider.notifier).state = MainNavigationTab.tacticalMap;
                      },
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.track_changes, size: 20),
                      label: const Text('Track Report Status'),
                      onPressed: () {
                        ref.read(currentTabProvider.notifier).state = MainNavigationTab.statusTracker;
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. LIVE ALERT BROADCAST TICKER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.warningAmber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warningAmber),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warningAmber, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'OFFICIAL NDMA / IMD LIVE BULLETIN: Orange Alert issued for Yamuna Lowland sectors. '
                    'Water levels recorded at 206.12m (0.8m above danger mark). NDRF Battalion 4 deployed on riverbank.',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(currentTabProvider.notifier).state = MainNavigationTab.officialAlerts;
                  },
                  child: const Text('View All Feeds', style: TextStyle(color: AppColors.warningAmber, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. LIVE DISTRICT METRICS (4 KPIS)
          const Text('District Emergency Telemetry (Live)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildKpiCard(
                    title: 'Active Incidents',
                    value: '${incidents.length}',
                    subtitle: 'Reports logged in queue',
                    icon: Icons.report_problem,
                    color: AppColors.primaryLight,
                    width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                  ),
                  _buildKpiCard(
                    title: 'High-Priority Rescue',
                    value: '$criticalCount',
                    subtitle: 'Score ≥80 (Life Critical)',
                    icon: Icons.emergency,
                    color: AppColors.criticalRed,
                    width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                  ),
                  _buildKpiCard(
                    title: 'Available Beds',
                    value: '$availableBeds',
                    subtitle: 'Across ${shelters.length} relief camps',
                    icon: Icons.night_shelter,
                    color: AppColors.verifiedGreen,
                    width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                  ),
                  _buildKpiCard(
                    title: 'Active Volunteers',
                    value: '$availableVolunteers',
                    subtitle: 'Boating, medical & rescue',
                    icon: Icons.volunteer_activism,
                    color: Colors.orangeAccent,
                    width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // 4. ROLE-BASED ACCESS PORTALS
          const Text('Select Your Operational Role Portal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Click any portal card to authenticate and enter role-specific command consoles:', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 14),

          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              final cardWidth = isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildPortalCard(
                    context: context,
                    ref: ref,
                    width: cardWidth,
                    title: 'Citizen Safety & SOS Portal',
                    subtitle: 'For residents, displaced families and community reporters',
                    badge: 'PUBLIC ACCESS',
                    badgeColor: AppColors.verifiedGreen,
                    icon: Icons.person,
                    features: [
                      '1-Tap Emergency SOS with automatic GPS broadcast',
                      'Bilingual incident reporting with voice note and photos',
                      'Public tracking stepper using reference ID (RQ-XXXX)',
                      'Family 72-hour survival kit preparedness checklist',
                    ],
                    buttonText: 'Enter Citizen Dashboard',
                    onTap: () {
                      ref.read(activeRoleProvider.notifier).state = UserRole.citizen;
                      ref.read(currentTabProvider.notifier).state = MainNavigationTab.citizenSos;
                    },
                  ),
                  _buildPortalCard(
                    context: context,
                    ref: ref,
                    width: cardWidth,
                    title: 'Field Responder Console',
                    subtitle: 'For NDRF rescue teams, boat crews and on-ground emergency units',
                    badge: 'DISPATCH UNIT',
                    badgeColor: AppColors.primaryLight,
                    icon: Icons.local_hospital,
                    features: [
                      'Interactive GIS map with closed submerged road avoidance',
                      '1-Tap Mission Progression: Accept → En Route → On Scene → Resolved',
                      'GPS location check-in and offline mutation sync queue',
                      'Direct route caution with NOT VERIFIED SAFE hazard warnings',
                    ],
                    buttonText: 'Enter Tactical Responder View',
                    onTap: () {
                      ref.read(activeRoleProvider.notifier).state = UserRole.fieldResponder;
                      ref.read(currentTabProvider.notifier).state = MainNavigationTab.tacticalMap;
                    },
                  ),
                  _buildPortalCard(
                    context: context,
                    ref: ref,
                    width: cardWidth,
                    title: 'Incident Commander Control',
                    subtitle: 'For District Magistrates, SDMA and Emergency Ops Chiefs',
                    badge: 'INCIDENT COMMAND',
                    badgeColor: AppColors.criticalRed,
                    icon: Icons.military_tech,
                    features: [
                      'District triage board with AI Explainable Priority scoring',
                      'What-If Simulation sliders (water depth, trapped counts, night-time)',
                      'Silent-Zone telecom blackout anomaly surveillance',
                      'Duplicate detection queue with human confirmation gate',
                    ],
                    buttonText: 'Enter Commander Console',
                    onTap: () {
                      ref.read(activeRoleProvider.notifier).state = UserRole.incidentCommander;
                      ref.read(currentTabProvider.notifier).state = MainNavigationTab.commandCenter;
                    },
                  ),
                  _buildPortalCard(
                    context: context,
                    ref: ref,
                    width: cardWidth,
                    title: 'NGO Relief & Supply Allocation',
                    subtitle: 'For Red Cross, humanitarian NGOs and shelter managers',
                    badge: 'RELIEF MATRIX',
                    badgeColor: Colors.orange,
                    icon: Icons.night_shelter,
                    features: [
                      'Live shelter board with bed occupancy & drinking water stock',
                      'Stale telemetry flag (>4h) preventing inaccurate capacity claims',
                      'Volunteer skill matching (medical, boating, chainsaw, translator)',
                      'Instant PDF & CSV situation report generation for logistics',
                    ],
                    buttonText: 'Enter Relief & Shelter Board',
                    onTap: () {
                      ref.read(activeRoleProvider.notifier).state = UserRole.ngoLead;
                      ref.read(currentTabProvider.notifier).state = MainNavigationTab.shelterBoard;
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // 5. OFFICIAL NATIONAL EMERGENCY HELPLINES BAR
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.phone_in_talk, color: AppColors.primaryLight, size: 20),
                    SizedBox(width: 8),
                    Text('Direct Emergency Helplines (24x7 National Dispatch)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    _buildHelplineChip('112', 'National Emergency Police/Fire/Rescue'),
                    _buildHelplineChip('1078', 'NDRF Central Disaster Control'),
                    _buildHelplineChip('1070', 'State Disaster Management Authority'),
                    _buildHelplineChip('108', 'Emergency Ambulance Services'),
                    _buildHelplineChip('1098', 'Child Emergency Helpline'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Footer Notice
          const Center(
            child: Text(
              'ResQAI • Built for College InnoTech Exhibition 2026 • AI-Assisted Decision Support System',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
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
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              CircleAvatar(
                radius: 14,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _buildPortalCard({
    required BuildContext context,
    required WidgetRef ref,
    required double width,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required List<String> features,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: badgeColor.withOpacity(0.15),
                child: Icon(icon, color: badgeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withOpacity(0.5)),
                ),
                child: Text(
                  badge,
                  style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: badgeColor),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f, style: const TextStyle(fontSize: 12, height: 1.3))),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: badgeColor.withOpacity(0.2),
                foregroundColor: Colors.white,
                side: BorderSide(color: badgeColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: Text(buttonText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              onPressed: onTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelplineChip(String number, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.call, size: 13, color: AppColors.verifiedGreen),
          const SizedBox(width: 6),
          Text(number, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.verifiedGreen)),
          const SizedBox(width: 6),
          Text('($label)', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
