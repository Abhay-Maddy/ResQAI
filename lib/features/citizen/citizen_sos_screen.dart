import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/incident_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/models/incident_model.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';

class CitizenSosScreen extends ConsumerStatefulWidget {
  const CitizenSosScreen({super.key});

  @override
  ConsumerState<CitizenSosScreen> createState() => _CitizenSosScreenState();
}

class _CitizenSosScreenState extends ConsumerState<CitizenSosScreen> {
  IncidentCategory _emergencyCategory = IncidentCategory.flood;
  int _peopleAffected = 4;
  bool _medicalAttentionRequired = false;
  bool _elderlyOrInfantsTrapped = true;
  bool _structureSubmerged = false;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _locationController = TextEditingController(
    text: 'Yamuna Khadar Sector 4, East Delhi (GPS: 28.6139° N, 77.2090° E)',
  );

  bool _isDispatched = false;
  String? _dispatchedSosId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return AppShell(
      currentRoute: AppRoutes.citizenSos,
      title: 'Emergency SOS Dispatch',
      breadcrumbs: const ['Citizen', 'Emergency SOS'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 32,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _isDispatched
                ? _buildDispatchedConfirmation(isDark)
                : _buildSosForm(isDark, isMobile),
          ),
        ),
      ),
    );
  }

  Widget _buildSosForm(bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.emergencyRed.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.emergencyRed.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Banner
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.emergencyRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emergency, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVATE EMERGENCY RESCUE',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: AppColors.emergencyRed,
                      ),
                    ),
                    const Text(
                      'Directly alerts NDRF Control Room, State EOC & Local Boats',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 1. Emergency Hazard Category
          const Text(
            '1. Nature of Emergency Hazard',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: IncidentCategory.values.map((cat) {
              final isSelected = _emergencyCategory == cat;
              return ChoiceChip(
                label: Text(cat.name.toUpperCase()),
                selected: isSelected,
                selectedColor: AppColors.emergencyRed,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                onSelected: (val) {
                  if (val) setState(() => _emergencyCategory = cat);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // 2. Location
          const Text(
            '2. Incident Location & GPS Coordinates',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.my_location, color: AppColors.primaryBlue),
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Re-fetch Current GPS',
                onPressed: () {
                  setState(() {
                    _locationController.text = 'Yamuna Riverbank Ward 4, Geolocation: 28.6142° N, 77.2105° E';
                  });
                },
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Headcount of Trapped Individuals
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('3. People Requiring Rescue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('Count of trapped individuals', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _peopleAffected > 1 ? () => setState(() => _peopleAffected--) : null,
                  ),
                  Text(
                    '$_peopleAffected',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(() => _peopleAffected++),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. Critical Triage Flags
          const Text('4. Life-Safety Critical Flags', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _elderlyOrInfantsTrapped,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.emergencyRed,
            title: const Text('Elderly, Pregnant, or Infants trapped on scene', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            onChanged: (v) => setState(() => _elderlyOrInfantsTrapped = v ?? false),
          ),
          CheckboxListTile(
            value: _medicalAttentionRequired,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.emergencyRed,
            title: const Text('Severe injury or immediate medical triage needed', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            onChanged: (v) => setState(() => _medicalAttentionRequired = v ?? false),
          ),
          CheckboxListTile(
            value: _structureSubmerged,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.emergencyRed,
            title: const Text('Floor water above 4 feet / Structure collapsing', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            onChanged: (v) => setState(() => _structureSubmerged = v ?? false),
          ),
          const SizedBox(height: 16),

          // 5. Brief Urgent Notes
          const Text('5. Urgent Details (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'e.g. Roof-top access through rear terrace ladder...',
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 24),

          // SUBMIT SOS BUTTON
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            onPressed: _submitEmergencySos,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app, size: 24),
                SizedBox(width: 10),
                Text(
                  'CONFIRM & DISPATCH RESCUE TEAM NOW',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Or call official emergency helpline: 112 (India Emergency Response Support System)',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchedConfirmation(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.successGreen, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: AppColors.successGreen, size: 54),
          ),
          const SizedBox(height: 18),
          const Text(
            'EMERGENCY SOS LOGGED & DISPATCHED',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.successGreen),
          ),
          const SizedBox(height: 8),
          Text(
            'Unique Tracking ID: $_dispatchedSosId',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          const Text(
            'Your emergency distress alert has been logged into the State Disaster Operations Command queue. '
            'First Responder NDRF Unit #3 has been alerted with your coordinates.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.track_changes),
                label: const Text('Track Live Status'),
                onPressed: () {
                  Navigator.pushNamed(context, '${AppRoutes.citizenReports}/$_dispatchedSosId');
                },
              ),
              const SizedBox(width: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                icon: const Icon(Icons.home),
                label: const Text('Return to Dashboard'),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.citizenDashboard);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submitEmergencySos() {
    final newId = 'RQ-SOS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final user = ref.read(authProvider);

    final newSos = IncidentModel(
      id: newId,
      title: 'CRITICAL SOS: ${_emergencyCategory.name.toUpperCase()} - $_peopleAffected Persons Trapped',
      descriptionOriginal: _notesController.text.isNotEmpty
          ? _notesController.text
          : 'Immediate life safety evacuation requested. $_peopleAffected trapped.',
      descriptionTranslated: _notesController.text.isNotEmpty
          ? _notesController.text
          : 'Immediate life safety evacuation requested. $_peopleAffected trapped.',
      category: _emergencyCategory,
      latitude: 28.6139,
      longitude: 77.2090,
      address: _locationController.text,
      status: IncidentStatus.helpAssigned,
      priorityScore: 95.0,
      priorityExplanation: 'Critical SOS dispatch triggered via 1-Tap Emergency Portal',
      vulnerableGroups: [
        if (_elderlyOrInfantsTrapped) 'Elderly/Infant',
        if (_medicalAttentionRequired) 'Injured',
      ],
      reporterPhoneMasked: user?.phoneMasked ?? '+91 98*** **210',
      reportedAt: DateTime.now(),
      source: 'ONE_TAP_SOS',
      householdMembersCount: _peopleAffected,
      reliefRequirements: ['Urgent Boat Evacuation', if (_medicalAttentionRequired) 'Paramedic Triage'],
    );

    ref.read(incidentsProvider.notifier).addIncident(newSos);

    setState(() {
      _isDispatched = true;
      _dispatchedSosId = newId;
    });
  }
}
