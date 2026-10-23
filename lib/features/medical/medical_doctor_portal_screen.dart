import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets/truth_badge_widget.dart';

class MedicalTriageCase {
  final String id;
  final String incidentId;
  final String patientAgeGender;
  final String conditionSummary;
  final String triageCategory; // 'RED (Immediate)', 'YELLOW (Urgent)', 'GREEN (Minor)'
  final String location;
  final String urgencyNeeds;
  bool isAccepted;
  String status; // 'PENDING_TRIAGE', 'ATTENDING', 'REFERRED', 'STABILIZED'
  String? attendingDoctorNotes;
  String? referredHospital;

  MedicalTriageCase({
    required this.id,
    required this.incidentId,
    required this.patientAgeGender,
    required this.conditionSummary,
    required this.triageCategory,
    required this.location,
    required this.urgencyNeeds,
    this.isAccepted = false,
    this.status = 'PENDING_TRIAGE',
    this.attendingDoctorNotes,
    this.referredHospital,
  });
}

class HospitalCapacity {
  final String name;
  final String location;
  final int totalBeds;
  final int occupiedBeds;
  final int icuBedsAvailable;
  final int oxygenBedsAvailable;
  final String bloodBankStatus;
  final String emergencyPhone;
  final String lastUpdated;

  HospitalCapacity({
    required this.name,
    required this.location,
    required this.totalBeds,
    required this.occupiedBeds,
    required this.icuBedsAvailable,
    required this.oxygenBedsAvailable,
    required this.bloodBankStatus,
    required this.emergencyPhone,
    required this.lastUpdated,
  });

  int get availableBeds => totalBeds - occupiedBeds;
}

final medicalCasesProvider = StateNotifierProvider<MedicalCasesNotifier, List<MedicalTriageCase>>((ref) {
  return MedicalCasesNotifier();
});

final triageCasesProvider = medicalCasesProvider;

final hospitalsProvider = Provider<List<HospitalCapacity>>((ref) {
  return [
    HospitalCapacity(
      name: 'AIIMS Trauma Center & Emergency',
      location: 'Ring Road, Ansari Nagar (8.2 km)',
      totalBeds: 240,
      occupiedBeds: 218,
      icuBedsAvailable: 6,
      oxygenBedsAvailable: 16,
      bloodBankStatus: 'Adequate (O+, B+, AB+ available)',
      emergencyPhone: '+91 11 2658 8700',
      lastUpdated: '12 mins ago (Real-time sync)',
    ),
    HospitalCapacity(
      name: 'LNJP Hospital & Disaster Ward',
      location: 'Delhi Gate, New Delhi (5.4 km)',
      totalBeds: 180,
      occupiedBeds: 154,
      icuBedsAvailable: 4,
      oxygenBedsAvailable: 22,
      bloodBankStatus: 'Moderate (O- and A- in high demand)',
      emergencyPhone: '+91 11 2323 3000',
      lastUpdated: '25 mins ago',
    ),
    HospitalCapacity(
      name: 'Lal Bahadur Shastri District Hospital',
      location: 'Khichripur, Mayur Vihar (2.1 km)',
      totalBeds: 110,
      occupiedBeds: 92,
      icuBedsAvailable: 2,
      oxygenBedsAvailable: 16,
      bloodBankStatus: 'Urgent donor call requested for B-',
      emergencyPhone: '+91 11 2277 4145',
      lastUpdated: '40 mins ago',
    ),
  ];
});

class MedicalCasesNotifier extends StateNotifier<List<MedicalTriageCase>> {
  MedicalCasesNotifier() : super(_initialCases());

