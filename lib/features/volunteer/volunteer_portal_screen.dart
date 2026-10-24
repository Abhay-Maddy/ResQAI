import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';
import '../../data/repositories/auth_repository.dart';

class VolunteerTask {
  final String id;
  final String title;
  final String location;
  final String category; // 'Food Distribution', 'First Aid', 'Transport', 'Shelter Assistance'
  final String safetyLevel; // 'GREEN (Safe)', 'AMBER (Caution)'
  final String urgency;
  final List<String> requiredSkills;
  final String description;
  final String estimatedScope;
  final String? deadline;
  bool isAccepted;
  bool isCompleted;
  bool isDeclined;
  String? deliveryProofNote;

  VolunteerTask({
    required this.id,
    required this.title,
    required this.location,
    required this.category,
    required this.safetyLevel,
    required this.urgency,
    required this.requiredSkills,
    this.description = 'Provide frontline relief aid and coordinate with shelter wardens.',
    this.estimatedScope = '250 Displaced Beneficiaries',
    this.deadline = 'Today, 6:00 PM',
    this.isAccepted = false,
    this.isCompleted = false,
    this.isDeclined = false,
    this.deliveryProofNote,
  });
}

final volunteerTasksProvider = StateNotifierProvider<VolunteerTasksNotifier, List<VolunteerTask>>((ref) {
  return VolunteerTasksNotifier();
});

class VolunteerTasksNotifier extends StateNotifier<List<VolunteerTask>> {
  VolunteerTasksNotifier() : super(_initialTasks());

  static List<VolunteerTask> _initialTasks() {
    return [
      VolunteerTask(
        id: 'TASK-VOL-01',
        title: 'Distribute 250 Dry Food Rations & Water Pouches',
        location: 'Relief Camp Community Center, Mayur Vihar Ward 4',
        category: 'Food Distribution',
        safetyLevel: 'GREEN (Safe Logistic Zone)',
        urgency: 'HIGH',
        requiredSkills: ['Food Distribution', 'Shelter Care'],
        description: 'Distribute emergency relief kits containing flour, pulses, halogen tablets, and clean bottled water to displaced families.',
        estimatedScope: '250 Ration Packets • 50 Families',
        deadline: 'Today, 5:00 PM',
      ),
      VolunteerTask(
        id: 'TASK-VOL-02',
        title: 'First Aid Dressing & Blood Pressure Screening for Displaced Families',
        location: 'Government Primary School Safe Shelter',
        category: 'First Aid & Medical',
        safetyLevel: 'GREEN (Safe Logistic Zone)',
        urgency: 'CRITICAL',
        requiredSkills: ['First Aid Certified', 'Medical Care'],
        description: 'Assist Medical Officer with wound dressing for evacuees, ORS hydration distribution, and blood glucose checkups.',
        estimatedScope: '85 Evacuated Patients',
        deadline: 'Immediate Dispatch',
      ),
      VolunteerTask(
        id: 'TASK-VOL-03',
        title: 'Transport 15 Elderly Residents from Evacuation Staging to Camp 2',
        location: 'Yamuna Bund Staging Area',
        category: 'Transport',
        safetyLevel: 'AMBER (Caution - High Silt Road)',
        urgency: 'HIGH',
        requiredSkills: ['Vehicle Transport', 'Flood Rescue'],
        description: 'Coordinate minibus evacuation of senior citizens requiring assistance away from waterlogged embankment roads.',
        estimatedScope: '15 Senior Citizens • 2 Minibuses',
        deadline: 'Today, 4:30 PM',
      ),
      VolunteerTask(
        id: 'TASK-VOL-04',
        title: 'Set up 40 Emergency Sleeping Tents & Bedding Sets',
        location: 'East Delhi Sports Complex Evacuation Center',
        category: 'Shelter Assistance',
        safetyLevel: 'GREEN (Safe Logistic Zone)',
        urgency: 'NORMAL',
        requiredSkills: ['Shelter Care', 'Debris Clearing'],
        description: 'Assemble all-weather tarpaulin ridge tents and distribute mosquito nets, sleeping mats, and solar lanterns.',
        estimatedScope: '40 Tents • 160 Capacity',
        deadline: 'Tonight, 8:00 PM',
      ),
    ];
  }

  void acceptTask(String taskId) {
    state = state.map((t) {
      if (t.id == taskId) {
        t.isAccepted = true;
        t.isDeclined = false;
      }
      return t;
    }).toList();
  }

  void declineTask(String taskId) {
    state = state.map((t) {
      if (t.id == taskId) {
        t.isDeclined = true;
      }
      return t;
    }).toList();
  }

  void completeTask(String taskId, String proof) {
    state = state.map((t) {
      if (t.id == taskId) {
        t.isCompleted = true;
        t.deliveryProofNote = proof;
      }
      return t;
    }).toList();
  }
}

class VolunteerPortalScreen extends ConsumerStatefulWidget {
  const VolunteerPortalScreen({super.key});

  @override
  ConsumerState<VolunteerPortalScreen> createState() => _VolunteerPortalScreenState();
}

