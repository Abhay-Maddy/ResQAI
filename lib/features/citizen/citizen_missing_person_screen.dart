import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/incident_repository.dart';
import '../../shared/models/incident_model.dart';

class CitizenMissingPersonScreen extends ConsumerStatefulWidget {
  const CitizenMissingPersonScreen({super.key});

  @override
  ConsumerState<CitizenMissingPersonScreen> createState() => _CitizenMissingPersonScreenState();
}

class _CitizenMissingPersonScreenState extends ConsumerState<CitizenMissingPersonScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  final TextEditingController _nameController = TextEditingController(text: 'Rameshwar Lal Sharma');
  final TextEditingController _ageController = TextEditingController(text: '68');
  String _gender = 'Male';
  String _relationship = 'Parent (Father)';
  final List<String> _relationships = [
    'Child (Son/Daughter)',
    'Parent (Father/Mother)',
    'Spouse (Husband/Wife)',
    'Sibling (Brother/Sister)',
    'Grandparent',
    'Neighbor / Community Member',
    'Other',
  ];

  final DateTime _lastSeenDate = DateTime.now().subtract(const Duration(hours: 10));
  final TextEditingController _lastSeenLocationController = TextEditingController(
    text: 'Near Mayur Vihar Yamuna Khadar bund, Sector 4 Embankment',
  );
  final TextEditingController _physicalDescriptionController = TextEditingController(
    text: 'Approx 5ft 7in, slender build, grey hair. Wearing white cotton kurta and brown sandals.',
  );
  final TextEditingController _medicalConditionsController = TextEditingController(
    text: 'Diabetic; requires daily insulin. Mild hearing impairment.',
  );
  final TextEditingController _contactPhoneController = TextEditingController(text: '+91 98111 22334');
  final TextEditingController _altContactPhoneController = TextEditingController(text: '+91 98222 33445');

  bool _isUrgentEmergencyRescue = true;
  bool _attachedPhotoSimulation = true;
  bool _consentDeclaration = true;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _lastSeenLocationController.dispose();
    _physicalDescriptionController.dispose();
    _medicalConditionsController.dispose();
    _contactPhoneController.dispose();
    _altContactPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return AppShell(
      currentRoute: AppRoutes.citizenMissingPerson,
      title: 'Report Missing Family Member',
      breadcrumbs: const ['Citizen', 'Help Hub', 'Missing Person'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 28,
          vertical: isMobile ? 16 : 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 16 : 28),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.emergencyRed.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person_search, color: AppColors.emergencyRed, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Confidential Missing Person Report',
                                style: TextStyle(
                                  fontSize: isMobile ? 17 : 20,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : AppColors.deepNavy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Direct statutory intake routed to NDRF, SDRF, and Police Search & Rescue Units',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Confidentiality Notice
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lock, color: Colors.brown, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'RESTRICTED PRIVACY WORKFLOW (DPDP ACT & NDMA)',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.brown),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Missing family member details are strictly restricted to authorized search teams. Under statutory privacy protocols, identifying details and locations are never published on the public disaster map without authorization.',
                                  style: TextStyle(fontSize: 11, height: 1.35, color: Colors.brown),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Urgent Search Toggle
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.emergencyRed.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.emergencyRed.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emergency, color: AppColors.emergencyRed, size: 22),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Immediate Tactical Search & Rescue Dispatch Required',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.emergencyRed),
                                ),
                                Text('Person is in imminent peril, submerged area, or acute medical need',
                                    style: TextStyle(fontSize: 11, color: Colors.black54)),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isUrgentEmergencyRescue,
                            activeColor: AppColors.emergencyRed,
                            onChanged: (v) => setState(() => _isUrgentEmergencyRescue = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Person Information
                    const Text('Missing Person Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Full Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter name' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Age *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter age' : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Gender *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _gender,
                                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                                items: ['Male', 'Female', 'Other']
                                    .map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 12))))
                                    .toList(),
                                onChanged: (v) => setState(() => _gender = v ?? 'Male'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Relationship to You *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _relationship,
                                isExpanded: true,
                                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                                items: _relationships
                                    .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12))))
                                    .toList(),
                                onChanged: (v) => setState(() => _relationship = v ?? _relationships.first),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Last Seen Details
                    const Text('Last Known Location & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _lastSeenLocationController,
                      decoration: const InputDecoration(
                        labelText: 'Last Known Spot / Landmark *',
                        prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please specify last known location' : null,
                    ),
                    const SizedBox(height: 14),

                    // Physical Description
                    TextFormField(
                      controller: _physicalDescriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Physical Appearance & Clothing Worn *',
                        hintText: 'Height, build, clothing color, distinguishing marks, language spoken...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please describe physical appearance' : null,
                    ),
                    const SizedBox(height: 14),

                    // Medical Conditions
                    TextFormField(
                      controller: _medicalConditionsController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Medical Conditions or Special Care Needs (if any)',
                        hintText: 'e.g. Diabetic on insulin, Alzheimer / Dementia, Asthma, Non-verbal...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Contact Details
                    const Text('Follow-Up Contacts for Search Officers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _contactPhoneController,
                            decoration: const InputDecoration(
                              labelText: 'Your Contact Phone *',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter phone' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _altContactPhoneController,
                            decoration: const InputDecoration(
                              labelText: 'Alternate Family Phone',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Photo Proof Toggle
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceCard : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add_a_photo_outlined, color: AppColors.primaryBlue),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Recent Photograph of Missing Person Attached',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Text('recent_photo_rameshwar_lal.jpg (2.1 MB) • For search team verification',
                                    style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Switch(
                            value: _attachedPhotoSimulation,
                            activeColor: AppColors.primaryBlue,
                            onChanged: (v) => setState(() => _attachedPhotoSimulation = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: _consentDeclaration,
                      activeColor: AppColors.emergencyRed,
                      title: const Text(
                        'I declare that I am authorized to report this missing person. I consent to immediate coordination by NDRF, Police, and local search teams.',
                        style: TextStyle(fontSize: 11),
                      ),
                      onChanged: (v) => setState(() => _consentDeclaration = v ?? true),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emergencyRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send),
                      label: Text(
                        _isSubmitting ? 'Routing to Search Teams...' : 'Transmit Confidential Missing Person Report',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onPressed: _isSubmitting ? null : _submitMissingPersonReport,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitMissingPersonReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_consentDeclaration) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warningOrange,
          content: Text('Please accept the consent declaration before transmitting.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final caseId = 'RQ-MIS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final user = ref.read(authProvider);

    final details = '${_nameController.text.trim()}, Age: ${_ageController.text}, Gender: $_gender. '
        'Relation: $_relationship. Last seen on ${_lastSeenDate.day}/${_lastSeenDate.month} at ${_lastSeenLocationController.text.trim()}. '
        'Appearance: ${_physicalDescriptionController.text.trim()}. '
        'Medical: ${_medicalConditionsController.text.trim()}. Contact: ${_contactPhoneController.text.trim()}';

    final incident = IncidentModel(
      id: caseId,
      title: 'MISSING PERSON: ${_nameController.text.trim()} (Age ${_ageController.text})',
      descriptionOriginal: details,
      descriptionTranslated: details,
      category: IncidentCategory.missingPerson,
      latitude: 28.6280,
      longitude: 77.2980,
      address: _lastSeenLocationController.text.trim(),
      status: IncidentStatus.received,
      priorityScore: _isUrgentEmergencyRescue ? 98.0 : 88.0,
      priorityExplanation: _isUrgentEmergencyRescue
          ? 'Critical Life Alert: Immediate search & rescue requested for missing vulnerable citizen'
          : 'Confidential missing person report logged for tactical SAR coordination',
      vulnerableGroups: ['Missing Family Member', 'Confidential SAR'],
      reporterPhoneMasked: user?.phoneMasked ?? _contactPhoneController.text.trim(),
      reportedAt: DateTime.now(),
      source: 'CITIZEN_MISSING_PERSON_REPORT',
      missingPersonsCount: 1,
      missingPersonsDetails: details,
      missingPersonEmergencyAssistanceNeeded: _isUrgentEmergencyRescue,
      evidencePhotos: _attachedPhotoSimulation ? ['recent_photo_rameshwar_lal.jpg'] : const [],
      departmentAssigned: 'NDRF 8th Battalion & State Police SAR Team',
      assistanceDeliveryStatus: 'SEARCH_IN_PROGRESS',
    );

    ref.read(incidentsProvider.notifier).addIncident(incident);

    setState(() => _isSubmitting = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified_user, color: AppColors.successGreen, size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Missing Person Case Logged',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Case Reference:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  Text(caseId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.emergencyRed)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your report has been securely transmitted to the NDRF Field Command & District Police Station.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            const Text(
              'A dedicated search officer will contact you on your safe contact phone.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergencyRed, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacementNamed(context, '${AppRoutes.citizenReports}/$caseId');
            },
            child: const Text('Open Case Tracking'),
          ),
        ],
      ),
    );
  }
}
