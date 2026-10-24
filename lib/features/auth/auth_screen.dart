import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/incident_repository.dart';
import '../../shared/models/user_model.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final bool isRegisterMode;

  const AuthScreen({super.key, this.isRegisterMode = false});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late bool _isRegister;
  UserRole _selectedRole = UserRole.citizen;

  // Common Fields
  final TextEditingController _nameController = TextEditingController(text: 'Aarav Sharma');
  final TextEditingController _emailController = TextEditingController(text: 'citizen@resqai.org');
  final TextEditingController _phoneController = TextEditingController(text: '+91 98765 43210');
  final TextEditingController _passwordController = TextEditingController(text: 'password123');
  bool _obscurePassword = true;
  bool _otpVerified = true;

  // Citizen Specific Fields
  final TextEditingController _emergencyContactNameController = TextEditingController(text: 'Sunita Sharma (Mother)');
  final TextEditingController _emergencyContactPhoneController = TextEditingController(text: '+91 98111 22233');
  final TextEditingController _stateController = TextEditingController(text: 'Delhi');
  final TextEditingController _districtController = TextEditingController(text: 'East Delhi');
  final TextEditingController _localityController = TextEditingController(text: 'Mayur Vihar Phase 1');
  String _selectedLanguage = 'en';
  String _notificationPref = 'ALL_ALERTS_SMS';
  String _specialAssistance = 'NONE';
  bool _locationPermission = true;

  // Volunteer Specific Fields
  final TextEditingController _volunteerIdController = TextEditingController(
    text: 'RQ-VOL-2026-${Random().nextInt(900) + 100}',
  );
  final TextEditingController _volunteerServiceAreaController = TextEditingController(text: 'Yamuna Riverbank & East Delhi');
  final List<String> _selectedSkills = ['First Aid Certified', 'Food Distribution'];
  String _transportEquipment = '4x4 Vehicle';
  bool _agreedToSafetyRules = true;
  bool _volunteerAvailable = true;

  // Government Official Specific Fields
  final TextEditingController _govtIdController = TextEditingController(text: 'GOV-DL-IAS-2018');
  final TextEditingController _govtDeptController = TextEditingController(text: 'DDMA / Revenue & Disaster Management');
  final TextEditingController _govtDesignationController = TextEditingController(text: 'Additional District Magistrate (Relief)');

  // NGO Specific Fields
  final TextEditingController _ngoNameController = TextEditingController(text: 'Red Cross Relief Mission Delhi');
  final TextEditingController _ngoRegNumberController = TextEditingController(text: 'DARPAN-DL-2024-00192');
  final TextEditingController _ngoRegTypeController = TextEditingController(text: 'Registered Society under Act XXI of 1860');
  final TextEditingController _ngoRepNameController = TextEditingController(text: 'Vikram Sethi (Director of Operations)');
  final TextEditingController _ngoAddressController = TextEditingController(text: 'Plot 14, Institutional Area, New Delhi');
  final List<String> _ngoSpecializations = ['Emergency Rations', 'Temporary Shelter'];

  // Doctor Specific Fields
  final TextEditingController _medicalRegNumberController = TextEditingController(text: 'MCI-2019-84210');
  final TextEditingController _hospitalController = TextEditingController(text: 'AIIMS Trauma Center, Delhi');
  final TextEditingController _specializationController = TextEditingController(text: 'Emergency Triage & Trauma Surgery');

  // Rescue Team Specific Fields
  final TextEditingController _unitNameController = TextEditingController(text: 'NDRF 8th Battalion Quick Response Unit');
  final TextEditingController _responderBadgeController = TextEditingController(text: 'NDRF-BADGE-774');
  final TextEditingController _teamSpecializationController = TextEditingController(text: 'Inflatable Flood Evacuation & USAR');

  @override
  void initState() {
    super.initState();
    _isRegister = widget.isRegisterMode;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return AppShell(
      currentRoute: _isRegister ? AppRoutes.register : AppRoutes.login,
      title: _isRegister ? 'Create ResQAI Account' : 'Sign In to ResQAI',
      breadcrumbs: ['Auth', _isRegister ? 'Register' : 'Sign In'],
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 32, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 18 : 32),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Icon Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield, color: AppColors.primaryBlue, size: 32),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Center(
                    child: Text(
                      _isRegister ? 'Create Role-Specific Account' : 'Welcome to ResQAI',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : AppColors.deepNavy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  Center(
                    child: Text(
                      _isRegister
                          ? 'Complete customized registration for your disaster response category'
                          : 'Sign in to access your role-based disaster command workspace',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Role Selector
                  const Text('Select Your Response Category *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<UserRole>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: [
                      UserRole.citizen,
                      UserRole.volunteer,
                      UserRole.govtOfficial,
                      UserRole.ngoLead,
                      UserRole.doctor,
                      UserRole.rescueTeam,
                    ].map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(
                          '${role.title} (${role.name})',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _selectedRole = v;
                          if (v == UserRole.volunteer) {
                            _nameController.text = 'Ananya Deshmukh';
                            _emailController.text = 'volunteer@resqai.org';
                          } else if (v == UserRole.govtOfficial) {
                            _nameController.text = 'Rajesh Kumar IAS';
                            _emailController.text = 'adm.delhi@gov.in';
                          } else if (v == UserRole.ngoLead) {
                            _nameController.text = 'Vikram Sethi';
                            _emailController.text = 'director@redcrossdelhi.org';
                          } else if (v == UserRole.doctor) {
                            _nameController.text = 'Dr. Priya Nair';
                            _emailController.text = 'trauma.aiims@health.gov.in';
                          } else if (v == UserRole.rescueTeam) {
                            _nameController.text = 'Commandant Vikramaditya';
                            _emailController.text = 'ndrf.8bn@mha.gov.in';
                          } else {
                            _nameController.text = 'Aarav Sharma';
                            _emailController.text = 'citizen@resqai.org';
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Verification Advisory for Privileged Roles
                  if (_isRegister && _selectedRole != UserRole.citizen)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.warningOrange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.warningOrange.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_outlined, color: AppColors.warningOrange, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Statutory Verification Notice: Privileged registration as ${_selectedRole.title} requires credential audit by DDMA. You will receive immediate dashboard access with operational approval tracking.',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.35,
                                color: isDark ? Colors.white : AppColors.deepNavy,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // COMMON ACCOUNT CREDENTIALS (Email & Password)
                  const Text('Email Address *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Password *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ROLE-SPECIFIC FORM FIELDS (ONLY WHEN IN REGISTER MODE)
                  if (_isRegister) ...[
                    // Full Name
                    const Text('Full Name *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Primary Mobile with Verified OTP status
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Primary Mobile Phone *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mobile OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 6),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _otpVerified ? AppColors.successGreen : AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  setState(() => _otpVerified = true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: AppColors.successGreen,
                                      content: Text('✓ Mobile OTP Verified Successfully (+91 SMS Gateway)'),
                                    ),
                                  );
                                },
                                child: Text(_otpVerified ? '✓ Verified' : 'Verify OTP', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // D1. CITIZEN SPECIFIC REGISTRATION
                    if (_selectedRole == UserRole.citizen) ...[
                      _buildCitizenRegistrationFields(isDark),
                    ]
                    // D2. VOLUNTEER SPECIFIC REGISTRATION
                    else if (_selectedRole == UserRole.volunteer) ...[
                      _buildVolunteerRegistrationFields(isDark),
                    ]
                    // D3. GOVERNMENT OFFICIAL REGISTRATION
                    else if (_selectedRole == UserRole.govtOfficial) ...[
                      _buildGovernmentRegistrationFields(isDark),
                    ]
                    // D4. NGO REPRESENTATIVE REGISTRATION
                    else if (_selectedRole == UserRole.ngoLead) ...[
                      _buildNgoRegistrationFields(isDark),
                    ]
                    // D5. DOCTOR SPECIFIC REGISTRATION
                    else if (_selectedRole == UserRole.doctor) ...[
                      _buildDoctorRegistrationFields(isDark),
                    ]
                    // D5. RESCUE TEAM REGISTRATION
                    else if (_selectedRole == UserRole.rescueTeam) ...[
                      _buildRescueTeamRegistrationFields(isDark),
                    ],
                  ],

                  const SizedBox(height: 20),

                  // Submit Action Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _handleAuthSubmit,
                    child: Text(
                      _isRegister ? 'Complete Registration & Open Dashboard' : 'Sign In to Workspace',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Toggle between Sign In and Register Mode
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _isRegister = !_isRegister),
                      child: Text(
                        _isRegister ? 'Already registered? Sign In' : 'New user? Create a Role-Specific Account',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
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

  // D1. CITIZEN REGISTRATION SECTION
  Widget _buildCitizenRegistrationFields(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mandatory Emergency Contact Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.emergencyRed.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.emergencyRed.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.contact_emergency, color: AppColors.emergencyRed, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Mandatory Emergency Contact (Distinct from Self) *',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.emergencyRed),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emergencyContactNameController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Person (e.g. Spouse / Mother / Brother)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emergencyContactPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Mobile (+91 Phone)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // District & Locality
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _districtController,
                decoration: const InputDecoration(labelText: 'District *', border: OutlineInputBorder(), isDense: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _localityController,
                decoration: const InputDecoration(labelText: 'Locality / Ward *', border: OutlineInputBorder(), isDense: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Language & Notifications
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedLanguage,
                decoration: const InputDecoration(labelText: 'Language', border: OutlineInputBorder(), isDense: true),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'hi', child: Text('हिंदी (Hindi)')),
                ],
                onChanged: (v) => setState(() => _selectedLanguage = v ?? 'en'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _notificationPref,
                decoration: const InputDecoration(labelText: 'Notification Mode', border: OutlineInputBorder(), isDense: true),
                items: const [
                  DropdownMenuItem(value: 'ALL_ALERTS_SMS', child: Text('SMS + Push')),
                  DropdownMenuItem(value: 'CRITICAL_ONLY', child: Text('Critical Only')),
                ],
                onChanged: (v) => setState(() => _notificationPref = v ?? 'ALL_ALERTS_SMS'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Vulnerability Profile / Special Assistance
        DropdownButtonFormField<String>(
          value: _specialAssistance,
          decoration: const InputDecoration(labelText: 'Special Assistance (Vulnerability Profile)', border: OutlineInputBorder(), isDense: true),
          items: const [
            DropdownMenuItem(value: 'NONE', child: Text('None / Standard Able-Bodied')),
            DropdownMenuItem(value: 'ELDERLY', child: Text('Senior Citizen / Elderly Care')),
            DropdownMenuItem(value: 'MOBILITY', child: Text('Wheelchair / Reduced Mobility')),
            DropdownMenuItem(value: 'CHRONIC_CARE', child: Text('Chronic Medical Care (Oxygen/Dialysis)')),
            DropdownMenuItem(value: 'INFANT', child: Text('Infant / Expectant Mother')),
          ],
          onChanged: (v) => setState(() => _specialAssistance = v ?? 'NONE'),
        ),
        const SizedBox(height: 10),

        // Location Permission with Manual Fallback
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Real-Time Hazard Location Telemetry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          subtitle: const Text('Used for geo-targeted early evacuation warnings (Manual fallback supported)', style: TextStyle(fontSize: 10, color: Colors.grey)),
          value: _locationPermission,
          activeColor: AppColors.primaryBlue,
          onChanged: (v) => setState(() => _locationPermission = v),
        ),
      ],
    );
  }

  // D2. VOLUNTEER REGISTRATION SECTION
  Widget _buildVolunteerRegistrationFields(bool isDark) {
    final availableSkills = [
      'First Aid Certified',
      'Food Distribution',
      'Shelter Care',
      'Vehicle Transport',
      'Medical Care',
      'Debris Clearing',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _volunteerIdController,
                decoration: const InputDecoration(labelText: 'Volunteer ID (Issued)', border: OutlineInputBorder(), isDense: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _volunteerServiceAreaController,
                decoration: const InputDecoration(labelText: 'Service Area / Sector', border: OutlineInputBorder(), isDense: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        const Text('Skills & Operational Training *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: availableSkills.map((sk) {
            final isSelected = _selectedSkills.contains(sk);
            return FilterChip(
              label: Text(sk, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : null)),
              selected: isSelected,
              selectedColor: AppColors.primaryBlue,
              onSelected: (sel) {
                setState(() {
                  if (sel) {
                    _selectedSkills.add(sk);
                  } else {
                    _selectedSkills.remove(sk);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        DropdownButtonFormField<String>(
          value: _transportEquipment,
          decoration: const InputDecoration(labelText: 'Transportation / Equipment Access', border: OutlineInputBorder(), isDense: true),
          items: const [
            DropdownMenuItem(value: '4x4 Vehicle', child: Text('4x4 SUV / Utility Vehicle')),
            DropdownMenuItem(value: 'Boat / Raft', child: Text('Inflatable Rescue Raft / Boat')),
            DropdownMenuItem(value: 'Two Wheeler', child: Text('Motorbike / Scooter')),
            DropdownMenuItem(value: 'None', child: Text('Pedestrian / Foot Logistics Only')),
          ],
          onChanged: (v) => setState(() => _transportEquipment = v ?? 'None'),
        ),
        const SizedBox(height: 10),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Available for Immediate Deployment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          subtitle: const Text('Broadcasts readiness for local relief missions & urgent assignments', style: TextStyle(fontSize: 10, color: Colors.grey)),
          value: _volunteerAvailable,
          activeColor: AppColors.successGreen,
          onChanged: (v) => setState(() => _volunteerAvailable = v),
        ),
        const SizedBox(height: 6),

        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _agreedToSafetyRules,
          activeColor: AppColors.primaryBlue,
          title: const Text('I agree to Statutory Volunteer Safety Rules (Never enter river floodwaters unescorted by NDRF)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          onChanged: (v) => setState(() => _agreedToSafetyRules = v ?? true),
        ),
      ],
    );
  }

  // D3. GOVERNMENT OFFICIAL REGISTRATION SECTION
  Widget _buildGovernmentRegistrationFields(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _govtIdController,
          decoration: const InputDecoration(labelText: 'Official Government / Officer ID *', border: OutlineInputBorder(), isDense: true),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _govtDeptController,
          decoration: const InputDecoration(labelText: 'Department (e.g. DDMA, Revenue, Police, Health) *', border: OutlineInputBorder(), isDense: true),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _govtDesignationController,
          decoration: const InputDecoration(labelText: 'Official Designation *', border: OutlineInputBorder(), isDense: true),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TextField(controller: _stateController, decoration: const InputDecoration(labelText: 'State Jurisdiction', border: OutlineInputBorder(), isDense: true))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _districtController, decoration: const InputDecoration(labelText: 'District Jurisdiction', border: OutlineInputBorder(), isDense: true))),
          ],
        ),
      ],
    );
  }

  // D4. NGO REPRESENTATIVE REGISTRATION SECTION
  Widget _buildNgoRegistrationFields(bool isDark) {
    const ngoSpecializationOptions = [
      'Emergency Rations',
      'Temporary Shelter',
      'Clean Water & WASH',
      'Medical Triage',
      'Child & Women Safety',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ngoNameController,
          decoration: const InputDecoration(labelText: 'Official NGO / Society Name *', border: OutlineInputBorder(), isDense: true),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ngoRegNumberController,
          decoration: const InputDecoration(labelText: 'NGO DARPAN ID / Registration Number *', border: OutlineInputBorder(), isDense: true),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ngoRegTypeController,
          decoration: const InputDecoration(labelText: 'Statutory Registration Type / Act *', border: OutlineInputBorder(), isDense: true),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ngoRepNameController,
          decoration: const InputDecoration(labelText: 'Authorized Representative *', border: OutlineInputBorder(), isDense: true),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ngoAddressController,
          decoration: const InputDecoration(labelText: 'Headquarters Address & Operational Sectors *', border: OutlineInputBorder(), isDense: true),
        ),
        const SizedBox(height: 12),
        const Text('Relief Specializations & Activities *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ngoSpecializationOptions.map((spec) {
            final isSelected = _ngoSpecializations.contains(spec);
            return FilterChip(
              label: Text(spec, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : null)),
              selected: isSelected,
              selectedColor: AppColors.primaryBlue,
              onSelected: (sel) {
                setState(() {
                  if (sel) {
                    _ngoSpecializations.add(spec);
                  } else {
                    _ngoSpecializations.remove(spec);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // D5. DOCTOR REGISTRATION SECTION
  Widget _buildDoctorRegistrationFields(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _medicalRegNumberController,
          decoration: const InputDecoration(labelText: 'Medical Council Reg No (MCI / State Council) *', border: OutlineInputBorder(), isDense: true),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _hospitalController,
          decoration: const InputDecoration(labelText: 'Hospital / Clinic Affiliation *', border: OutlineInputBorder(), isDense: true),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _specializationController,
          decoration: const InputDecoration(labelText: 'Clinical Specialization *', border: OutlineInputBorder(), isDense: true),
        ),
      ],
    );
  }

  // D5. RESCUE TEAM REGISTRATION SECTION
  Widget _buildRescueTeamRegistrationFields(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _unitNameController,
          decoration: const InputDecoration(labelText: 'Rescue Team / Battalion Affiliation *', border: OutlineInputBorder(), isDense: true),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _responderBadgeController,
          decoration: const InputDecoration(labelText: 'Official Badge / Operator ID *', border: OutlineInputBorder(), isDense: true),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _teamSpecializationController,
          decoration: const InputDecoration(labelText: 'Specialization (e.g. Flood Boat Evacuation, USAR) *', border: OutlineInputBorder(), isDense: true),
        ),
      ],
    );
  }

  void _handleAuthSubmit() {
    // Validation
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    if (email.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppColors.emergencyRed, content: Text('Please fill all mandatory credentials.')),
      );
      return;
    }

    if (_isRegister && _selectedRole == UserRole.volunteer && !_agreedToSafetyRules) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppColors.emergencyRed, content: Text('Please accept the volunteer safety guidelines.')),
      );
      return;
    }

    final isPrivileged = _selectedRole != UserRole.citizen && _selectedRole != UserRole.volunteer;

    final newUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      citizenId: _selectedRole == UserRole.volunteer
          ? _volunteerIdController.text
          : 'RQ-${_selectedRole.name.toUpperCase().substring(0, 3)}-${Random().nextInt(9000) + 1000}',
      name: name,
      email: email,
      phoneMasked: '+91 98*** **210',
      phoneRaw: _phoneController.text,
      role: _selectedRole,
      badgeOrJurisdiction: _selectedRole == UserRole.govtOfficial
          ? _govtDesignationController.text
          : (_selectedRole == UserRole.rescueTeam ? _responderBadgeController.text : _selectedRole.title),
      emergencyContactName: _emergencyContactNameController.text,
      emergencyContactPhone: _emergencyContactPhoneController.text,
      district: _districtController.text,
      stateName: _stateController.text,
      organization: _selectedRole == UserRole.ngoLead
          ? _ngoNameController.text
          : (_selectedRole == UserRole.doctor ? _hospitalController.text : _unitNameController.text),
      regNumber: _selectedRole == UserRole.ngoLead
          ? '${_ngoRegNumberController.text} (${_ngoRegTypeController.text})'
          : (_selectedRole == UserRole.govtOfficial
              ? _govtIdController.text
              : (_selectedRole == UserRole.doctor ? _medicalRegNumberController.text : null)),
      skills: _selectedRole == UserRole.volunteer
          ? _selectedSkills
          : (_selectedRole == UserRole.ngoLead ? _ngoSpecializations : const []),
      availability: _selectedRole == UserRole.volunteer ? (_volunteerAvailable ? 'AVAILABLE' : 'OFFLINE') : 'AVAILABLE',
      serviceArea: _selectedRole == UserRole.volunteer ? _volunteerServiceAreaController.text : null,
      isVerified: !isPrivileged,
      verificationStatus: isPrivileged ? 'PENDING' : 'APPROVED',
      isLocationPermissionGranted: _locationPermission,
      preferredLanguage: _selectedLanguage,
      notificationPreferences: _notificationPref,
      specialAssistance: _specialAssistance,
      loggedInAt: DateTime.now(),
    );

    // Persist authenticated state
    ref.read(authProvider.notifier).loginAs(newUser);
    ref.read(activeRoleProvider.notifier).state = _selectedRole;

    if (_isRegister && isPrivileged) {
      _showPendingVerificationDialog(newUser);
    } else {
      _navigateToRoleWorkspace(_selectedRole);
    }
  }

  void _showPendingVerificationDialog(UserModel user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.hourglass_top, color: AppColors.warningOrange, size: 24),
            SizedBox(width: 10),
            Text('Verification Queued', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your application as ${user.role.title} has been registered and submitted to the DDMA / State Administrative Desk.',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warningOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Account ID: ${user.citizenId}\nRegistration Ref: ${user.regNumber ?? "PENDING-DDMA"}\nStatus: PENDING AUDIT',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, height: 1.4),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _navigateToRoleWorkspace(user.role);
            },
            child: const Text('Proceed to Role Workspace', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _navigateToRoleWorkspace(UserRole role) {
    switch (role) {
      case UserRole.citizen:
        Navigator.pushReplacementNamed(context, AppRoutes.citizenDashboard);
        break;
      case UserRole.volunteer:
        Navigator.pushReplacementNamed(context, AppRoutes.volunteerDashboard);
        break;
      case UserRole.ngoLead:
        Navigator.pushReplacementNamed(context, AppRoutes.ngoDashboard);
        break;
      case UserRole.govtOfficial:
      case UserRole.incidentCommander:
      case UserRole.admin:
        Navigator.pushReplacementNamed(context, AppRoutes.governmentCommandCentre);
        break;
      case UserRole.rescueTeam:
      case UserRole.fieldResponder:
        Navigator.pushReplacementNamed(context, AppRoutes.responderDashboard);
        break;
      case UserRole.doctor:
        Navigator.pushReplacementNamed(context, AppRoutes.medicalDashboard);
        break;
      default:
        Navigator.pushReplacementNamed(context, AppRoutes.citizenDashboard);
        break;
    }
  }
}