class _VolunteerPortalScreenState extends ConsumerState<VolunteerPortalScreen> {
  bool _isAvailable = true;
  final String _serviceArea = 'Yamuna Riverbank & East Delhi NCR';
  final List<String> _offeredSupport = [
    'Food & Water Distribution',
    'First Aid Assistance',
    'Relief Camp Support',
    'Language Translation',
  ];
  final Set<String> _processingTaskIds = {};

  void _reportHazardDialog() {
    final hazardCtrl = TextEditingController();
    final locationCtrl = TextEditingController(text: 'Road near Mayur Vihar Pocket 1');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.warningOrange),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warningOrange, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Report Route Hazard / Road Blockage',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Location / Road Landmark:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(controller: locationCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 12),
            const Text('Hazard Description (Submerged road, downed wire, silt):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(controller: hazardCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'e.g. 2 ft floodwater crossing NH-9 bypass', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warningOrange,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.warningOrange,
                  content: Text('✓ Hazard report registered. Tactical GIS map updated for all responder units.'),
                ),
              );
            },
            child: const Text('Broadcast Hazard', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _uploadProofDialog(VolunteerTask task) {
    final noteCtrl = TextEditingController(text: 'Assistance delivered; 250 ration packets distributed and audited.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.successGreen),
        ),
        title: const Row(
          children: [
            Icon(Icons.task_alt, color: AppColors.successGreen, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text('Record Completed Assistance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Task: ${task.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryBlue)),
            const SizedBox(height: 12),
            const Text('Delivery Proof / Field Completion Summary:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(controller: noteCtrl, maxLines: 2, decoration: const InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.photo_camera, size: 16, color: AppColors.successGreen),
                  SizedBox(width: 8),
                  Text('Field photo verified: delivery_receipt.jpg', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.successGreen, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(volunteerTasksProvider.notifier).completeTask(task.id, noteCtrl.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.successGreen,
                  content: Text('✓ Delivery verified and added to public transparency records.'),
                ),
              );
            },
            child: const Text('Confirm Completion', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAcceptTask(VolunteerTask task) async {
    setState(() => _processingTaskIds.add(task.id));
    await Future.delayed(const Duration(milliseconds: 300));
    ref.read(volunteerTasksProvider.notifier).acceptTask(task.id);
    if (mounted) {
      setState(() => _processingTaskIds.remove(task.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.successGreen,
          content: Text('✓ Task ${task.id} accepted! Added to your active missions.'),
        ),
      );
    }
  }

  void _handleDeclineTask(VolunteerTask task) {
    ref.read(volunteerTasksProvider.notifier).declineTask(task.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task ${task.id} removed from your queue.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider);
    final tasks = ref.watch(volunteerTasksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    final acceptedTasks = tasks.where((t) => t.isAccepted && !t.isCompleted).toList();
    final availableTasks = tasks.where((t) => !t.isAccepted && !t.isCompleted && !t.isDeclined).toList();
    final completedTasks = tasks.where((t) => t.isCompleted).toList();

    return AppShell(
      currentRoute: AppRoutes.volunteerTasks,
      title: 'Volunteer Operations Portal',
      breadcrumbs: const ['Volunteer', 'Tasks'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 28,
          vertical: isMobile ? 16 : 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // C1. VOLUNTEER PROFILE CARD (RESPONSIVE STACKED / MULTI-COLUMN)
            _buildVolunteerProfileCard(currentUser, isDark, isMobile),
            const SizedBox(height: 16),

            // C2. SAFETY DIRECTIVE CARD (NO UNNECESSARY UNDERLINES)
            _buildSafetyDirectiveCard(isDark),
            const SizedBox(height: 20),

            // ACTIVE ASSIGNMENTS IN PROGRESS
            if (acceptedTasks.isNotEmpty) ...[
              _buildActiveAssignmentsSection(acceptedTasks, isDark, isMobile),
              const SizedBox(height: 22),
            ],

            // C3 & C4. APPROVED COMMUNITY RELIEF NEEDS SECTION
            _buildAvailableTasksSection(availableTasks, isDark, isMobile),
            const SizedBox(height: 22),

            // COMPLETED CONTRIBUTION HISTORY
            if (completedTasks.isNotEmpty) ...[
              _buildCompletedHistorySection(completedTasks, isDark),
              const SizedBox(height: 30),
            ],

            const SizedBox(height: 60), // Safe area for mobile navigation
          ],
        ),
      ),
    );
  }

  // C1. VOLUNTEER PROFILE CARD
  Widget _buildVolunteerProfileCard(dynamic currentUser, bool isDark, bool isMobile) {
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Avatar, Name & Verification Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: isMobile ? 24 : 28,
                backgroundColor: Colors.teal.shade700,
                child: const Icon(Icons.volunteer_activism, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          currentUser?.name ?? 'Ananya Deshmukh',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: isMobile ? 16 : 18,
                            color: isDark ? Colors.white : AppColors.deepNavy,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.successGreen.withOpacity(0.4)),
                          ),
                          child: const Text(
                            'VERIFIED COMMUNITY VOLUNTEER',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: AppColors.successGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Volunteer ID: ${currentUser?.citizenId ?? "RQ-VOL-2026-081"} • Service Area: $_serviceArea',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Skills chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _offeredSupport.map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.teal.withOpacity(0.25)),
                ),
                child: Text(
                  s,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.teal.shade800,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Row 3: Availability Toggle & Report Hazard Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Availability Toggle with clear label
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isAvailable ? 'STATUS: AVAILABLE' : 'STATUS: OFF DUTY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _isAvailable ? AppColors.successGreen : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    value: _isAvailable,
                    activeColor: AppColors.successGreen,
                    onChanged: (v) => setState(() => _isAvailable = v),
                  ),
                ],
              ),

              // Report Hazard Action Button (Touch-Friendly)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warningOrange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 8 : 12,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.warning_amber_rounded, size: 16),
                label: const Text(
                  'Report Hazard',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: _reportHazardDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // C2. SAFETY DIRECTIVE CARD (NO UNWANTED UNDERLINING)
  Widget _buildSafetyDirectiveCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, color: AppColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Safety Directive (Statutory Civilian Guidelines)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Civilian volunteers are dispatched strictly to designated Safe Staging Camps, shelter distribution lines, and first aid stations. Never enter active river floodwaters or collapsed structures without NDRF command accompaniment.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: isDark ? Colors.white70 : AppColors.deepNavy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ACTIVE ASSIGNMENTS SECTION
  Widget _buildActiveAssignmentsSection(List<VolunteerTask> acceptedTasks, bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Active Task Assignments',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: isMobile ? 15 : 16,
                color: isDark ? Colors.white : AppColors.deepNavy,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.warningOrange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${acceptedTasks.length} IN PROGRESS',
                style: const TextStyle(
                  color: AppColors.warningOrange,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...acceptedTasks.map((task) {
          final cardBg = isDark ? AppColors.darkSurface : Colors.white;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.warningOrange.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 8,
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.warningOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        task.id,
                        style: const TextStyle(
                          color: AppColors.warningOrange,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        task.location,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Safety Zone: ${task.safetyLevel}',
                  style: const TextStyle(fontSize: 11, color: AppColors.successGreen, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.navigation_outlined, size: 16),
                      label: const Text('Open Map Route', style: TextStyle(fontSize: 12)),
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.disasterMap),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Complete & Upload Evidence', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => _uploadProofDialog(task),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // C3 & C4. APPROVED COMMUNITY RELIEF NEEDS SECTION
  Widget _buildAvailableTasksSection(List<VolunteerTask> availableTasks, bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Approved Community Relief Needs',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: isMobile ? 15 : 17,
                  color: isDark ? Colors.white : AppColors.deepNavy,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${availableTasks.length} Available',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Matching your volunteer skills & geographic service radius.',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText,
          ),
        ),
        const SizedBox(height: 12),

        if (availableTasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: const Center(
              child: Text(
                'No unassigned relief tasks in your sector right now. Check back soon.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
          )
        else
          ...availableTasks.map((task) {
            final isProcessing = _processingTaskIds.contains(task.id);
            final cardBg = isDark ? AppColors.darkSurface : Colors.white;
            final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: EdgeInsets.all(isMobile ? 14 : 18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Task ID + Priority Badge + Safety Level
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.id,
                          style: TextStyle(
                            color: Colors.teal.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: task.urgency == 'CRITICAL'
                              ? AppColors.emergencyRed.withOpacity(0.12)
                              : AppColors.warningOrange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.urgency,
                          style: TextStyle(
                            color: task.urgency == 'CRITICAL' ? AppColors.emergencyRed : AppColors.warningOrange,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.safetyLevel,
                          style: const TextStyle(
                            color: AppColors.successGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Task Title with natural wrapping
                  Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: isMobile ? 14 : 16,
                      height: 1.3,
                      color: isDark ? Colors.white : AppColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Location Row
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primaryBlue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          task.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Description & Estimated Scope
                  Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: isDark ? Colors.white70 : AppColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.people_alt_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Scope: ${task.estimatedScope} • Due: ${task.deadline}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Required Skills Chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: task.requiredSkills.map((sk) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          sk,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Action Buttons: Decline and Accept
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: isProcessing ? null : () => _handleDeclineTask(task),
                        child: const Text('Decline', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: isProcessing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.thumb_up_alt_outlined, size: 16),
                        label: Text(
                          isProcessing ? 'Claiming...' : 'Accept Assignment',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        onPressed: isProcessing ? null : () => _handleAcceptTask(task),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // COMPLETED HISTORY SECTION
  Widget _buildCompletedHistorySection(List<VolunteerTask> completedTasks, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Verified Contribution History',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 10),
        ...completedTasks.map((t) {
          final cardBg = isDark ? AppColors.darkSurface : Colors.white;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.successGreen,
                  child: Icon(Icons.check, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        'Completed: ${t.deliveryProofNote ?? "Audited relief delivery"}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'AUDITED',
                    style: TextStyle(
                      color: AppColors.successGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

