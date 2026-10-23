import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/incident_repository.dart';
import '../../features/auth/login_modal.dart';
import '../../features/responder/responder_dashboard.dart';
import '../../features/resources/shelter_board_screen.dart';
import '../../features/settings/system_health_screen.dart';
import '../../app.dart';

class RoleBasedDashboardScreen extends ConsumerWidget {
  const RoleBasedDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRole = ref.watch(activeRoleProvider);
    final currentUser = ref.watch(authProvider);

    return Scaffold(
      body: _buildDashboardForRole(context, ref, activeRole, currentUser),
    );
  }

  Widget _buildDashboardForRole(BuildContext context, WidgetRef ref, UserRole role, dynamic currentUser) {
    switch (role) {
      case UserRole.citizen:
        return _buildCitizenDashboard(context, ref, currentUser);
      case UserRole.fieldResponder:
        return _buildResponderDashboard(context, ref, currentUser);
      case UserRole.incidentCommander:
        return const ResponderDashboard(); // Full triage, What-If and duplicates
      case UserRole.ngoLead:
      case UserRole.reliefStaff:
        return const ShelterBoardScreen(); // Shelter capacity and supply matrix
      case UserRole.admin:
      case UserRole.analyst:
        return const SystemHealthScreen(); // Admin governance & audit
    }
  }

  // 1. CITIZEN SPECIFIC DASHBOARD
  Widget _buildCitizenDashboard(BuildContext context, WidgetRef ref, dynamic currentUser) {
    final incidents = ref.watch(incidentsProvider);
    final myIncidents = incidents.where((i) => i.source == 'CITIZEN_WEB' || i.source == 'ONE_TAP_SOS').toList();
    final shelters = ref.watch(sheltersProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Welcome Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.verifiedGreen.withOpacity(0.2), AppColors.darkSurfaceCard],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.verifiedGreen.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.verifiedGreen,
                  child: Text(
                    currentUser != null && currentUser.name.isNotEmpty ? currentUser.name[0].toUpperCase() : 'C',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Welcome, ${currentUser?.name ?? "Citizen"}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.verifiedGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('CITIZEN ACCESS', style: TextStyle(color: AppColors.verifiedGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Citizen Disaster ID: ${currentUser?.citizenId ?? "RQ-CIT-2026-1042"} • Ward: ${currentUser?.badgeOrJurisdiction ?? "Yamuna Khadar Ward 4"}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.contact_emergency, size: 14, color: AppColors.criticalRed),
                          const SizedBox(width: 4),
                          Text(
                            'Emergency SOS Contact: ${currentUser?.emergencyContactName ?? "Family"} (${currentUser?.emergencyContactPhone ?? "+91 98765 00112"})',
                            style: const TextStyle(fontSize: 11, color: AppColors.criticalRed, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                            child: Text('Blood: ${currentUser?.bloodGroup ?? "B+"}', style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Edit Card', style: TextStyle(fontSize: 12)),
                  onPressed: () => LoginModal.show(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick Action Cards
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => ref.read(currentTabProvider.notifier).state = MainNavigationTab.citizenSos,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.criticalRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.criticalRed),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.touch_app, color: AppColors.criticalRed, size: 28),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('1-Tap Emergency SOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.criticalRed)),
                            Text('Broadcast live GPS to rescue teams', style: TextStyle(fontSize: 11, color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: InkWell(
                  onTap: () => ref.read(currentTabProvider.notifier).state = MainNavigationTab.statusTracker,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.track_changes, color: AppColors.primaryLight, size: 28),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Track Incident Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryLight)),
                            Text('Check rescue status by Reference ID', style: TextStyle(fontSize: 11, color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // My Active Reports Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Emergency Reports & Status Progression', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('${myIncidents.length} Reports Tracked', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          if (myIncidents.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 36, color: AppColors.verifiedGreen),
                      const SizedBox(height: 8),
                      const Text('No Active Emergencies Reported', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('You have not logged any disaster incidents yet.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            )
          else
            ...myIncidents.map((inc) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                child: Text(inc.id, style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              const SizedBox(width: 10),
                              Text(inc.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          _buildStatusChip(inc.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(inc.descriptionOriginal, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(child: Text(inc.address, style: const TextStyle(fontSize: 11, color: Colors.grey))),
                          Text('Priority: ${inc.priorityScore.toStringAsFixed(1)}/100', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.criticalRed)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),

          // Safe Relocation Shelters (Nearest to Citizen)
          const Text('Nearest Verified Safe Relief Shelters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          ...shelters.take(2).map((s) {
            final bedsLeft = s.remainingBeds;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.verifiedGreen,
                  child: Icon(Icons.night_shelter, color: Colors.white, size: 20),
                ),
                title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Distance: 1.2 km • Water: ${s.waterLitersStock}L • Meals: ${s.foodMealsStock} pkts', style: const TextStyle(fontSize: 11)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.verifiedGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text('$bedsLeft beds left', style: const TextStyle(color: AppColors.verifiedGreen, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // 2. FIELD RESPONDER DASHBOARD
  Widget _buildResponderDashboard(BuildContext context, WidgetRef ref, dynamic currentUser) {
    final incidents = ref.watch(incidentsProvider);
    final activeMissions = incidents.where((i) => i.status == IncidentStatus.verified || i.status == IncidentStatus.helpAssigned).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tactical Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.local_hospital, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(currentUser?.name ?? 'Inspector Rajesh Kumar', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.4), borderRadius: BorderRadius.circular(4)),
                            child: const Text('NDRF BATTALION 4', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('GPS Check-in: 28.6139° N, 77.2090° E (Yamuna Lowland) • Battery: 94% • Radio: Channel 6', style: TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.verifiedGreen),
                  icon: const Icon(Icons.map, size: 16),
                  label: const Text('Open Tactical GIS', style: TextStyle(fontSize: 12)),
                  onPressed: () => ref.read(currentTabProvider.notifier).state = MainNavigationTab.tacticalMap,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Responder Mission Queue
          const Text('Active Dispatch Rescue Missions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),

          ...activeMissions.map((m) {
            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: AppColors.criticalRed.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                              child: Text(m.id, style: const TextStyle(color: AppColors.criticalRed, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            const SizedBox(width: 10),
                            Text(m.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        _buildStatusChip(m.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(m.descriptionOriginal, style: const TextStyle(fontSize: 13, height: 1.4)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(child: Text(m.address, style: const TextStyle(fontSize: 11, color: Colors.grey))),
                        Text('Severity: ${m.priorityScore.toStringAsFixed(1)}/100', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.criticalRed)),
                      ],
                    ),
                    const Divider(height: 20),

                    // 1-Tap Mission State Progression Buttons
                    Row(
                      children: [
                        const Text('Mission Action:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: () {
                            ref.read(incidentsProvider.notifier).updateStatus(m.id, IncidentStatus.helpAssigned);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Status updated: ${m.id} marked as Help Assigned (En Route)')),
                            );
                          },
                          child: const Text('En Route', style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.verifiedGreen),
                          onPressed: () {
                            ref.read(incidentsProvider.notifier).updateStatus(m.id, IncidentStatus.resolved);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Mission Completed: ${m.id} resolved successfully!')),
                            );
                          },
                          child: const Text('Mark Resolved', style: TextStyle(fontSize: 11, color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusChip(IncidentStatus status) {
    Color color;
    switch (status) {
      case IncidentStatus.received:
        color = Colors.blue;
        break;
      case IncidentStatus.underReview:
        color = Colors.orange;
        break;
      case IncidentStatus.verified:
        color = AppColors.verifiedGreen;
        break;
      case IncidentStatus.helpAssigned:
        color = AppColors.criticalRed;
        break;
      case IncidentStatus.resolved:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
      child: Text(status.label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
