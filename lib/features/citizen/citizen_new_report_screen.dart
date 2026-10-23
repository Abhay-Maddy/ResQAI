import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/incident_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/models/incident_model.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';

class CitizenNewReportScreen extends ConsumerStatefulWidget {
  const CitizenNewReportScreen({super.key});

  @override
  ConsumerState<CitizenNewReportScreen> createState() => _CitizenNewReportScreenState();
}

class _CitizenNewReportScreenState extends ConsumerState<CitizenNewReportScreen> {
  int _currentStep = 0;

  // Step 1: Incident & Location
  IncidentCategory _category = IncidentCategory.flood;
  final TextEditingController _titleController = TextEditingController(text: 'Structural Boundary Wall Collapse & Inundation');
  final TextEditingController _addressController = TextEditingController(text: 'House 42, Yamuna Khadar Sector 4, East Delhi');

  // Step 2: Damage & Affected People
  final TextEditingController _householdCountController = TextEditingController(text: '5');
  final TextEditingController _estimatedLossController = TextEditingController(text: '220000');
  final List<String> _selectedProperties = ['Pucca Housing Structure', 'Agricultural Standing Crops'];
  final List<String> _propertyOptions = [
    'Pucca Housing Structure',
    'Kutcha Mud House / Thatched Roof',
    'Agricultural Standing Crops',
    'Livestock & Cattle',
    'Small Business / Shop / Workshop',
    'Household Electronics & Vehicles',
  ];

  // Step 3: Assistance Required
  final List<String> _selectedNeeds = ['Drinking Water', 'Food / Dry Rations', 'Waterproof Tarpaulins'];
  final List<String> _needsOptions = [
    'Drinking Water',
    'Food / Dry Rations',
    'Waterproof Tarpaulins',
    'Warm Blankets',
    'Emergency Medicine & First Aid',
    'Temporary Camp Shelter',
    'Sanitation / Hygiene Kits',
  ];

