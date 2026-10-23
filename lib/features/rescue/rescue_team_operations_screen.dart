import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets/truth_badge_widget.dart';

enum RescueMissionStage {
  dispatched,
  enRoute,
  onScene,
  resolved,
}

class RescueMission {
  final String id;
  final String incidentId;
  final String title;
  final String location;
  final String gpsCoordinates;
  final int strandedVictimsCount;
  final String hazardLevel; // 'CRITICAL (Water Depth 2.8m, Swift Current)', 'HIGH', 'MODERATE'
  final String specialRisks;
  RescueMissionStage stage;
  final String reportedTime;
  int? victimsEvacuated;
  String? evacuationShelter;
  String? debriefNotes;

  RescueMission({
    required this.id,
    required this.incidentId,
    required this.title,
    required this.location,
    required this.gpsCoordinates,
    required this.strandedVictimsCount,
    required this.hazardLevel,
    required this.specialRisks,
    this.stage = RescueMissionStage.dispatched,
    required this.reportedTime,
    this.victimsEvacuated,
    this.evacuationShelter,
    this.debriefNotes,
  });
}

final rescueMissionsProvider = StateNotifierProvider<RescueMissionsNotifier, List<RescueMission>>((ref) {
  return RescueMissionsNotifier();
});

class RescueMissionsNotifier extends StateNotifier<List<RescueMission>> {
  RescueMissionsNotifier() : super(_initialMissions());

  static List<RescueMission> _initialMissions() {
    return [
      RescueMission(
        id: 'MISSION-NDRF-01',
        incidentId: 'INC-2026-001',
        title: 'Rooftop Evacuation of 14 Civilians & 2 Infants',
        location: 'Yamuna Khadar Lowland Settlement, Ward 4',
        gpsCoordinates: '28.6219° N, 77.2798° E',
        strandedVictimsCount: 14,
        hazardLevel: 'CRITICAL (Water Level 2.6m, Rising 8cm/hr)',
        specialRisks: 'Submerged 11kV electrical cables; floating steel debris',
        stage: RescueMissionStage.enRoute,
        reportedTime: '24 mins ago',
      ),
      RescueMission(
        id: 'MISSION-NDRF-02',
        incidentId: 'INC-2026-005',
        title: 'Trapped Senior Citizens in Submerged Ground Floor Compound',
        location: 'Kashmere Gate Lowland Enclave, Gali 3',
        gpsCoordinates: '28.6672° N, 77.2285° E',
        strandedVictimsCount: 5,
        hazardLevel: 'HIGH (Water Level 1.9m)',
        specialRisks: 'Two non-ambulatory wheelchair patients requiring stretcher lift',
        stage: RescueMissionStage.dispatched,
        reportedTime: '12 mins ago',
      ),
      RescueMission(
        id: 'MISSION-NDRF-03',
        incidentId: 'INC-2026-003',
        title: 'Search & Clear Shanty Clusters near Railway Culvert',
        location: 'Old Iron Bridge Eastern Embankment',
        gpsCoordinates: '28.6548° N, 77.2410° E',
        strandedVictimsCount: 8,
        hazardLevel: 'MODERATE (Water Level 1.2m)',
        specialRisks: 'Silt accumulation blocking motorized boat propeller',
        stage: RescueMissionStage.resolved,
        reportedTime: '2 hrs ago',
        victimsEvacuated: 8,
        evacuationShelter: 'Mayur Vihar Community Relief Camp',
        debriefNotes: 'All 8 individuals safely evacuated via Inflatable Rescue Boat 02 without casualties.',
      ),
    ];
  }

  void advanceStage(String missionId, RescueMissionStage nextStage, {int? evacuated, String? shelter, String? notes}) {
    state = [
      for (final m in state)
        if (m.id == missionId)
          RescueMission(
            id: m.id,
            incidentId: m.incidentId,
            title: m.title,
            location: m.location,
            gpsCoordinates: m.gpsCoordinates,
            strandedVictimsCount: m.strandedVictimsCount,
            hazardLevel: m.hazardLevel,
            specialRisks: m.specialRisks,
            stage: nextStage,
            reportedTime: m.reportedTime,
            victimsEvacuated: evacuated ?? m.victimsEvacuated,
            evacuationShelter: shelter ?? m.evacuationShelter,
            debriefNotes: notes ?? m.debriefNotes,
          )
        else
          m
    ];
  }
}

