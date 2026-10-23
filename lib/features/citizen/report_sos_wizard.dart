import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/incident_model.dart';
import '../../data/repositories/incident_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets/truth_badge_widget.dart';
import '../../app.dart';

class ReportSosWizard extends ConsumerStatefulWidget {
  const ReportSosWizard({super.key});

  @override
  ConsumerState<ReportSosWizard> createState() => _ReportSosWizardState();
}

class _ReportSosWizardState extends ConsumerState<ReportSosWizard> with SingleTickerProviderStateMixin {
  late TabController _modeTabController;

  // --- SOS Mode Controllers & State ---
  IncidentCategory _sosCategory = IncidentCategory.flood;
  final _sosQuickNotesController = TextEditingController();
  bool _notifyFamilyContact = true;
  bool _isSosActive = false;
  String _sosLocation = 'Live Geolocation: 28.6139° N, 77.2090° E (Yamuna Lowland)';

  // --- Detailed Damage & Assistance Report State ---
  final _damageFormKey = GlobalKey<FormState>();
  IncidentCategory _damageCategory = IncidentCategory.flood;
  DateTime _incidentDate = DateTime.now();
  final _damageTitleController = TextEditingController();
  final _damageDescController = TextEditingController();
  final _damageAddressController = TextEditingController(text: 'House No 42, Yamuna Khadar Sector 4, East Delhi');
  final _estimatedLossController = TextEditingController(text: '150000');
  final _householdCountController = TextEditingController(text: '5');
  final _medicalNeedsController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  String _preferredFollowUp = 'SMS Notification';

  // Affected Property Categories
  final List<String> _selectedProperties = ['Home / Housing'];
  final List<String> _propertyOptions = [
    'Home / Housing',
    'Agricultural Land & Standing Crops',
    'Livestock & Cattle',
    'Small Business / Shop / Workshop',
    'Household Electronics & Vehicles',
  ];

  // Immediate Relief Requirements
  final List<String> _selectedReliefNeeds = ['Drinking Water', 'Food / Dry Rations'];
  final List<String> _reliefOptions = [
    'Drinking Water',
    'Food / Dry Rations',
    'Waterproof Tarpaulins / Tents',
    'Warm Clothes & Blankets',
    'Emergency Medicine & First Aid',
    'Hygiene & Sanitation Kits',
  ];

  // Evidence Photos Simulation
  final List<String> _attachedEvidence = ['damage_photo_01.jpg'];
  bool _hasVoiceNote = false;