  static List<MedicalTriageCase> _initialCases() {
    return [
      MedicalTriageCase(
        id: 'MED-CASE-01',
        incidentId: 'INC-2026-001',
        patientAgeGender: 'Male, 48 yrs • Family of 4',
        conditionSummary: 'Severe laceration from submerged tin roofing; high fever and dirty flood water exposure',
        triageCategory: 'YELLOW (Urgent)',
        location: 'Yamuna Flood Plains Ward 4, Rescue Point B',
        urgencyNeeds: 'Tetanus Toxoid, Suture Dressing Kit, IV Cefotaxime',
      ),
      MedicalTriageCase(
        id: 'MED-CASE-02',
        incidentId: 'INC-2026-003',
        patientAgeGender: 'Elderly Female, 72 yrs',
        conditionSummary: 'Type-1 diabetic with lost insulin pens during evacuation; signs of diabetic ketoacidosis (lethargy)',
        triageCategory: 'RED (Immediate)',
        location: 'Mayur Vihar Safe Camp Community Center',
        urgencyNeeds: 'Regular Insulin (40 IU), Glucometer, Normal Saline 500ml IV',
      ),
      MedicalTriageCase(
        id: 'MED-CASE-03',
        incidentId: 'INC-2026-004',
        patientAgeGender: 'Child, 6 yrs',
        conditionSummary: 'Mild hypothermia, acute dehydration from water-borne gastroenteritis',
        triageCategory: 'YELLOW (Urgent)',
        location: 'East Delhi Flood Relief Enclave Camp',
        urgencyNeeds: 'Pediatric ORS sachets, Zinc supplements, Ondansetron syrup',
      ),
      MedicalTriageCase(
        id: 'MED-CASE-04',
        incidentId: 'INC-2026-002',
        patientAgeGender: 'Female, 31 yrs',
        conditionSummary: 'Blunt ankle trauma following boundary wall collapse during rainstorm; suspected hairline fracture',
        triageCategory: 'GREEN (Minor)',
        location: 'Shahdara Drainage Sector 2 Camp',
        urgencyNeeds: 'Crepe bandage, immobilization splint, analgesics',
      ),
    ];
  }

  void acceptCase(String caseId) {
    state = [
      for (final c in state)
        if (c.id == caseId)
          MedicalTriageCase(
            id: c.id,
            incidentId: c.incidentId,
            patientAgeGender: c.patientAgeGender,
            conditionSummary: c.conditionSummary,
            triageCategory: c.triageCategory,
            location: c.location,
            urgencyNeeds: c.urgencyNeeds,
            isAccepted: true,
            status: 'ATTENDING',
            attendingDoctorNotes: 'Doctor on triage duty responding.',
          )
        else
          c
    ];
  }

  void updateTreatmentOutcome(String caseId, String status, String notes, {String? referredHospital}) {
    state = [
      for (final c in state)
        if (c.id == caseId)
          MedicalTriageCase(
            id: c.id,
            incidentId: c.incidentId,
            patientAgeGender: c.patientAgeGender,
            conditionSummary: c.conditionSummary,
            triageCategory: c.triageCategory,
            location: c.location,
            urgencyNeeds: c.urgencyNeeds,
            isAccepted: true,
            status: status,
            attendingDoctorNotes: notes,
            referredHospital: referredHospital,
          )
        else
          c
    ];
  }
}

class MedicalDoctorPortalScreen extends ConsumerStatefulWidget {
  const MedicalDoctorPortalScreen({super.key});

  @override
  ConsumerState<MedicalDoctorPortalScreen> createState() => _MedicalDoctorPortalScreenState();
}