class RescueTeamOperationsScreen extends ConsumerStatefulWidget {
  const RescueTeamOperationsScreen({super.key});

  @override
  ConsumerState<RescueTeamOperationsScreen> createState() => _RescueTeamOperationsScreenState();
}

class _RescueTeamOperationsScreenState extends ConsumerState<RescueTeamOperationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _operationalReadiness = 'MISSION READY (ALPHA-1)';

  final Map<String, dynamic> _equipmentInventory = {
    'Inflatable Motorized Rescue Boats (IRBs)': {'total': 8, 'deployed': 5, 'ready': 3},
    'Life Jackets & High-Buoyancy Vests': {'total': 180, 'deployed': 95, 'ready': 85},
    'FLIR Thermal SAR Recon Drones': {'total': 4, 'deployed': 2, 'ready': 2},
    'Hydraulic Cutters & Heavy Spreaders': {'total': 6, 'deployed': 2, 'ready': 4},
    'Submersible Mud & Slurry Pumps (50HP)': {'total': 4, 'deployed': 3, 'ready': 1},
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openResolutionDialog(RescueMission mission) {
    final countController = TextEditingController(text: mission.strandedVictimsCount.toString());
    final shelterController = TextEditingController(text: 'Mayur Vihar Safe Relief Enclave');
    final notesController = TextEditingController(text: 'All victims safely rescued and transferred to medical reception.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: AppColors.verifiedGreen, size: 22),
            SizedBox(width: 8),
            Text('Complete Rescue Mission & Debrief', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mission: ${mission.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 12),
              const Text('Confirmed Evacuated Persons Count *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: countController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.darkSurfaceCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Designated Relief Shelter Delivered To *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: shelterController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.darkSurfaceCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Tactical Debrief Notes *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.darkSurfaceCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.verifiedGreen),
            onPressed: () {
              final count = int.tryParse(countController.text) ?? mission.strandedVictimsCount;
              ref.read(rescueMissionsProvider.notifier).advanceStage(
                mission.id,
                RescueMissionStage.resolved,
                evacuated: count,
                shelter: shelterController.text,
                notes: notesController.text,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Mission ${mission.id} marked RESOLVED. $count citizens evacuated safely.'),
                  backgroundColor: AppColors.verifiedGreen,
                ),
              );
            },
            child: const Text('Submit Debrief & Close Mission'),
          ),
        ],
      ),
    );
  }

  void _requestAerialSupportDialog() {
    final reasonController = TextEditingController(text: 'Air winch evacuation required for rooftop cluster cut off by rapid current.');
    final zoneController = TextEditingController(text: 'Yamuna Khadar Sector 4 (28.6219° N, 77.2798° E)');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.criticalRed),
        ),
        title: const Row(
          children: [
            Icon(Icons.airplanemode_active, color: AppColors.criticalRed, size: 22),
            SizedBox(width: 8),
            Text('Requisition Aerial Support (IAF / Coast Guard)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Part 12 Compliance: Requisitions are transmitted to State Emergency Operations Center (SEOC) and Defense Liaison Officer.', style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 12),
              const Text('Support Type:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceCard,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('IAF Mi-17 / Chetak Winch Rescue Chopper', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.warningAmber)),
              ),
              const SizedBox(height: 12),
              const Text('Target Drop / Winch Zone *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: zoneController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.darkSurfaceCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Operational Justification *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.darkSurfaceCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.criticalRed),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Aerial Support Requisition transmitted to SEOC Air Cell. Dispatch Ref: RQ-AERIAL-092.'),
                  backgroundColor: AppColors.verifiedGreen,
                ),
              );
            },
            child: const Text('Authorize Tactical Requisition'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final missions = ref.watch(rescueMissionsProvider);
    final activeMissions = missions.where((m) => m.stage != RescueMissionStage.resolved).toList();
    final currentUser = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.criticalRed.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield, color: AppColors.criticalRed, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rescue Operations Command', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('NDRF & SDRF Tactical Evacuation Portal', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: Chip(
              backgroundColor: AppColors.verifiedGreen.withOpacity(0.2),
              side: const BorderSide(color: AppColors.verifiedGreen),
              avatar: const Icon(Icons.radio, color: AppColors.verifiedGreen, size: 14),
              label: Text(
                _operationalReadiness,
                style: const TextStyle(color: AppColors.verifiedGreen, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.criticalRed,
          labelColor: AppColors.criticalRed,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              icon: const Icon(Icons.radar, size: 18),
              text: 'Active Missions (${activeMissions.length})',
            ),
            const Tab(
              icon: Icon(Icons.construction, size: 18),
              text: 'Equipment & Fleet',
            ),
            const Tab(
              icon: Icon(Icons.badge, size: 18),
              text: 'Unit Dossier',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMissionsTab(missions),
          _buildEquipmentTab(),
          _buildUnitDossierTab(currentUser),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.criticalRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.airplanemode_active),
        label: const Text('Requisition Aerial Support', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _requestAerialSupportDialog,
      ),
    );
  }

  Widget _buildMissionsTab(List<RescueMission> missions) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tactical Alert Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.criticalRed.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning, color: AppColors.criticalRed, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Operational Rule: Rescue dispatch progresses through 4 strict verification gates: Dispatched → En Route → On Scene → Evacuation Resolved. Maintain radio contact on VHF Channel 4.',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: missions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final m = missions[index];
              final isResolved = m.stage == RescueMissionStage.resolved;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isResolved ? Colors.white12 : AppColors.criticalRed.withOpacity(0.5),
                    width: isResolved ? 1 : 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _stageColor(m.stage).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _stageColor(m.stage)),
                          ),
                          child: Text(
                            _stageTitle(m.stage),
                            style: TextStyle(color: _stageColor(m.stage), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(m.id, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
                        const Spacer(),
                        Text(m.reportedTime, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(m.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(child: Text('${m.location} (${m.gpsCoordinates})', style: const TextStyle(fontSize: 12, color: Colors.grey))),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Hazard and Victims Grid
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.criticalRed.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.people, size: 16, color: AppColors.criticalRed),
                                const SizedBox(width: 6),
                                Text('${m.strandedVictimsCount} Trapped Civilians', style: const TextStyle(color: AppColors.criticalRed, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.darkSurfaceCard,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.water, size: 16, color: Colors.lightBlueAccent),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(m.hazardLevel, style: const TextStyle(fontSize: 11, color: Colors.white70), overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurfaceCard,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.report_problem, size: 16, color: AppColors.warningAmber),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text('Special Risks: ${m.specialRisks}', style: const TextStyle(fontSize: 11, color: AppColors.warningAmber)),
                          ),
                        ],
                      ),
                    ),

                    if (isResolved) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.verifiedGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.verifiedGreen.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: AppColors.verifiedGreen, size: 16),
                                const SizedBox(width: 6),
                                Text('Debrief: ${m.victimsEvacuated} Persons Safely Evacuated', style: const TextStyle(color: AppColors.verifiedGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Shelter Destination: ${m.evacuationShelter}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                            if (m.debriefNotes != null)
                              Text('Notes: ${m.debriefNotes}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // 4-Stage Dispatch Stepper / Progression Buttons
                    if (!isResolved)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Stage: ${_stageTitle(m.stage)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          if (m.stage == RescueMissionStage.dispatched)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.warningAmber, foregroundColor: Colors.black),
                              icon: const Icon(Icons.directions_boat, size: 16),
                              label: const Text('Mark EN ROUTE', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () {
                                ref.read(rescueMissionsProvider.notifier).advanceStage(m.id, RescueMissionStage.enRoute);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Unit Alpha moving En Route to ${m.location}. GPS transponder active.')),
                                );
                              },
                            )
                          else if (m.stage == RescueMissionStage.enRoute)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyBlue),
                              icon: const Icon(Icons.pin_drop, size: 16),
                              label: const Text('Mark ON SCENE'),
                              onPressed: () {
                                ref.read(rescueMissionsProvider.notifier).advanceStage(m.id, RescueMissionStage.onScene);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Unit arrived on scene at ${m.location}. Commencing rescue boats.')),
                                );
                              },
                            )
                          else if (m.stage == RescueMissionStage.onScene)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.verifiedGreen),
                              icon: const Icon(Icons.verified, size: 16),
                              label: const Text('Record Evacuation Complete'),
                              onPressed: () => _openResolutionDialog(m),
                            ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildEquipmentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tactical Equipment & Fleet Logistics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Part 12 Compliance: Track available, deployed, and reserve disaster response hardware.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _equipmentInventory.keys.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final key = _equipmentInventory.keys.elementAt(index);
              final item = _equipmentInventory[key] as Map<String, dynamic>;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.darkSurfaceCard,
                      child: Icon(Icons.hardware, color: AppColors.warningAmber, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Deployed: ${item['deployed']} • Standby Reserve: ${item['ready']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.verifiedGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.verifiedGreen.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Total: ${item['total']}',
                        style: const TextStyle(color: AppColors.verifiedGreen, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reserve Depots Linked', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                SizedBox(height: 6),
                Text('• SDRF Central Depot, Sector 19 Rohini\n• NDRF 8th Battalion Regional Response Center, Ghaziabad\n• Delhi Flood Control Yard, Yamuna Bazar', style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildUnitDossierTab(dynamic currentUser) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.criticalRed.withOpacity(0.2), AppColors.darkSurface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.criticalRed.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.criticalRed,
                  child: Icon(Icons.shield, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(currentUser?.name ?? 'NDRF Team Alpha (8th Bn)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          const TruthBadgeWidget(type: TruthBadgeType.verifiedSafe, customText: 'VERIFIED NDRF'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Commander: Insp. Vikram Rathore • Badge #NDRF-2024-88', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const Text('Specialization: Urban Flood Evacuation & Deep Water Diving', style: TextStyle(fontSize: 12, color: AppColors.criticalRed)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          const Text('Tactical Capability & Operational Scope', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _dossierRow(Icons.groups, 'Unit Strength', '24 Combat Divers, 6 Boat Pilots, 4 Paramedics, 2 K9 Units'),
          _dossierRow(Icons.call, 'VHF Radio Callsign & Freq', 'CALLSIGN: RESCUE-ALPHA-8 • 156.800 MHz (Channel 16)'),
          _dossierRow(Icons.explore, 'Operational Sector', 'Trans-Yamuna Basin (Wards 1 through 7)'),
          _dossierRow(Icons.security, 'Authorized Under', 'National Disaster Management Act 2005 (Section 44)'),
          _dossierRow(Icons.check_circle_outline, 'Successful Rescues (2026)', '184 Persons Evacuated to Safe Shelters'),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Statutory Emergency Dispatch Rule (Part 12)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                SizedBox(height: 6),
                Text(
                  'No rescue operation may be simulated or marked resolved without recorded debrief verification including confirmed victim count and designated safe shelter destination.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dossierRow(IconData icon, String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.criticalRed),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _stageColor(RescueMissionStage stage) {
    switch (stage) {
      case RescueMissionStage.dispatched:
        return AppColors.criticalRed;
      case RescueMissionStage.enRoute:
        return AppColors.warningAmber;
      case RescueMissionStage.onScene:
        return AppColors.navyBlue;
      case RescueMissionStage.resolved:
        return AppColors.verifiedGreen;
    }
  }

  String _stageTitle(RescueMissionStage stage) {
    switch (stage) {
      case RescueMissionStage.dispatched:
        return 'DISPATCHED';
      case RescueMissionStage.enRoute:
        return 'EN ROUTE';
      case RescueMissionStage.onScene:
        return 'ON SCENE';
      case RescueMissionStage.resolved:
        return 'EVACUATION COMPLETE';
    }
  }
}
