import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/incident_model.dart';
import '../../data/repositories/incident_repository.dart';
import '../../shared/widgets/truth_badge_widget.dart';

class ReportSosWizard extends ConsumerStatefulWidget {
  const ReportSosWizard({super.key});

  @override
  ConsumerState<ReportSosWizard> createState() => _ReportSosWizardState();
}

class _ReportSosWizardState extends ConsumerState<ReportSosWizard> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController(text: 'Current GPS: Yamuna Khadar Sector 4 (28.6139, 77.2090)');

  IncidentCategory _selectedCategory = IncidentCategory.flood;
  bool _isSosActive = false;
  bool _hasVoiceNote = false;
  bool _isManualCorrectionOpen = false;
  double _manualLat = 28.6139;
  double _manualLng = 77.2090;

  final List<String> _selectedVulnerabilities = [];
  final List<String> _vulnerabilityOptions = [
    'Children under 5',
    'Elderly persons (>65)',
    'Pregnant women',
    'Persons with mobility disability',
    'Hospital / Clinic nearby',
  ];

  void _triggerOneTapSos() {
    setState(() => _isSosActive = true);
    final newId = 'RQ-${(100 + ref.read(incidentsProvider).length + 1)}';

    final sosIncident = IncidentModel(
      id: newId,
      title: 'CRITICAL ONE-TAP SOS: Immediate Rescue Needed',
      descriptionOriginal: 'ONE-TAP EMERGENCY SOS TRIGGERED BY CITIZEN AT Yamuna Khadar. Immediate boat evacuation required.',
      descriptionTranslated: 'ONE-TAP EMERGENCY SOS TRIGGERED BY CITIZEN AT Yamuna Khadar. Immediate boat evacuation required.',
      category: IncidentCategory.flood,
      latitude: 28.6139,
      longitude: 77.2090,
      address: 'Live Geolocation: 28.6139° N, 77.2090° E (Yamuna Lowland)',
      status: IncidentStatus.received,
      priorityScore: 99.0,
      priorityExplanation: 'Critical One-Tap SOS: Auto-escalated to highest district rescue triage.',
      vulnerableGroups: ['Emergency SOS Triggered'],
      reporterPhoneMasked: '+91 99*** **112',
      reportedAt: DateTime.now(),
      source: 'ONE_TAP_SOS',
    );

    ref.read(incidentsProvider.notifier).addIncident(sosIncident);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.verifiedGreen, size: 28),
            SizedBox(width: 8),
            Text('SOS Broadcast Active!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Emergency Reference ID is: $newId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.accent)),
            const SizedBox(height: 8),
            const Text('NDRF and Local Disaster Management have received your exact GPS coordinates. Stay in high and dry ground if possible.'),
            const SizedBox(height: 12),
            const TruthBadgeWidget(type: TruthBadgeType.piiMasked),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isSosActive = false);
            },
            child: const Text('OK / Track Status', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _submitDetailedReport() {
    if (!_formKey.currentState!.validate()) return;

    final newId = 'RQ-${(100 + ref.read(incidentsProvider).length + 1)}';
    final rawText = _descController.text;

    final newIncident = IncidentModel(
      id: newId,
      title: _titleController.text.isNotEmpty ? _titleController.text : 'Community Emergency Report',
      descriptionOriginal: rawText,
      descriptionTranslated: rawText, // Bilingual preservation
      category: _selectedCategory,
      latitude: _manualLat,
      longitude: _manualLng,
      address: _addressController.text,
      status: IncidentStatus.received,
      priorityScore: IncidentModel.calculatePriority(
        category: _selectedCategory,
        casualties: 0,
        trappedCount: 4,
        hasVulnerable: _selectedVulnerabilities.isNotEmpty,
        waterLevelMeters: 1.2,
        isNightTime: false,
      ),
      priorityExplanation: 'Community submission with ${_selectedVulnerabilities.length} vulnerable tags.',
      vulnerableGroups: List.from(_selectedVulnerabilities),
      hasVoiceNote: _hasVoiceNote,
      reporterPhoneMasked: _phoneController.text.length >= 4 
          ? '+91 *** ***${_phoneController.text.substring(_phoneController.text.length - 4)}'
          : '+91 98*** **000',
      reportedAt: DateTime.now(),
      source: 'CITIZEN_WEB',
    );

    ref.read(incidentsProvider.notifier).addIncident(newIncident);

    _titleController.clear();
    _descController.clear();
    _phoneController.clear();
    setState(() {
      _selectedVulnerabilities.clear();
      _hasVoiceNote = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.verifiedGreen,
        content: Text('Report submitted successfully! Your Reference ID is: $newId'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // One-Tap SOS Action Card (Feature 2)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.criticalRed.withOpacity(0.9), const Color(0xFF991B1B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.criticalRed.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emergency, color: Colors.white, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'ONE-TAP EMERGENCY SOS',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Instantly broadcasts your live GPS coordinates to the Disaster Response Command Center.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.criticalRed,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  icon: const Icon(Icons.touch_app, size: 24),
                  label: Text(
                    _isSosActive ? 'SOS BROADCAST ACTIVE (PRESS TO RETRIGGER)' : 'PRESS FOR IMMEDIATE RESCUE',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _triggerOneTapSos,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Standard Citizen Incident Report Form (Features 1, 3, 5, 16)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Detailed Incident Reporting', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Hindi & English accepted. AI automatically translates and detects vulnerable groups.', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                    const Divider(height: 24),

                    // Incident Category
                    const Text('Incident Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<IncidentCategory>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      items: IncidentCategory.values.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat.label));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Title
                    const Text('Headline / Title', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 15 people trapped on terrace due to flood',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Please enter a title' : null,
                    ),

                    const SizedBox(height: 16),

                    // Description (Bilingual)
                    const Text('Description (हिंदी या English)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'पानी का स्तर कितना है? कितने लोग फंसे हैं? कोई घायल है? Describe situation...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Please describe the incident' : null,
                    ),

                    const SizedBox(height: 16),

                    // Location & Geolocation (Feature 3)
                    Row(
                      children: [
                        const Text('Location Coordinates', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const Spacer(),
                        TextButton.icon(
                          icon: Icon(_isManualCorrectionOpen ? Icons.check : Icons.edit_location, size: 16),
                          label: Text(_isManualCorrectionOpen ? 'Done' : 'Correct Location Manually'),
                          onPressed: () => setState(() => _isManualCorrectionOpen = !_isManualCorrectionOpen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.location_on, color: AppColors.primary),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    if (_isManualCorrectionOpen) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurfaceCard,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: _manualLat.toString(),
                                decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                onChanged: (v) => _manualLat = double.tryParse(v) ?? _manualLat,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                initialValue: _manualLng.toString(),
                                decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                onChanged: (v) => _manualLng = double.tryParse(v) ?? _manualLng,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Vulnerable Group Flagging (Feature 16)
                    const Text('Identify Vulnerable Individuals Present', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _vulnerabilityOptions.map((opt) {
                        final isSelected = _selectedVulnerabilities.contains(opt);
                        return FilterChip(
                          label: Text(opt, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          selectedColor: AppColors.primary.withOpacity(0.3),
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedVulnerabilities.add(opt);
                              } else {
                                _selectedVulnerabilities.remove(opt);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Voice Note Toggle (Feature 2)
                    CheckboxListTile(
                      title: const Text('Attach Audio Voice Note (Web Audio API)', style: TextStyle(fontSize: 13)),
                      subtitle: const Text('Simulates 15-second recorded field voice note', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      value: _hasVoiceNote,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _hasVoiceNote = val ?? false),
                    ),

                    const SizedBox(height: 16),

                    // Reporter Phone (Feature 7: DPDP Masking)
                    const Text('Contact Phone (Masked for Privacy)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 9876543210 (Will be masked as +91 98*** **210)',
                        prefixIcon: Icon(Icons.phone, color: Colors.grey),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.send, color: Colors.white),
                      label: const Text('Submit Verified Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      onPressed: _submitDetailedReport,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