  @override
  void initState() {
    super.initState();
    _modeTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _modeTabController.dispose();
    _sosQuickNotesController.dispose();
    _damageTitleController.dispose();
    _damageDescController.dispose();
    _damageAddressController.dispose();
    _estimatedLossController.dispose();
    _householdCountController.dispose();
    _medicalNeedsController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  void _triggerOneTapSos() {
    final currentUser = ref.read(authProvider);
    final newId = 'RQ-SOS-${(2000 + ref.read(incidentsProvider).length + 1)}';
    final notes = _sosQuickNotesController.text.trim();

    final sosIncident = IncidentModel(
      id: newId,
      title: 'CRITICAL 1-TAP SOS: ${_sosCategory.label} Rescue Needed',
      descriptionOriginal: notes.isNotEmpty 
          ? 'EMERGENCY SOS: $notes'
          : 'CRITICAL 1-TAP SOS ACTIVATED: Citizen at $_sosLocation urgently requests emergency response assistance.',
      descriptionTranslated: notes.isNotEmpty 
          ? 'EMERGENCY SOS: $notes'
          : 'CRITICAL 1-TAP SOS ACTIVATED: Citizen at $_sosLocation urgently requests emergency response assistance.',
      category: _sosCategory,
      latitude: 28.6139,
      longitude: 77.2090,
      address: _sosLocation,
      status: IncidentStatus.received,
      priorityScore: 99.0,
      priorityExplanation: 'Critical One-Tap SOS: Emergency response request queued for authorized dispatch triage.',
      vulnerableGroups: ['1-Tap SOS Dispatch'],
      source: 'ONE_TAP_SOS',
      reporterPhoneMasked: currentUser?.phoneMasked ?? '+91 98*** **412',
      reportedAt: DateTime.now(),
      verificationHistory: [
        '${DateTime.now().toIso8601String().substring(0, 16)}: SOS Broadcast Received at Central Command Desk',
        if (_notifyFamilyContact && currentUser != null)
          '${DateTime.now().toIso8601String().substring(0, 16)}: Automated alert queued for Emergency Contact: ${currentUser.emergencyContactName} (${currentUser.emergencyContactPhone})',
      ],
    );

    ref.read(incidentsProvider.notifier).addIncident(sosIncident);
    setState(() => _isSosActive = true);

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
            Icon(Icons.check_circle, color: AppColors.verifiedGreen, size: 28),
            SizedBox(width: 8),
            Text('SOS Broadcast Received!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.criticalRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.criticalRed),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SOS REFERENCE ID:', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold, color: Colors.white70)),
                  Text(newId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.criticalRed)),
                  const SizedBox(height: 4),
                  const Text('Status: Queued in DDMA Emergency Dispatch Queue', style: TextStyle(fontSize: 12, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your GPS coordinates have been registered with the local Disaster Command Desk. If conditions are life-threatening, dial 112 (National Emergency Helpline) or 1078 (Disaster Helpline) immediately.',
              style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
            ),
            if (_notifyFamilyContact && currentUser != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.send_to_mobile, size: 16, color: AppColors.verifiedGreen),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Emergency Contact (${currentUser.emergencyContactName}) notified with location link.',
                      style: const TextStyle(fontSize: 11, color: AppColors.verifiedGreen),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            const TruthBadgeWidget(type: TruthBadgeType.piiMasked),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(currentTabProvider.notifier).state = MainNavigationTab.statusTracker;
            },
            child: const Text('Track Live Status', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _submitDamageAndAssistanceReport() {
    if (!_damageFormKey.currentState!.validate()) return;
    final currentUser = ref.read(authProvider);

    final newCaseId = 'RQ-CASE-2026-${(1000 + ref.read(incidentsProvider).length + 1)}';
    final desc = _damageDescController.text.trim();
    final lossAmount = double.tryParse(_estimatedLossController.text.trim()) ?? 0.0;
    final householdCount = int.tryParse(_householdCountController.text.trim()) ?? 1;

    final damageIncident = IncidentModel(
      id: newCaseId,
      title: _damageTitleController.text.trim().isNotEmpty
          ? _damageTitleController.text.trim()
          : 'Damage & Assistance Claim: ${_damageCategory.label}',
      descriptionOriginal: desc,
      descriptionTranslated: desc,
      category: _damageCategory,
      latitude: 28.6139,
      longitude: 77.2090,
      address: _damageAddressController.text.trim(),
      status: IncidentStatus.received,
      priorityScore: IncidentModel.calculatePriority(
        category: _damageCategory,
        casualties: 0,
        trappedCount: householdCount,
        hasVulnerable: householdCount > 3,
        waterLevelMeters: 1.0,
        isNightTime: false,
      ),
      priorityExplanation: 'Community Damage Assessment with ${_selectedProperties.length} property claims and ₹${lossAmount.toStringAsFixed(0)} estimated loss.',
      vulnerableGroups: ['Damage Assessment Claim', ..._selectedProperties],
      source: 'DAMAGE_REPORT',
      reporterPhoneMasked: _contactPhoneController.text.trim().isNotEmpty 
          ? '+91 *** ***${_contactPhoneController.text.trim().substring(_contactPhoneController.text.trim().length - 4)}'
          : (currentUser?.phoneMasked ?? '+91 98*** **412'),
      reportedAt: DateTime.now(),
      affectedProperties: List.from(_selectedProperties),
      estimatedLossInr: lossAmount,
      householdMembersCount: householdCount,
      urgentMedicalNeeds: _medicalNeedsController.text.trim().isNotEmpty ? _medicalNeedsController.text.trim() : null,
      reliefRequirements: List.from(_selectedReliefNeeds),
      evidencePhotos: List.from(_attachedEvidence),
      preferredFollowUp: _preferredFollowUp,
      verificationHistory: [
        '${DateTime.now().toIso8601String().substring(0, 16)}: Detailed Damage & Assistance Application submitted (Case Ref: $newCaseId)',
        '${DateTime.now().toIso8601String().substring(0, 16)}: Queued for District Revenue & Disaster Relief Inspection',
      ],
    );

    ref.read(incidentsProvider.notifier).addIncident(damageIncident);

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
            Icon(Icons.assignment_turned_in, color: AppColors.verifiedGreen, size: 26),
            SizedBox(width: 8),
            Text('Assistance Claim Registered!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.verifiedGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.verifiedGreen),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('GOVERNMENT RELIEF CASE ID:', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold, color: Colors.white70)),
                  Text(newCaseId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.verifiedGreen)),
                  const SizedBox(height: 4),
                  Text('Estimated Damage Claim: ₹${lossAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your damage report and assistance request has been recorded in the DDMA Relief Registry. An authorized field verification team will review your evidence before funds/relief supplies are approved.',
              style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 8),
            Text('Preferred Follow-Up: $_preferredFollowUp', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(currentTabProvider.notifier).state = MainNavigationTab.statusTracker;
            },
            child: const Text('Track Application', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Mode Selector Tab Bar
        Container(
          color: AppColors.darkSurfaceCard,
          child: TabBar(
            controller: _modeTabController,
            indicatorColor: AppColors.criticalRed,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.emergency, color: AppColors.criticalRed, size: 20), text: 'Fast Emergency SOS (Urgent)'),
              Tab(icon: Icon(Icons.assessment, color: AppColors.primaryLight, size: 20), text: 'Disaster Damage & Relief Claim'),
            ],
          ),
        ),

