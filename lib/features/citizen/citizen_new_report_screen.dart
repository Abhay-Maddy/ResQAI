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
  final TextEditingController _titleController =
      TextEditingController(text: 'Structural Boundary Wall Collapse & Inundation');
  final TextEditingController _stateDistrictController =
      TextEditingController(text: 'East Delhi, NCT of Delhi');
  final TextEditingController _addressController =
      TextEditingController(text: 'House 42, Yamuna Khadar Sector 4, East Delhi');
  final TextEditingController _safetyConcernsController =
      TextEditingController(text: 'Water rising near electrical transformer; boundary wall weakened.');
  DateTime _incidentDate = DateTime.now().subtract(const Duration(hours: 6));

  // Step 2: Family & Confidential Missing Persons
  final TextEditingController _householdCountController = TextEditingController(text: '5');
  bool _hasMissingPerson = false;
  final TextEditingController _missingPersonsCountController = TextEditingController(text: '1');
  final TextEditingController _missingPersonsDetailsController = TextEditingController(
    text: 'Rajesh Sharma, 64 yrs, wearing blue kurta. Last seen near Mayur Vihar bund at 4 PM.',
  );
  bool _missingPersonEmergencyNeeded = true;

  // Step 3: Damage & Affected Properties
  String _damageSeverity = 'Severe Structural Damage';
  final List<String> _severityLevels = [
    'Minor (Habitable with repairs)',
    'Moderate (Partial flooding / damaged contents)',
    'Severe Structural Damage',
    'Total Destruction / Collapsed',
  ];
  final TextEditingController _estimatedLossController = TextEditingController(text: '250000');
  final List<String> _selectedProperties = [
    'Pucca Housing Structure',
    'Flooding Inside Living Area',
    'Agricultural Standing Crops',
  ];
  final List<String> _propertyOptions = [
    'Pucca Housing Structure',
    'Kutcha Mud House / Thatched Roof',
    'Flooding Inside Living Area',
    'Agricultural Standing Crops',
    'Livestock & Cattle (Cow/Buffalo/Goats)',
    'Small Business / Shop / Artisan Kiosk',
    'Household Electronics & Vehicles',
    'Sanitation / Borewell Contamination',
  ];

  // Step 4: Lost or Damaged Vital Documents
  final List<String> _selectedDocuments = [
    'Aadhaar Identity Card',
    'Ration Card (NFSA / PDS)',
    'Bank Passbook / Financial Records',
  ];
  final List<String> _documentOptions = [
    'Aadhaar Identity Card',
    'Ration Card (NFSA / PDS)',
    'Voter ID (EPIC)',
    'Land / Property Ownership Deed',
    'Bank Passbook / Financial Records',
    'Educational / School Certificates',
    'Health Insurance / Ayushman Card',
    'Disability / Pension Certificate',
  ];

  // Step 5: Assistance Required
  final List<String> _selectedNeeds = [
    'Drinking Water Cans',
    'Dry Food Rations / Kitchen Kits',
    'Waterproof Tarpaulins & Tents',
    'Emergency Ex-Gratia Financial Relief',
  ];
  final List<String> _needsOptions = [
    'Drinking Water Cans',
    'Dry Food Rations / Kitchen Kits',
    'Waterproof Tarpaulins & Tents',
    'Warm Blankets & Clothing',
    'Emergency Medicine & First Aid',
    'Temporary Shelter Relocation',
    'Elderly / Disabled Transit Assistance',
    'Emergency Ex-Gratia Financial Relief',
    'Crop & Livestock Replacement Support',
    'Fast-Track Document Replacement Assistance',
  ];

  // Step 6: Evidence & Description
  final TextEditingController _descriptionController = TextEditingController(
    text: 'Ground floor submerged under 3.5 ft water; northern boundary wall collapsed. Two buffaloes evacuated to embankment. Vital rations submerged.',
  );
  bool _attachedPhotoSimulation = true;
  bool _consentAgreed = true;

  @override
  void dispose() {
    _titleController.dispose();
    _stateDistrictController.dispose();
    _addressController.dispose();
    _safetyConcernsController.dispose();
    _householdCountController.dispose();
    _missingPersonsCountController.dispose();
    _missingPersonsDetailsController.dispose();
    _estimatedLossController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return AppShell(
      currentRoute: AppRoutes.citizenNewReport,
      title: 'Disaster Damage & Relief Claim',
      breadcrumbs: const ['Citizen', 'Damage Claims', 'New Report'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 32,
          vertical: isMobile ? 16 : 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 16 : 28),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.assignment_turned_in, color: AppColors.primaryBlue, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Disaster Damage & SDRF Assistance Claim',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 19,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : AppColors.deepNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '6-Step statutory assessment form for revenue inspections and direct assistance',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

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
                        if (_currentStep < 5) {
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
                          padding: const EdgeInsets.only(top: 24),
                          child: Row(
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _currentStep == 5 ? AppColors.successGreen : AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: details.onStepContinue,
                                child: Text(
                                  _currentStep == 5 ? 'Submit Formal Claim ✓' : 'Save & Continue →',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (_currentStep > 0) ...[
                                const SizedBox(width: 12),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
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
                              const Text('Disaster Classification', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                              const Text('Damage / Incident Headline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _titleController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Roof blown off during storm',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('State & District', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        TextField(
                                          controller: _stateDistrictController,
                                          decoration: InputDecoration(
                                            prefixIcon: const Icon(Icons.map_outlined, size: 18),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                                        const Text('Date of Impact', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        InkWell(
                                          onTap: () async {
                                            final d = await showDatePicker(
                                              context: context,
                                              initialDate: _incidentDate,
                                              firstDate: DateTime.now().subtract(const Duration(days: 90)),
                                              lastDate: DateTime.now(),
                                            );
                                            if (d != null) setState(() => _incidentDate = d);
                                          },
                                          child: Container(
                                            height: 52,
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey.shade400),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            alignment: Alignment.centerLeft,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('${_incidentDate.day}/${_incidentDate.month}/${_incidentDate.year}'),
                                                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Text('Specific Property Address / Landmark', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _addressController,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                                  hintText: 'House no, Street, Ward / Village',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text('Immediate Safety Concerns (if any)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _safetyConcernsController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Hanging electric wires, rising river water, vulnerable embankment',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // STEP 2: Family & Confidential Missing Persons
                        Step(
                          title: const Text('Family & Missing Persons', style: TextStyle(fontWeight: FontWeight.bold)),
                          isActive: _currentStep >= 1,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Affected Household Members', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _householdCountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.group_outlined, size: 18),
                                  hintText: 'Number of persons residing in household',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.emergencyRed.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.emergencyRed.withOpacity(0.2)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_search, color: AppColors.emergencyRed, size: 22),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Report Missing or Separated Family Member?',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.emergencyRed)),
                                          Text('Confidential NDRF/Police search workflow',
                                              style: TextStyle(fontSize: 11, color: Colors.black54)),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: _hasMissingPerson,
                                      activeColor: AppColors.emergencyRed,
                                      onChanged: (v) => setState(() => _hasMissingPerson = v),
                                    ),
                                  ],
                                ),
                              ),
                              if (_hasMissingPerson) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.amber.shade300),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.lock_outline, color: Colors.brown, size: 18),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'CONFIDENTIAL: Missing person records are strictly restricted to authorized search teams. Never displayed on the public map.',
                                          style: TextStyle(fontSize: 11, color: Colors.brown, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text('Number of Persons Missing / Separated', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _missingPersonsCountController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                                ),
                                const SizedBox(height: 12),
                                const Text('Identifying Details (Name, Age, Clothing, Last Seen Time & Spot)',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _missingPersonsDetailsController,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Name, physical features, clothes, contact number for search teams',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  value: _missingPersonEmergencyNeeded,
                                  activeColor: AppColors.emergencyRed,
                                  title: const Text('Immediate tactical search & rescue dispatch required',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  onChanged: (v) => setState(() => _missingPersonEmergencyNeeded = v ?? true),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // STEP 3: Property & Structural Damage
                        Step(
                          title: const Text('Property & Loss', style: TextStyle(fontWeight: FontWeight.bold)),
                          isActive: _currentStep >= 2,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Damage Severity Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _damageSeverity,
                                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                                items: _severityLevels.map((lvl) => DropdownMenuItem(value: lvl, child: Text(lvl))).toList(),
                                onChanged: (v) => setState(() => _damageSeverity = v ?? _severityLevels[2]),
                              ),
                              const SizedBox(height: 14),
                              const Text('Estimated Economic Loss (INR ₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _estimatedLossController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  prefixText: '₹ ',
                                  hintText: 'Estimated rupees',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text('Affected Assets (Select All That Apply)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: _propertyOptions.map((prop) {
                                  final isSel = _selectedProperties.contains(prop);
                                  return FilterChip(
                                    label: Text(prop, style: TextStyle(fontSize: 12, color: isSel ? AppColors.primaryBlue : null)),
                                    selected: isSel,
                                    selectedColor: AppColors.primaryBlue.withOpacity(0.18),
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

                        // STEP 4: Lost / Submerged Documents
                        Step(
                          title: const Text('Vital Document Losses', style: TextStyle(fontWeight: FontWeight.bold)),
                          isActive: _currentStep >= 3,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Check all vital identity & property records damaged, lost, or rendered inaccessible:',
                                style: TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: _documentOptions.map((doc) {
                                  final isSel = _selectedDocuments.contains(doc);
                                  return FilterChip(
                                    label: Text(doc, style: TextStyle(fontSize: 12, color: isSel ? AppColors.warningOrange : null)),
                                    selected: isSel,
                                    selectedColor: AppColors.warningOrange.withOpacity(0.2),
                                    onSelected: (v) {
                                      setState(() {
                                        if (v) {
                                          _selectedDocuments.add(doc);
                                        } else {
                                          _selectedDocuments.remove(doc);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline, color: AppColors.primaryBlue, size: 16),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Marking lost documents automatically alerts District Revenue Counters for expedited, fee-exempt certificate re-issuance.',
                                        style: TextStyle(fontSize: 11, color: AppColors.deepNavy),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // STEP 5: Required Assistance
                        Step(
                          title: const Text('Assistance Needed', style: TextStyle(fontWeight: FontWeight.bold)),
                          isActive: _currentStep >= 4,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Immediate Humanitarian Assistance Requirements',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: _needsOptions.map((need) {
                                  final isSel = _selectedNeeds.contains(need);
                                  return FilterChip(
                                    label: Text(need, style: TextStyle(fontSize: 12, color: isSel ? AppColors.successGreen : null)),
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

                        // STEP 6: Evidence & Final Review
                        Step(
                          title: const Text('Evidence & Submit', style: TextStyle(fontWeight: FontWeight.bold)),
                          isActive: _currentStep >= 5,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Detailed Narrative of Damage & Event', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _descriptionController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: 'Describe physical damages, losses, and sequence of events...',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurfaceCard : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.add_photo_alternate, color: AppColors.primaryBlue),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Geotagged Photo Proof Attached', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                          Text('submerged_house_damaged_wall_sector4.jpg (2.4 MB)',
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
                              const SizedBox(height: 14),
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                value: _consentAgreed,
                                activeColor: AppColors.primaryBlue,
                                title: const Text(
                                  'I solemnly declare that the statements above are true to the best of my knowledge and consent to field verification by the Revenue Inspector/Patwari under the Disaster Management Act, 2005.',
                                  style: TextStyle(fontSize: 11, color: Colors.black87),
                                ),
                                onChanged: (v) => setState(() => _consentAgreed = v ?? true),
                              ),
                            ],
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
    if (!_consentAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warningOrange,
          content: Text('Please accept the statutory declaration of truth before submitting.'),
        ),
      );
      return;
    }

    final reportId = 'RQ-DMG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final user = ref.read(authProvider);

    final loss = double.tryParse(_estimatedLossController.text) ?? 200000.0;
    final count = int.tryParse(_householdCountController.text) ?? 4;
    final missingCount = _hasMissingPerson ? (int.tryParse(_missingPersonsCountController.text) ?? 1) : 0;

    final incident = IncidentModel(
      id: reportId,
      title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Disaster Damage Claim',
      descriptionOriginal: _descriptionController.text,
      descriptionTranslated: _descriptionController.text,
      category: _category,
      latitude: 28.6200,
      longitude: 77.2800,
      address: '${_addressController.text}, ${_stateDistrictController.text}',
      status: IncidentStatus.received,
      priorityScore: _hasMissingPerson ? 95.0 : 75.0,
      priorityExplanation: _hasMissingPerson
          ? 'Urgent: Missing person report ($missingCount missing) with ₹$loss economic loss'
          : 'Damage claim filed with estimated loss of ₹$loss across ${_selectedProperties.length} property categories',
      vulnerableGroups: const [],
      reporterPhoneMasked: user?.phoneMasked ?? '+91 98*** **210',
      reportedAt: DateTime.now(),
      source: 'CITIZEN_DAMAGE_CLAIM',
      affectedProperties: _selectedProperties,
      estimatedLossInr: loss,
      householdMembersCount: count,
      reliefRequirements: _selectedNeeds,
      missingPersonsCount: missingCount,
      missingPersonsDetails: _hasMissingPerson ? _missingPersonsDetailsController.text : null,
      missingPersonEmergencyAssistanceNeeded: _missingPersonEmergencyNeeded,
      lostDocuments: _selectedDocuments,
      immediateSafetyConcerns: _safetyConcernsController.text,
      assistanceDeliveryStatus: 'PENDING_SANCTION',
      reliefAssistanceCategory: _selectedNeeds.isNotEmpty ? _selectedNeeds.first : 'SDRF Ex-Gratia Grant',
      evidencePhotos: _attachedPhotoSimulation ? ['submerged_house_damaged_wall_sector4.jpg'] : const [],
    );

    ref.read(incidentsProvider.notifier).addIncident(incident);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.successGreen,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Claim $reportId logged. Routed to District Revenue Authority.')),
          ],
        ),
      ),
    );

    // Redirect to citizen reports page or detail page
    Navigator.pushReplacementNamed(context, '${AppRoutes.citizenReports}/$reportId');
  }
}