class _MedicalDoctorPortalScreenState extends ConsumerState<MedicalDoctorPortalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isOnDuty = true;

  final List<HospitalCapacity> _hospitals = [
    HospitalCapacity(
      name: 'AIIMS Trauma Center & Emergency',
      location: 'Ring Road, Ansari Nagar (8.2 km)',
      totalBeds: 240,
      occupiedBeds: 218,
      icuBedsAvailable: 6,
      oxygenBedsAvailable: 16,
      bloodBankStatus: 'Adequate (O+, B+, AB+ available)',
      emergencyPhone: '+91 11 2658 8700',
      lastUpdated: '12 mins ago (Real-time sync)',
    ),
    HospitalCapacity(
      name: 'LNJP Hospital & Disaster Ward',
      location: 'Delhi Gate, New Delhi (5.4 km)',
      totalBeds: 180,
      occupiedBeds: 154,
      icuBedsAvailable: 4,
      oxygenBedsAvailable: 22,
      bloodBankStatus: 'Moderate (O- and A- in high demand)',
      emergencyPhone: '+91 11 2323 3000',
      lastUpdated: '25 mins ago',
    ),
    HospitalCapacity(
      name: 'Lal Bahadur Shastri District Hospital',
      location: 'Khichripur, Mayur Vihar (2.1 km)',
      totalBeds: 110,
      occupiedBeds: 92,
      icuBedsAvailable: 2,
      oxygenBedsAvailable: 16,
      bloodBankStatus: 'Urgent donor call requested for B-',
      emergencyPhone: '+91 11 2277 4145',
      lastUpdated: '40 mins ago',
    ),
  ];

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

  void _openTreatmentDialog(MedicalTriageCase triageCase) {
    final notesController = TextEditingController(text: triageCase.attendingDoctorNotes ?? '');
    String selectedStatus = 'STABILIZED';
    String? selectedHospital = _hospitals.first.name;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.darkSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.navyBlue),
            ),
            title: Row(
              children: [
                const Icon(Icons.medical_services, color: AppColors.warningAmber, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Clinical Action: ${triageCase.id}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Patient Summary:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      '${triageCase.patientAgeGender}\n${triageCase.conditionSummary}\nLocation: ${triageCase.location}',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text('Clinical Action Status *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    items: const [
                      DropdownMenuItem(value: 'STABILIZED', child: Text('Stabilized & Managed at Camp')),
                      DropdownMenuItem(value: 'REFERRED', child: Text('Referred to Tertiary Care Hospital')),
                      DropdownMenuItem(value: 'ATTENDING', child: Text('Treatment In Progress (Monitoring)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedStatus = val);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.darkSurfaceCard,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (selectedStatus == 'REFERRED') ...[
                    const Text('Destination Hospital Referral *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedHospital,
                      items: _hospitals.map((h) => DropdownMenuItem(value: h.name, child: Text(h.name, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (val) => setDialogState(() => selectedHospital = val),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.darkSurfaceCard,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  const Text('Doctor Notes & Prescription Regimen *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Administered IV fluids, dressed wound, vital signs: BP 120/80, SpO2 98%...',
                      filled: true,
                      fillColor: AppColors.darkSurfaceCard,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Notice: In accordance with statutory medical guidelines, sensitive patient identifiers are preserved strictly on authorized channels.', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.verifiedGreen),
                icon: const Icon(Icons.check_circle, size: 16),
                label: const Text('Record Clinical Record'),
                onPressed: () {
                  ref.read(medicalCasesProvider.notifier).updateTreatmentOutcome(
                    triageCase.id,
                    selectedStatus,
                    notesController.text.trim().isEmpty ? 'Clinical triage completed.' : notesController.text.trim(),
                    referredHospital: selectedStatus == 'REFERRED' ? selectedHospital : null,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Medical case ${triageCase.id} successfully updated to $selectedStatus.'),
                      backgroundColor: AppColors.verifiedGreen,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _requestMedicalSuppliesDialog() {
    final itemController = TextEditingController(text: 'Dextrose Normal Saline (500ml x 50), Ampicillin IV (100 vials)');
    final qtyController = TextEditingController(text: '150 units');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.inventory_2, color: AppColors.warningAmber, size: 22),
            SizedBox(width: 8),
            Text('Requisition Emergency Medical Supplies', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Requisition routed directly to District Chief Medical Officer (CMO) and SDRF Central Medical Depot.', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 12),
            const Text('Supplies Required *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(
              controller: itemController,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.darkSurfaceCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Urgency Level:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.criticalRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.criticalRed.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.priority_high, color: AppColors.criticalRed, size: 16),
                  SizedBox(width: 6),
                  Text('PRIORITY 1: DISASTER MEDICAL DEPOT EXPEDITE', style: TextStyle(color: AppColors.criticalRed, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warningAmber),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Requisition for ${qtyController.text} dispatched to District CMO. Order Ref: RQ-MED-DEPOT-882.'),
                  backgroundColor: AppColors.verifiedGreen,
                ),
              );
            },
            child: const Text('Submit Supply Requisition', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider);
    final medicalCases = ref.watch(medicalCasesProvider);

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
                color: AppColors.warningAmber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_hospital, color: AppColors.warningAmber, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Medical & Doctor Portal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Field Triage, Emergency Clinical Support & Bed Registry', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              avatar: Icon(_isOnDuty ? Icons.check_circle : Icons.pause_circle_outline, color: _isOnDuty ? AppColors.verifiedGreen : Colors.grey, size: 16),
              label: Text(_isOnDuty ? 'ON DUTY' : 'STANDBY', style: TextStyle(color: _isOnDuty ? AppColors.verifiedGreen : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
              selected: _isOnDuty,
              onSelected: (val) => setState(() => _isOnDuty = val),
              backgroundColor: AppColors.darkSurfaceCard,
              selectedColor: AppColors.verifiedGreen.withOpacity(0.15),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.warningAmber,
          labelColor: AppColors.warningAmber,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              icon: const Icon(Icons.emergency, size: 18),
              text: 'Triage Queue (${medicalCases.where((c) => c.status != "STABILIZED").length})',
            ),
            const Tab(
              icon: Icon(Icons.apartment, size: 18),
              text: 'Hospital Beds & ICU',
            ),
            const Tab(
              icon: Icon(Icons.badge, size: 18),
              text: 'Doctor Profile',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTriageQueueTab(medicalCases),
          _buildHospitalCapacityTab(),
          _buildDoctorProfileTab(currentUser),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.warningAmber,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.medication),
        label: const Text('Request Drugs / IV Kits', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _requestMedicalSuppliesDialog,
      ),
    );
  }

  Widget _buildTriageQueueTab(List<MedicalTriageCase> cases) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Notice
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warningAmber.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warningAmber, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'START Triage Protocol: Red (Immediate life-threatening), Yellow (Urgent transport/stabilization), Green (Minor walking wounded). Patient privacy strictly preserved.',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Active Patient Cases (${cases.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  _triagePill('RED', cases.where((c) => c.triageCategory.contains('RED')).length, AppColors.criticalRed),
                  const SizedBox(width: 6),
                  _triagePill('YELLOW', cases.where((c) => c.triageCategory.contains('YELLOW')).length, AppColors.warningAmber),
                  const SizedBox(width: 6),
                  _triagePill('GREEN', cases.where((c) => c.triageCategory.contains('GREEN')).length, AppColors.verifiedGreen),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cases.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final c = cases[index];
              final isRed = c.triageCategory.contains('RED');
              final isYellow = c.triageCategory.contains('YELLOW');
              final triageColor = isRed ? AppColors.criticalRed : (isYellow ? AppColors.warningAmber : AppColors.verifiedGreen);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: triageColor.withOpacity(0.4), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: triageColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: triageColor),
                          ),
                          child: Text(
                            c.triageCategory,
                            style: TextStyle(color: triageColor, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(c.id, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
                        const Spacer(),
                        _statusBadge(c.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(c.patientAgeGender, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(c.conditionSummary, style: const TextStyle(fontSize: 13, color: Colors.white)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(child: Text(c.location, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurfaceCard,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.medication, size: 16, color: AppColors.warningAmber),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text('Urgent Needs: ${c.urgencyNeeds}', style: const TextStyle(fontSize: 11, color: AppColors.warningAmber, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                    if (c.attendingDoctorNotes != null) ...[
                      const SizedBox(height: 8),
                      Text('Doctor Note: ${c.attendingDoctorNotes}', style: const TextStyle(fontSize: 12, color: Colors.lightBlueAccent, fontStyle: FontStyle.italic)),
                    ],
                    if (c.referredHospital != null) ...[
                      const SizedBox(height: 4),
                      Text('Referred To: ${c.referredHospital}', style: const TextStyle(fontSize: 12, color: AppColors.verifiedGreen, fontWeight: FontWeight.bold)),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!c.isAccepted)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyBlue),
                            icon: const Icon(Icons.hail, size: 16),
                            label: const Text('Accept Triage Assignment'),
                            onPressed: () {
                              ref.read(medicalCasesProvider.notifier).acceptCase(c.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Accepted triage for ${c.id}. Priority medical alert set.'), backgroundColor: AppColors.navyBlue),
                              );
                            },
                          )
                        else
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.verifiedGreen),
                            icon: const Icon(Icons.edit_note, size: 16),
                            label: const Text('Update Clinical Action'),
                            onPressed: () => _openTreatmentDialog(c),
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

  Widget _buildHospitalCapacityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hospital Bed Registry & Emergency Capacity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Part 12 Compliance: Authorized hospital occupancy figures with verified updates.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _hospitals.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final h = _hospitals[index];
              final occupancyRate = (h.occupiedBeds / h.totalBeds * 100).toInt();

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.darkSurfaceCard,
                          child: Icon(Icons.local_hospital, color: AppColors.criticalRed, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(h.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(h.location, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: occupancyRate > 85 ? AppColors.criticalRed.withOpacity(0.2) : AppColors.verifiedGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$occupancyRate% Full',
                            style: TextStyle(
                              color: occupancyRate > 85 ? AppColors.criticalRed : AppColors.verifiedGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Capacity Metrics Grid
                    Row(
                      children: [
                        _metricTile('Available Beds', '${h.availableBeds}/${h.totalBeds}', AppColors.verifiedGreen),
                        const SizedBox(width: 8),
                        _metricTile('ICU Beds', '${h.icuBedsAvailable}', AppColors.criticalRed),
                        const SizedBox(width: 8),
                        _metricTile('Oxygen Beds', '${h.oxygenBedsAvailable}', AppColors.warningAmber),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Blood Bank Status
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurfaceCard,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bloodtype, color: AppColors.criticalRed, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Blood Bank: ${h.bloodBankStatus}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Updated: ${h.lastUpdated}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.phone, size: 14, color: AppColors.verifiedGreen),
                          label: Text(h.emergencyPhone, style: const TextStyle(fontSize: 12)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Dialing Hospital Emergency Hotline: ${h.emergencyPhone}')),
                            );
                          },
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

  Widget _buildDoctorProfileTab(dynamic currentUser) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.warningAmber.withOpacity(0.15), AppColors.darkSurface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.warningAmber.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.warningAmber,
                  child: Icon(Icons.medical_services, color: Colors.black, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(currentUser?.name ?? 'Dr. Aditi Mukherjee, MD', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          const TruthBadgeWidget(type: TruthBadgeType.verifiedSafe, customText: 'VERIFIED NMC'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Medical Council Registration: NMC-2018-09412', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const Text('Specialty: Emergency Medicine & Disaster Trauma Care', style: TextStyle(fontSize: 12, color: AppColors.warningAmber)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          const Text('Professional Credentials & Deployment Scope', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _profileRow(Icons.account_balance, 'Affiliated Hospital', 'AIIMS Trauma Center, New Delhi'),
          _profileRow(Icons.military_tech, 'Certifications', 'ATLS (Advanced Trauma Life Support), ACLS, Disaster Triage Level 3'),
          _profileRow(Icons.place, 'Assigned Field Sector', 'Trans-Yamuna Flood Relief Camps (Sectors 3, 4 & 5)'),
          _profileRow(Icons.contact_phone, 'District CMO Direct Liaison', '+91 11 2230 9912 (Chief Medical Officer Delhi East)'),
          _profileRow(Icons.history, 'Disaster Operations Logged', '14 Clinical shifts • 86 Patients Stabilized in 2026'),
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
                Text('Statutory Medical Disclaimer (Part 12)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                SizedBox(height: 6),
                Text(
                  'All clinical actions entered into ResQAI are legally binding disaster response triage logs synchronized with the State Disaster Management Authority (SDMA) medical audit ledger.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileRow(IconData icon, String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.warningAmber),
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

  Widget _metricTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _triagePill(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text('$label: $count', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'ATTENDING':
        color = Colors.lightBlueAccent;
        break;
      case 'STABILIZED':
        color = AppColors.verifiedGreen;
        break;
      case 'REFERRED':
        color = AppColors.warningAmber;
        break;
      default:
        color = AppColors.criticalRed;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