        // Mode Content
        Expanded(
          child: TabBarView(
            controller: _modeTabController,
            children: [
              _buildFastSosMode(),
              _buildDetailedDamageReportingMode(),
            ],
          ),
        ),
      ],
    );
  }

  // --- 1. FAST EMERGENCY SOS MODE (Part 6) ---
  Widget _buildFastSosMode() {
    final currentUser = ref.watch(authProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Emergency SOS Action Box
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.criticalRed.withOpacity(0.95), const Color(0xFF7F1D1D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.criticalRed.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
                    SizedBox(width: 10),
                    Text(
                      '1-TAP EMERGENCY SOS',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Under severe distress? Tap below to broadcast your live GPS to the local disaster control center immediately with zero delay.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.criticalRed,
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 6,
                  ),
                  icon: const Icon(Icons.touch_app, size: 28),
                  label: Text(
                    _isSosActive ? 'RE-BROADCAST LIVE SOS' : 'PRESS FOR RESCUE DISPATCH',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _triggerOneTapSos,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick SOS Optional Customization
          Card(
            color: AppColors.darkSurfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Optional Rapid Triage Details (Submit instantly if needed):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 12),

                  const Text('Emergency Hazard Type:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<IncidentCategory>(
                    value: _sosCategory,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    items: IncidentCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _sosCategory = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  const Text('Quick Emergency Note (e.g. 4 people trapped on roof):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _sosQuickNotesController,
                    decoration: const InputDecoration(
                      hintText: 'Describe immediate danger or landmark (optional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Alert Emergency Contact (${currentUser?.emergencyContactName ?? "Family"})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Sends SMS with GPS coordinates to ${currentUser?.emergencyContactPhone ?? "+91 98765 00112"}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    value: _notifyFamilyContact,
                    onChanged: (val) => setState(() => _notifyFamilyContact = val),
                  ),
                  const Divider(height: 16),

                  Row(
                    children: [
                      const Icon(Icons.gps_fixed, size: 16, color: AppColors.primaryLight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _sosLocation,
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Allow quick manual location text override
                          showDialog(
                            context: context,
                            builder: (ctx) {
                              final ctrl = TextEditingController(text: _sosLocation);
                              return AlertDialog(
                                backgroundColor: AppColors.darkSurface,
                                title: const Text('Update GPS / Landmark', style: TextStyle(fontSize: 14)),
                                content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Enter street or coordinates')),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() => _sosLocation = ctrl.text.trim());
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text('Save'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Text('Edit GPS', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // National Hotlines Card (Transparent & Honest)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.infoBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.infoBlue.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.phone_in_talk, color: AppColors.infoBlue, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Direct National Helpline Links:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.infoBlue)),
                      Text('• Dial 112 for All-India Unified Police / Fire / Ambulance\n• Dial 1078 for National Disaster Management Authority (NDMA)\n• Dial 1070 for State Emergency Relief Control Room', style: TextStyle(fontSize: 11, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. DETAILED DISASTER DAMAGE & RELIEF CLAIM MODE (Part 6) ---
  Widget _buildDetailedDamageReportingMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _damageFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.document_scanner, color: AppColors.primaryLight, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Official Disaster Damage & Relief Application', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Submit verified property loss, agricultural damage, and family relief requirements for government assistance and NGO allocation.', style: TextStyle(fontSize: 11, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Incident Category & Date of Occurrence
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Disaster Type *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<IncidentCategory>(
                        value: _damageCategory,
                        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                        items: IncidentCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _damageCategory = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date of Occurrence *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          side: const BorderSide(color: AppColors.darkBorder),
                        ),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          '${_incidentDate.day}/${_incidentDate.month}/${_incidentDate.year}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _incidentDate,
                            firstDate: DateTime(2025),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => _incidentDate = picked);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Title
            const Text('Damage Summary Headline *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextFormField(
              controller: _damageTitleController,
              decoration: const InputDecoration(
                hintText: 'e.g. Complete inundation of ground floor and crop damage',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) => v == null || v.isEmpty ? 'Please enter a summary title' : null,
            ),
            const SizedBox(height: 14),

            // Affected Property Categories (Part 6)
            const Text('Affected Property Categories *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _propertyOptions.map((prop) {
                final isSelected = _selectedProperties.contains(prop);
                return FilterChip(
                  label: Text(prop, style: const TextStyle(fontSize: 11)),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withOpacity(0.3),
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedProperties.add(prop);
                      } else {
                        _selectedProperties.remove(prop);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Estimated Loss in INR & Household Members Count
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Estimated Economic Loss (₹ INR):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _estimatedLossController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.currency_rupee, size: 16),
                          hintText: 'e.g. 150000',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Affected Family Members *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _householdCountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.people, size: 16),
                          hintText: 'e.g. 5',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Detailed Description
            const Text('Detailed Description of Damage & Circumstances *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextFormField(
              controller: _damageDescController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe depth of water, cracked walls, lost livestock, ruined seed stores, etc.',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Please describe the damage' : null,
            ),
            const SizedBox(height: 14),

            // Urgent Medical Needs
            const Text('Injuries or Urgent Medical Needs (if any):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextFormField(
              controller: _medicalNeedsController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.medical_services, size: 16),
                hintText: 'e.g. Elderly grandmother requires hypertension medication; minor leg wound on child',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),

            // Required Relief Supplies (Part 6)
            const Text('Immediate Relief Supplies Required:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _reliefOptions.map((need) {
                final isSelected = _selectedReliefNeeds.contains(need);
                return FilterChip(
                  label: Text(need, style: const TextStyle(fontSize: 11)),
                  selected: isSelected,
                  selectedColor: AppColors.verifiedGreen.withOpacity(0.3),
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedReliefNeeds.add(need);
                      } else {
                        _selectedReliefNeeds.remove(need);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Location
            const Text('Damage Site Location Address *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextFormField(
              controller: _damageAddressController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.location_on, size: 16),
                hintText: 'Plot/House No, Locality, Ward, District',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) => v == null || v.isEmpty ? 'Address is required' : null,
            ),
            const SizedBox(height: 14),

            // Evidence Attachments & Voice Note
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    icon: const Icon(Icons.add_a_photo, size: 16),
                    label: Text('Attach Evidence Photo (${_attachedEvidence.length})', style: const TextStyle(fontSize: 11)),
                    onPressed: () {
                      setState(() {
                        _attachedEvidence.add('field_damage_${DateTime.now().millisecondsSinceEpoch % 100}.jpg');
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Field damage photo attached to application draft.')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Voice Note', style: TextStyle(fontSize: 12)),
                    value: _hasVoiceNote,
                    onChanged: (v) => setState(() => _hasVoiceNote = v ?? false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Follow-Up Method
            const Text('Preferred Follow-Up Method *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: _preferredFollowUp,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              items: const [
                DropdownMenuItem(value: 'SMS Notification', child: Text('SMS Notification to Registered Phone', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'Direct Phone Call', child: Text('Direct Phone Call from Disaster Officer', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'Physical Field Inspection', child: Text('Physical Field Visit by Revenue Inspector', style: TextStyle(fontSize: 12))),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _preferredFollowUp = val);
              },
            ),
            const SizedBox(height: 20),

            // Submission Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.verifiedGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.send_and_archive, color: Colors.white),
              label: const Text('Submit Verified Damage Report & Relief Claim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: _submitDamageAndAssistanceReport,
            ),
          ],
        ),
      ),
    );
  }
}
