import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';

class VolunteerTask {
  final String id;
  final String title;
  final String location;
  final String category; // 'Food Distribution', 'First Aid', 'Transport', 'Shelter Assistance'
  final String safetyLevel; // 'GREEN (Safe)', 'AMBER (Caution)'
  final String urgency;
  final List<String> requiredSkills;
  bool isAccepted;
  bool isCompleted;
  String? deliveryProofNote;

  VolunteerTask({
    required this.id,
    required this.title,
    required this.location,
    required this.category,
    required this.safetyLevel,
    required this.urgency,
    required this.requiredSkills,
    this.isAccepted = false,
    this.isCompleted = false,
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
      ),
      VolunteerTask(
        id: 'TASK-VOL-02',
        title: 'First Aid Dressing & Blood Pressure Screening for Displaced Families',
        location: 'Government Primary School Safe Shelter',
        category: 'First Aid & Medical',
        safetyLevel: 'GREEN (Safe Logistic Zone)',
        urgency: 'CRITICAL',
        requiredSkills: ['First Aid Certified', 'Medical Care'],
      ),
      VolunteerTask(
        id: 'TASK-VOL-03',
        title: 'Transport 15 Elderly Residents from Evacuation Staging to Camp 2',
        location: 'Yamuna Bund Staging Area',
        category: 'Transport',
        safetyLevel: 'AMBER (Caution - High Silt Road)',
        urgency: 'HIGH',
        requiredSkills: ['Vehicle Transport', 'Flood Rescue'],
      ),
      VolunteerTask(
        id: 'TASK-VOL-04',
        title: 'Set up 40 Emergency Sleeping Tents & Bedding Sets',
        location: 'East Delhi Sports Complex Evacuation Center',
        category: 'Shelter Assistance',
        safetyLevel: 'GREEN (Safe Logistic Zone)',
        urgency: 'NORMAL',
        requiredSkills: ['Shelter Care', 'Debris Clearing'],
      ),
    ];
  }

  void acceptTask(String taskId) {
    state = state.map((t) {
      if (t.id == taskId) {
        t.isAccepted = true;
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
  final List<String> _offeredSupport = ['Food & Water Distribution', 'First Aid Assistance', 'Relief Camp Support'];

  void _reportHazardDialog() {
    final hazardCtrl = TextEditingController();
    final locationCtrl = TextEditingController(text: 'Road near Mayur Vihar Pocket 1');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.warningAmber),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.warningAmber, size: 22),
            SizedBox(width: 8),
            Text('Report Road Hazard / Blocked Route', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Location / Road Landmark:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(controller: locationCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 10),
            const Text('Hazard Description (e.g. Submerged culvert, downed wire):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(controller: hazardCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Describe route hazard', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warningAmber, foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.warningAmber,
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
    final noteCtrl = TextEditingController(text: '250 ration packets distributed; verified by Shelter Warden.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.verifiedGreen),
        ),
        title: const Row(
          children: [
            Icon(Icons.task_alt, color: AppColors.verifiedGreen, size: 22),
            SizedBox(width: 8),
            Text('Record Completed Assistance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Task: ${task.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryLight)),
            const SizedBox(height: 10),
            const Text('Delivery Proof / Field Completion Summary:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(controller: noteCtrl, maxLines: 2, decoration: const InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(6)),
              child: const Row(
                children: [
                  Icon(Icons.photo_camera, size: 16, color: AppColors.verifiedGreen),
                  SizedBox(width: 6),
                  Text('Field photo attached: delivery_proof_img.jpg', style: TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.verifiedGreen, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(volunteerTasksProvider.notifier).completeTask(task.id, noteCtrl.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.verifiedGreen,
                  content: Text('✓ Delivery verified and added to public transparency records.'),
                ),
              );
            },
            child: const Text('Mark Complete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider);
    final tasks = ref.watch(volunteerTasksProvider);
    final acceptedTasks = tasks.where((t) => t.isAccepted && !t.isCompleted).toList();
    final availableTasks = tasks.where((t) => !t.isAccepted && !t.isCompleted).toList();
    final completedTasks = tasks.where((t) => t.isCompleted).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Volunteer Profile Banner (Part 8)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade900, AppColors.darkSurfaceCard],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.teal.shade400.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.teal.shade400,
                  child: const Icon(Icons.volunteer_activism, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            currentUser?.name ?? 'Pooja Sharma',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.verifiedGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.verifiedGreen),
                            ),
                            child: const Text('VERIFIED COMMUNITY VOLUNTEER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.verifiedGreen)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Volunteer ID: ${currentUser?.citizenId ?? "RQ-VOL-2026-081"} • Service Area: $_serviceArea',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: _offeredSupport.map((s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)),
                          child: Text(s, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        Text(_isAvailable ? 'AVAILABLE' : 'OFF DUTY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _isAvailable ? AppColors.verifiedGreen : Colors.grey)),
                        Switch(
                          value: _isAvailable,
                          activeColor: AppColors.verifiedGreen,
                          onChanged: (v) => setState(() => _isAvailable = v),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warningAmber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: const Icon(Icons.report, size: 14),
                      label: const Text('Report Hazard', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: _reportHazardDialog,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Volunteer Safety Directive (Part 8: Do not automatically direct untrained volunteers into dangerous zones)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.infoBlue.withOpacity(0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield, color: AppColors.infoBlue, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Safety Directive (Part 8): Civilian volunteers are dispatched strictly to designated Safe Staging Camps, shelter distribution lines, and first aid stations. Never enter active river water or collapsed structures without NDRF accompaniment.',
                    style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Active Assignments Queue
          if (acceptedTasks.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('My Active Task Assignments:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${acceptedTasks.length} in progress', style: const TextStyle(fontSize: 12, color: Colors.orange)),
              ],
            ),
            const SizedBox(height: 10),
            ...acceptedTasks.map((t) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: AppColors.darkSurfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.orange),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                          child: const Text('IN PROGRESS', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Location: ${t.location}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    Text('Zone: ${t.safetyLevel}', style: const TextStyle(fontSize: 11, color: AppColors.verifiedGreen)),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.pin_drop, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        const Text('GPS Route navigation available in Tactical GIS', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const Spacer(),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.verifiedGreen),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Complete & Upload Evidence', style: TextStyle(fontSize: 12)),
                          onPressed: () => _uploadProofDialog(t),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 16),
          ],

          // Location-Aware Task Recommendations (Part 8)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Approved Community Relief Needs (Matching Your Skills):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('${availableTasks.length} Available', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),

          if (availableTasks.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('No unassigned relief tasks in your immediate sector right now.', style: TextStyle(color: Colors.grey)),
                ),
              ),
            )
          else
            ...availableTasks.map((task) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: AppColors.darkSurfaceCard,
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
                                decoration: BoxDecoration(color: Colors.teal.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                child: Text(task.id, style: TextStyle(color: Colors.teal.shade300, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.verifiedGreen.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                            child: Text(task.safetyLevel, style: const TextStyle(color: AppColors.verifiedGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(child: Text(task.location, style: const TextStyle(fontSize: 12, color: Colors.white70))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: task.urgency == 'CRITICAL' ? Colors.red.withOpacity(0.2) : Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                            child: Text(task.urgency, style: TextStyle(color: task.urgency == 'CRITICAL' ? Colors.redAccent : Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        children: task.requiredSkills.map((sk) => Chip(
                          label: Text(sk, style: const TextStyle(fontSize: 10)),
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.white.withOpacity(0.06),
                        )).toList(),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Task ${task.id} declined.')),
                              );
                            },
                            child: const Text('Decline', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            icon: const Icon(Icons.thumb_up, size: 14),
                            label: const Text('Accept Assignment', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              ref.read(volunteerTasksProvider.notifier).acceptTask(task.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.verifiedGreen,
                                  content: Text('✓ Task ${task.id} accepted! Added to your mission queue.'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 20),

          // Completed History (Part 8: Contribution History)
          if (completedTasks.isNotEmpty) ...[
            const Text('My Verified Contribution History:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            ...completedTasks.map((t) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: AppColors.darkSurfaceCard,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.verifiedGreen,
                  child: Icon(Icons.check, color: Colors.white, size: 18),
                ),
                title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Completed: ${t.deliveryProofNote ?? "Verified by Shelter Team"}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.verifiedGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                  child: const Text('VERIFIED & AUDITED', style: TextStyle(color: AppColors.verifiedGreen, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }
}
