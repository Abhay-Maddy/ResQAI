import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/incident_repository.dart';
import '../../shared/models/user_model.dart';
import '../../app.dart';
import 'admin_verification_modal.dart';
import '../../core/router/app_router.dart';

class LoginModal extends ConsumerStatefulWidget {
  const LoginModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const LoginModal(),
    );
  }

  @override
  ConsumerState<LoginModal> createState() => _LoginModalState();
}

class _LoginModalState extends ConsumerState<LoginModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Manual sign-in controllers
  final _emailController = TextEditingController(text: 'rajesh.ndrf@gov.in');
  final _passwordController = TextEditingController(text: '••••••••');
  UserRole _selectedRole = UserRole.fieldResponder;
  bool _obscurePassword = true;

  // Registration controllers
  UserRole _regRole = UserRole.citizen;
  final _regNameController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regEmergencyContactNameController = TextEditingController();
  final _regEmergencyContactPhoneController = TextEditingController();
  final _regStateController = TextEditingController(text: 'Delhi');
  final _regDistrictController = TextEditingController(text: 'East Delhi');
  final _regLocalityController = TextEditingController(text: 'Yamuna Khadar Ward 4');
  String _selectedBloodGroup = 'O+';
  String _selectedLanguage = 'en';
  String _selectedNotifPref = 'ALL_ALERTS_SMS';
  String _selectedAssistance = 'NONE';
  bool _grantLocationPermission = true;

  // OTP Verification state
  bool _otpSent = false;
  bool _otpVerified = false;
  final _otpInputController = TextEditingController();

  // Privileged Role Specific Fields
  final _orgNameController = TextEditingController();
  final _regNumberController = TextEditingController(); // DARPAN, Medical ID, Govt Employee ID, Battalion
  final _departmentController = TextEditingController();
  final _specializationController = TextEditingController();
  final _equipmentController = TextEditingController();
  final _availabilityController = TextEditingController(text: 'AVAILABLE');
  final List<String> _selectedVolunteerSkills = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _regNameController.dispose();
    _regPhoneController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regEmergencyContactNameController.dispose();
    _regEmergencyContactPhoneController.dispose();
    _regStateController.dispose();
    _regDistrictController.dispose();
    _regLocalityController.dispose();
    _otpInputController.dispose();
    _orgNameController.dispose();
    _regNumberController.dispose();
    _departmentController.dispose();
    _specializationController.dispose();
    _equipmentController.dispose();
    _availabilityController.dispose();
    super.dispose();
  }

  void _navigateToDashboard(UserRole role) {
    switch (role) {
      case UserRole.citizen:
        Navigator.pushReplacementNamed(context, AppRoutes.citizenDashboard);
        break;
      case UserRole.volunteer:
        Navigator.pushReplacementNamed(context, AppRoutes.volunteerDashboard);
        break;
      case UserRole.ngoLead:
      case UserRole.reliefStaff:
        Navigator.pushReplacementNamed(context, AppRoutes.ngoDashboard);
        break;
      case UserRole.govtOfficial:
      case UserRole.incidentCommander:
      case UserRole.admin:
      case UserRole.analyst:
        Navigator.pushReplacementNamed(context, AppRoutes.governmentCommandCentre);
        break;
      case UserRole.fieldResponder:
      case UserRole.rescueTeam:
        Navigator.pushReplacementNamed(context, AppRoutes.responderDashboard);
        break;
      case UserRole.doctor:
        Navigator.pushReplacementNamed(context, AppRoutes.medicalDashboard);
        break;
    }
  }

  void _loginAsPreset(UserModel user) {
    ref.read(authProvider.notifier).loginAs(user);
    ref.read(activeRoleProvider.notifier).state = user.role;
    if (user.role == UserRole.citizen) {
      ref.read(currentTabProvider.notifier).state = MainNavigationTab.citizenSos;
    } else if (user.role == UserRole.fieldResponder || user.role == UserRole.rescueTeam) {
      ref.read(currentTabProvider.notifier).state = MainNavigationTab.tacticalMap;
    } else {
      ref.read(currentTabProvider.notifier).state = MainNavigationTab.roleDashboard;
    }
    Navigator.of(context).pop();
    _navigateToDashboard(user.role);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.verifiedGreen,
        content: Text('✓ Authenticated as ${user.name} (${user.role.title})'),
      ),
    );
  }

  void _submitManualLogin() {
    final email = _emailController.text.trim();
    final customUser = UserModel(
      id: 'USR-CUSTOM-${DateTime.now().millisecondsSinceEpoch % 1000}',
      citizenId: 'RQ-AUTH-${DateTime.now().millisecondsSinceEpoch % 9000 + 1000}',
      name: email.contains('@') ? email.split('@').first : 'Authorized Officer',
      email: email.isNotEmpty ? email : 'officer@resqai.gov.in',
      role: _selectedRole,
      badgeOrJurisdiction: 'Verified ${_selectedRole.title} Console',
      phoneMasked: '+91 98*** **000',
      emergencyContactName: 'Disaster Control Desk',
      emergencyContactPhone: '112 / 1078',
      bloodGroup: 'B+',
      isVerified: true,
      verificationStatus: 'APPROVED',
      loggedInAt: DateTime.now(),
    );

    ref.read(authProvider.notifier).loginAs(customUser);
    ref.read(activeRoleProvider.notifier).state = _selectedRole;
    if (_selectedRole == UserRole.citizen) {
      ref.read(currentTabProvider.notifier).state = MainNavigationTab.citizenSos;
    } else if (_selectedRole == UserRole.fieldResponder || _selectedRole == UserRole.rescueTeam) {
      ref.read(currentTabProvider.notifier).state = MainNavigationTab.tacticalMap;
    } else {
      ref.read(currentTabProvider.notifier).state = MainNavigationTab.roleDashboard;
    }
    Navigator.of(context).pop();
    _navigateToDashboard(customUser.role);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.verifiedGreen,
        content: Text('Welcome back, ${customUser.name}! Session persisted.'),
      ),
    );
  }

  void _sendOtp() {
    final phone = _regPhoneController.text.trim();
    if (phone.length < 10) {
      _showError('Enter a valid 10-digit mobile number before requesting OTP');
      return;
    }
    setState(() {
      _otpSent = true;
      _otpInputController.text = '8492'; // Simulated secure SMS OTP
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.infoBlue,
        content: Text('SMS OTP sent to your phone! Demo OTP: 8492 auto-filled.'),
      ),
    );
  }

  void _verifyOtp() {
    if (_otpInputController.text.trim() == '8492' || _otpInputController.text.trim().length >= 4) {
      setState(() {
        _otpVerified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.verifiedGreen,
          content: Text('✓ Phone number verified successfully via OTP!'),
        ),
      );
    } else {
      _showError('Invalid OTP code. Please enter the 4-digit code sent to your phone.');
    }
  }

  void _submitRegistration() {
    final name = _regNameController.text.trim();
    final phone = _regPhoneController.text.trim();
    final emergencyName = _regEmergencyContactNameController.text.trim();
    final emergencyPhone = _regEmergencyContactPhoneController.text.trim();

    if (name.isEmpty) {
      _showError('Please enter your full name');
      return;
    }
    if (phone.isEmpty) {
      _showError('Please enter your primary mobile number');
      return;
    }
    if (!_otpVerified) {
      _showError('Mandatory: Please verify your phone number with OTP');
      return;
    }
    if (emergencyPhone.isEmpty) {
      _showError('CRITICAL: Emergency Contact Number is mandatory');
      return;
    }

    final isCitizen = _regRole == UserRole.citizen;
    final prefix = isCitizen ? 'RQ-CIT' : 'RQ-${_regRole.name.toUpperCase().substring(0, 3)}';
    final newCitizenId = '$prefix-2026-${DateTime.now().millisecondsSinceEpoch % 9000 + 1000}';
    final maskedPhone = phone.length >= 4 
        ? '+91 *** ***${phone.substring(phone.length - 4)}'
        : '+91 98*** **123';

    // Privileged accounts require DDMA administrative verification (Part 4-D)
    final verificationStatus = isCitizen ? 'APPROVED' : 'PENDING';
    final isVerified = isCitizen;

    final newUser = UserModel(
      id: 'USR-${DateTime.now().millisecondsSinceEpoch % 10000}',
      citizenId: newCitizenId,
      name: name,
      email: _regEmailController.text.trim().isEmpty 
          ? '$name@${_regRole.name}.resqai.org'.toLowerCase().replaceAll(' ', '.') 
          : _regEmailController.text.trim(),
      role: _regRole,
      badgeOrJurisdiction: '${_regLocalityController.text.trim()}, ${_regDistrictController.text.trim()}',
      phoneMasked: maskedPhone,
      phoneRaw: phone,
      emergencyContactName: emergencyName.isEmpty ? 'Next of Kin' : emergencyName,
      emergencyContactPhone: emergencyPhone,
      bloodGroup: _selectedBloodGroup,
      isVerified: isVerified,
      verificationStatus: verificationStatus,
      organization: _orgNameController.text.trim().isNotEmpty ? _orgNameController.text.trim() : null,
      regNumber: _regNumberController.text.trim().isNotEmpty ? _regNumberController.text.trim() : null,
      serviceArea: '${_regDistrictController.text.trim()}, ${_regStateController.text.trim()}',
      skills: _selectedVolunteerSkills.isNotEmpty ? _selectedVolunteerSkills : ['Emergency Preparedness'],
      availability: _availabilityController.text.trim(),
      preferredLanguage: _selectedLanguage,
      notificationPreferences: _selectedNotifPref,
      specialAssistance: _selectedAssistance,
      stateName: _regStateController.text.trim(),
      district: _regDistrictController.text.trim(),
      isLocationPermissionGranted: _grantLocationPermission,
      loggedInAt: DateTime.now(),
    );

    // If privileged, add to DDMA / State Admin queue
    if (!isCitizen) {
      ref.read(pendingApprovalsProvider.notifier).addPending(newUser);
    }

    // Persist login session
    ref.read(authProvider.notifier).loginAs(newUser);
    ref.read(activeRoleProvider.notifier).state = _regRole;
    if (_regRole == UserRole.citizen) {
      ref.read(currentTabProvider.notifier).state = MainNavigationTab.citizenSos;
    } else {
      ref.read(currentTabProvider.notifier).state = MainNavigationTab.roleDashboard;
    }

    Navigator.of(context).pop();

    if (isCitizen) {
      _showCitizenDisasterCardDialog(context, newUser);
    } else {
      _showPendingVerificationSlipDialog(context, newUser);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.criticalRed,
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  void _showCitizenDisasterCardDialog(BuildContext context, UserModel user) {
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
            Icon(Icons.badge, color: AppColors.verifiedGreen, size: 24),
            SizedBox(width: 8),
            Text('Digital Citizen Disaster Card', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.darkSurfaceCard],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.verifiedGreen.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('RESQAI CITIZEN ID', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold, color: Colors.white70)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.verifiedGreen.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: Text(user.bloodGroup, style: const TextStyle(color: AppColors.verifiedGreen, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Citizen ID: ${user.citizenId}', style: const TextStyle(fontSize: 12, color: AppColors.primaryLight, fontWeight: FontWeight.w600)),
                  const Divider(color: Colors.white24, height: 16),
                  Row(
                    children: [
                      const Icon(Icons.contact_emergency, color: AppColors.criticalRed, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Emergency SOS Contact:\n${user.emergencyContactName} • ${user.emergencyContactPhone}',
                          style: const TextStyle(fontSize: 11, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('District / Locality: ${user.badgeOrJurisdiction}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                  Text('Special Assistance: ${user.specialAssistance}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your Citizen ID is active and linked to 1-Tap SOS. In case of emergency, your emergency contact will be notified automatically with your GPS coordinates.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.verifiedGreen),
            child: const Text('Enter Citizen Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.of(ctx).pop();
              _navigateToDashboard(user.role);
            },
          ),
        ],
      ),
    );
  }

  void _showPendingVerificationSlipDialog(BuildContext context, UserModel user) {
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
            Icon(Icons.hourglass_top, color: AppColors.warningAmber, size: 24),
            SizedBox(width: 8),
            Text('Application Submitted for Verification', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warningAmber.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('APPLICANT: ${user.role.title.toUpperCase()}', style: const TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold, color: AppColors.warningAmber)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.warningAmber.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: const Text('PENDING APPROVAL', style: TextStyle(color: AppColors.warningAmber, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(user.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Application Ref: ${user.citizenId}', style: const TextStyle(fontSize: 12, color: AppColors.primaryLight, fontWeight: FontWeight.w600)),
                  Text('Organization / Affiliation: ${user.organization ?? user.badgeOrJurisdiction}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                  Text('Credentials Provided: ${user.regNumber ?? "Verified via OTP"}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                  const Divider(color: Colors.white24, height: 16),
                  const Text(
                    'Administrative Governance Policy (Part 4-D):\nYour account credentials are now queued in the DDMA Administrative Verification Register. You currently have read-only access to disaster alerts and public shelters. Privileged actions (dispatching rescue, funding approvals) will unlock once approved by an official administrator.',
                    style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Proceed to Restricted Console', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.of(ctx).pop();
              _navigateToDashboard(user.role);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider);

    return Dialog(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ResQAI Multi-Role Access & Identity Portal',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          currentUser == null 
                              ? 'Persistent login, multi-role registration, and DDMA authorization'
                              : 'Signed in as ${currentUser.name} (${currentUser.role.title})',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  if (currentUser != null && currentUser.role == UserRole.admin)
                    IconButton(
                      icon: const Icon(Icons.admin_panel_settings, color: Colors.purpleAccent),
                      tooltip: 'Open DDMA Verification Queue',
                      onPressed: () => AdminVerificationModal.show(context),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Active Session Info if already logged in
              if (currentUser != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          currentUser.name.isNotEmpty ? currentUser.name[0].toUpperCase() : 'U',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(currentUser.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: currentUser.verificationStatus == 'APPROVED' 
                                        ? AppColors.verifiedGreen.withOpacity(0.2) 
                                        : AppColors.warningAmber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    currentUser.verificationStatus,
                                    style: TextStyle(
                                      color: currentUser.verificationStatus == 'APPROVED' ? AppColors.verifiedGreen : AppColors.warningAmber,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text('Role: ${currentUser.role.title} • ID: ${currentUser.citizenId}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.criticalRed,
                          side: const BorderSide(color: AppColors.criticalRed),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        icon: const Icon(Icons.logout, size: 14),
                        label: const Text('Logout', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          ref.read(authProvider.notifier).logout();
                          ref.read(activeRoleProvider.notifier).state = UserRole.citizen;
                          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.primaryBlue,
                              content: Text('✓ Successfully logged out. Session ended.'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Tab Bar
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primaryLight,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(icon: Icon(Icons.bolt, size: 16), text: '1-Click Presets'),
                  Tab(icon: Icon(Icons.login, size: 16), text: 'Sign In'),
                  Tab(icon: Icon(Icons.how_to_reg, size: 16), text: 'Register Account'),
                ],
              ),
              const SizedBox(height: 16),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildQuickRolePresets(),
                    _buildManualLoginForm(),
                    _buildRegistrationForm(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickRolePresets() {
    final accounts = AuthNotifier.demoAccounts;

    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.infoBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.infoBlue.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.infoBlue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pre-verified demonstration accounts for instant testing of all platform roles:',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        ...accounts.map((user) {
          IconData icon;
          Color roleColor;

          switch (user.role) {
            case UserRole.citizen:
              icon = Icons.person;
              roleColor = AppColors.verifiedGreen;
              break;
            case UserRole.volunteer:
              icon = Icons.handshake;
              roleColor = Colors.teal;
              break;
            case UserRole.fieldResponder:
              icon = Icons.local_hospital;
              roleColor = AppColors.primaryLight;
              break;
            case UserRole.rescueTeam:
              icon = Icons.fire_truck;
              roleColor = Colors.deepOrange;
              break;
            case UserRole.doctor:
              icon = Icons.medical_services;
              roleColor = Colors.cyan;
              break;
            case UserRole.ngoLead:
              icon = Icons.volunteer_activism;
              roleColor = Colors.orange;
              break;
            case UserRole.govtOfficial:
              icon = Icons.account_balance;
              roleColor = AppColors.primaryLight;
              break;
            case UserRole.incidentCommander:
              icon = Icons.military_tech;
              roleColor = AppColors.criticalRed;
              break;
            case UserRole.admin:
              icon = Icons.admin_panel_settings;
              roleColor = Colors.purpleAccent;
              break;
            default:
              icon = Icons.badge;
              roleColor = AppColors.primary;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            color: AppColors.darkSurfaceCard,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: roleColor.withOpacity(0.2),
                child: Icon(icon, color: roleColor, size: 20),
              ),
              title: Row(
                children: [
                  Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: roleColor.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                    child: Text(user.role.title, style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              subtitle: Text(
                'ID: ${user.citizenId} • ${user.badgeOrJurisdiction}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: roleColor.withOpacity(0.85),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: () => _loginAsPreset(user),
                child: const Text('Login', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildManualLoginForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Select Your Account Role:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<UserRole>(
                value: _selectedRole,
                isExpanded: true,
                items: UserRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text('${role.title} — ${role.description}', style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          const Text('Email or Government ID:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.email, size: 18),
              hintText: 'e.g. officer@ndrf.gov.in or user@citizen.org',
            ),
          ),
          const SizedBox(height: 14),

          const Text('Password:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock, size: 18),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, size: 18),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.login, color: Colors.white),
            label: const Text('Sign In & Restore Persistent Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: _submitManualLogin,
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm() {
    final isPrivileged = _regRole != UserRole.citizen;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Role Selection (Part 4-A)
          const Text('Account Category *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<UserRole>(
                value: _regRole,
                isExpanded: true,
                items: [
                  UserRole.citizen,
                  UserRole.volunteer,
                  UserRole.ngoLead,
                  UserRole.govtOfficial,
                  UserRole.doctor,
                  UserRole.rescueTeam,
                ].map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text('${role.title} (${role.name})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _regRole = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Security Notice for Privileged roles vs Citizen
          if (isPrivileged)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warningAmber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warningAmber.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_clock, color: AppColors.warningAmber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Privileged Account Protocol (Part 4-D): Registering as ${_regRole.title} requires verification of credentials by DDMA/State Admin. Your account will start in PENDING VERIFICATION status until reviewed.',
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.verifiedGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.verifiedGreen.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.verifiedGreen, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Citizen registration includes instant OTP mobile verification and mandatory Emergency SOS contact linking.',
                      style: TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Full Name
          const Text('Full Name *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TextField(
            controller: _regNameController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person, size: 18),
              hintText: 'e.g. Amit Kumar / Dr. Rajesh Verma',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),

          // Phone Number + OTP Verification Row (Part 4-B)
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mobile Phone Number *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _regPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.phone, size: 18),
                        hintText: '+91 98765 43210',
                        isDense: true,
                        suffixIcon: _otpVerified 
                            ? const Icon(Icons.verified, color: AppColors.verifiedGreen, size: 18)
                            : null,
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
                    const Text('OTP Verification:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _otpVerified ? AppColors.verifiedGreen : AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                      onPressed: _otpVerified ? null : _sendOtp,
                      child: Text(
                        _otpVerified ? '✓ Verified' : (_otpSent ? 'Resend OTP' : 'Send OTP'),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // OTP Code Entry if sent and not yet verified
          if (_otpSent && !_otpVerified) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _otpInputController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Enter 4-digit SMS OTP (Demo: 8492)',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.verifiedGreen),
                    onPressed: _verifyOtp,
                    child: const Text('Verify Code', style: TextStyle(fontSize: 11, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Email & Blood Group
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Email Address:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _regEmailController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email, size: 18),
                        hintText: 'user@example.com',
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Blood Group:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurfaceCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedBloodGroup,
                          isExpanded: true,
                          items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'].map((bg) {
                            return DropdownMenuItem(value: bg, child: Text(bg, style: const TextStyle(fontSize: 12)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedBloodGroup = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // EMERGENCY CONTACT SECTION (MANDATORY REQUIREMENT - PART 4-B)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.criticalRed.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.contact_emergency, color: AppColors.criticalRed, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Emergency Contact Details (Strictly Distinct from Self) *',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.criticalRed),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _regEmergencyContactNameController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.people_outline, size: 18),
                    hintText: 'Emergency Contact Person (e.g. Spouse / Mother / Brother)',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _regEmergencyContactPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.phone_in_talk, size: 18),
                    hintText: 'Emergency Contact Phone (e.g. +91 98765 00112)',
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // State, District, Locality (Part 4-B)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('State *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _regStateController,
                      decoration: const InputDecoration(hintText: 'Delhi', isDense: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('District *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _regDistrictController,
                      decoration: const InputDecoration(hintText: 'East Delhi', isDense: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Locality / Ward *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _regLocalityController,
                      decoration: const InputDecoration(hintText: 'Ward 4', isDense: true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Preferred Language & Notification Preferences
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Preferred Language:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurfaceCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLanguage,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'hi', child: Text('हिन्दी (Hindi)', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'bn', child: Text('বাংলা (Bengali)', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'ta', child: Text('தமிழ் (Tamil)', style: TextStyle(fontSize: 12))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedLanguage = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Alert Notification Mode:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurfaceCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedNotifPref,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'ALL_ALERTS_SMS', child: Text('All Alerts + SMS', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'CRITICAL_ONLY', child: Text('Critical Hazard Only', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'IN_APP_ONLY', child: Text('In-App Only', style: TextStyle(fontSize: 12))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedNotifPref = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Accessibility & Assistance Preferences (Part 4-B)
          const Text('Accessibility / Special Assistance Preference:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedAssistance,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'NONE', child: Text('None (Standard Able-Bodied Citizen)', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'ELDERLY', child: Text('Elderly Citizen (60+ years, requires evacuation assistance)', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'MOBILITY', child: Text('Mobility Impairment / Wheelchair Required', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'CHRONIC_CARE', child: Text('Chronic Medical Care / Oxygen Dependent', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'INFANT', child: Text('Infant / Small Children in Household', style: TextStyle(fontSize: 12))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedAssistance = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Location Permission Toggle (Part 4-B)
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable Location Access for Real-Time Hazard Alerts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            subtitle: const Text('Used only to notify you of nearby flash floods, gas leaks, and storm alerts within 5km.', style: TextStyle(fontSize: 10, color: Colors.grey)),
            value: _grantLocationPermission,
            onChanged: (val) => setState(() => _grantLocationPermission = val),
          ),
          const SizedBox(height: 10),

          // ROLE-SPECIFIC PRIVILEGED CREDENTIAL FIELDS (Part 4-D)
          if (isPrivileged) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_regRole.title} Verification Credentials *',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                  ),
                  const SizedBox(height: 8),

                  if (_regRole == UserRole.ngoLead) ...[
                    TextField(
                      controller: _orgNameController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.business, size: 18),
                        hintText: 'NGO / Relief Organization Name (e.g. Red Cross Society)',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _regNumberController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.assignment, size: 18),
                        hintText: 'NGO DARPAN / Registration ID (e.g. DARPAN-DL-2024-00192)',
                        isDense: true,
                      ),
                    ),
                  ] else if (_regRole == UserRole.govtOfficial) ...[
                    TextField(
                      controller: _departmentController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.account_balance, size: 18),
                        hintText: 'Government Department (e.g. DDMA East Delhi / Revenue Dept)',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _regNumberController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.badge, size: 18),
                        hintText: 'Official Govt Employee / Officer ID (e.g. GOV-DL-IAS-2018)',
                        isDense: true,
                      ),
                    ),
                  ] else if (_regRole == UserRole.doctor) ...[
                    TextField(
                      controller: _orgNameController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.local_hospital, size: 18),
                        hintText: 'Hospital / Institution (e.g. AIIMS Trauma Center)',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _regNumberController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.medical_information, size: 18),
                        hintText: 'Medical Council Reg No (e.g. MCI-2019-84210)',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _specializationController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.healing, size: 18),
                        hintText: 'Specialization (e.g. Trauma Surgery, Emergency Triage)',
                        isDense: true,
                      ),
                    ),
                  ] else if (_regRole == UserRole.rescueTeam) ...[
                    TextField(
                      controller: _departmentController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.military_tech, size: 18),
                        hintText: 'Battalion / Unit (e.g. 8th Battalion NDRF)',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _regNumberController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.confirmation_number, size: 18),
                        hintText: 'Commander Service ID (e.g. NDRF-CMD-044)',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _equipmentController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.fire_truck, size: 18),
                        hintText: 'Fleet / Equipment (e.g. 4 Inflatable Motorboats, Drone Sensors)',
                        isDense: true,
                      ),
                    ),
                  ] else if (_regRole == UserRole.volunteer) ...[
                    const Text('Volunteer Skills & Practical Help Offered:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: ['First Aid Certified', 'Flood Rescue', 'Food Distribution', 'Vehicle Transport', 'Shelter Care', 'Language Translator'].map((skill) {
                        final isSelected = _selectedVolunteerSkills.contains(skill);
                        return FilterChip(
                          label: Text(skill, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedVolunteerSkills.add(skill);
                              } else {
                                _selectedVolunteerSkills.remove(skill);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isPrivileged ? AppColors.warningAmber : AppColors.verifiedGreen,
              foregroundColor: isPrivileged ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: Icon(isPrivileged ? Icons.how_to_reg : Icons.badge),
            label: Text(
              isPrivileged ? 'Submit Application for DDMA Verification' : 'Generate Citizen ID & Enter Portal',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: _submitRegistration,
          ),
        ],
      ),
    );
  }
}