  // Step 4: Evidence & Notes
  final TextEditingController _descriptionController = TextEditingController(
    text: 'Ground floor submerged under 3.5 ft water; northern boundary wall collapsed. Two buffaloes evacuated to embankment.',
  );
  bool _attachedPhotoSimulation = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return AppShell(
      currentRoute: AppRoutes.citizenNewReport,
      title: 'File Damage & Assistance Claim',
      breadcrumbs: const ['Citizen', 'Reports', 'New Claim'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 32,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 18 : 28),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.edit_document, color: AppColors.primaryBlue, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Disaster Damage & SDRF Assistance Assessment',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 19,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : AppColors.deepNavy,
                              ),
                            ),
                            const Text(
                              '5-Step guided formal submission for official field verification and gratuitous grants',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // STEPPER
                  Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: AppColors.primaryBlue,
                        surface: isDark ? AppColors.darkSurfaceCard : Colors.white,
                      ),
                    ),
                    child: Stepper(
                      currentStep: _currentStep,
                      physics: const NeverScrollableScrollPhysics(),
                      onStepContinue: () {
                        if (_currentStep < 4) {
                          setState(() => _currentStep++);
                        } else {
                          _submitDamageReport();
                        }
                      },
                      onStepCancel: () {
                        if (_currentStep > 0) {
                          setState(() => _currentStep--);
                        }
                      },
                      controlsBuilder: (context, details) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Row(
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                onPressed: details.onStepContinue,
                                child: Text(_currentStep == 4 ? 'Confirm & Submit Claim' : 'Continue Next Step'),
                              ),
                              if (_currentStep > 0) ...[
                                const SizedBox(width: 12),
                                OutlinedButton(
                                  onPressed: details.onStepCancel,
                                  child: const Text('Back'),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                      steps: [
                        // STEP 1: Incident & Location
                        Step(
                          title: const Text('Incident & Location', style: TextStyle(fontWeight: FontWeight.bold)),
                          isActive: _currentStep >= 0,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Disaster Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<IncidentCategory>(
                                value: _category,
                                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                                items: IncidentCategory.values.map((c) {
                                  return DropdownMenuItem(value: c, child: Text(c.name.toUpperCase()));
                                }).toList(),
                                onChanged: (v) => setState(() => _category = v ?? IncidentCategory.flood),
                              ),
                              const SizedBox(height: 14),
                              const Text('Claim Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _titleController,
                                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                              ),
                              const SizedBox(height: 14),
                              const Text('Full Locality Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _addressController,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.location_on_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // STEP 2: Damage & Affected People
                        Step(
                          title: const Text('Damage & Affected People', style: TextStyle(fontWeight: FontWeight.bold)),
                          isActive: _currentStep >= 1,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Household Members Count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        TextField(
                                          controller: _householdCountController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Estimated Loss (INR ₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        TextField(
                                          controller: _estimatedLossController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            prefixText: '₹ ',
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text('Affected Property Categories', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: _propertyOptions.map((prop) {
                                  final isSel = _selectedProperties.contains(prop);
                                  return FilterChip(
                                    label: Text(prop),
                                    selected: isSel,
                                    selectedColor: AppColors.primaryBlue.withOpacity(0.2),
                                    onSelected: (v) {
                                      setState(() {
                                        if (v) {
                                          _selectedProperties.add(prop);
                                        } else {
                                          _selectedProperties.remove(prop);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                        // STEP 3: Assistance Required
                        Step(
                          title: const Text('Assistance Required', style: TextStyle(fontWeight: FontWeight.bold)),
                          isActive: _currentStep >= 2,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Select Immediate Relief Requirements', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: _needsOptions.map((need) {
                                  final isSel = _selectedNeeds.contains(need);
                                  return FilterChip(
                                    label: Text(need),
                                    selected: isSel,
                                    selectedColor: AppColors.successGreen.withOpacity(0.2),
                                    onSelected: (v) {
                                      setState(() {
                                        if (v) {
                                          _selectedNeeds.add(need);
                                        } else {
                                          _selectedNeeds.remove(need);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                        // STEP 4: Evidence & Notes
                        Step(
                          title: const Text('Optional Evidence & Description', style: TextStyle(fontWeight: FontWeight.bold)),
                          isActive: _currentStep >= 3,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Detailed Incident Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _descriptionController,
                                maxLines: 3,
                                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.photo_library, color: AppColors.primaryBlue),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Photo Evidence: flood_damage_submerged_house_east_delhi.jpg',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                            ],
                          ),
                        ),

                        // STEP 5: Review & Submit
                        Step(
                          title: const Text('Review & Confirmation', style: TextStyle(fontWeight: FontWeight.bold)),
                          isActive: _currentStep >= 4,
                          content: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Claim Summary: ${_titleController.text}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 6),
                                Text('Location: ${_addressController.text}', style: const TextStyle(fontSize: 12)),
                                Text('Estimated Economic Loss: ₹${_estimatedLossController.text}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                                Text('Household Count: ${_householdCountController.text} persons', style: const TextStyle(fontSize: 12)),
                                Text('Requested Relief: ${_selectedNeeds.join(', ')}', style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 10),
                                const Text(
                                  'By submitting, you consent to field verification by the designated Revenue Inspector/Patwari.',
                                  style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitDamageReport() {
    final reportId = 'RQ-DMG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final user = ref.read(authProvider);

    final loss = double.tryParse(_estimatedLossController.text) ?? 150000.0;
    final count = int.tryParse(_householdCountController.text) ?? 4;

    final incident = IncidentModel(
      id: reportId,
      title: _titleController.text,
      descriptionOriginal: _descriptionController.text,
      descriptionTranslated: _descriptionController.text,
      category: _category,
      latitude: 28.6200,
      longitude: 77.2800,
      address: _addressController.text,
      status: IncidentStatus.received,
      priorityScore: 78.0,
      priorityExplanation: 'Damage claim filed with estimated loss of ₹$loss',
      vulnerableGroups: const [],
      reporterPhoneMasked: user?.phoneMasked ?? '+91 98*** **210',
      reportedAt: DateTime.now(),
      source: 'DAMAGE_REPORT',
      affectedProperties: _selectedProperties,
      estimatedLossInr: loss,
      householdMembersCount: count,
      reliefRequirements: _selectedNeeds,
    );

    ref.read(incidentsProvider.notifier).addIncident(incident);

    // Redirect to dedicated report detail page
    Navigator.pushReplacementNamed(context, '${AppRoutes.citizenReports}/$reportId');
  }
}
