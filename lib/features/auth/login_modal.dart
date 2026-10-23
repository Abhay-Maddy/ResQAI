import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/incident_repository.dart';
import '../../shared/models/user_model.dart';
import '../../app.dart';

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
  final _emailController = TextEditingController(text: 'rajesh.ndrf@gov.in');
  final _passwordController = TextEditingController(text: '••••••••');
  UserRole _selectedRole = UserRole.fieldResponder;
  bool _obscurePassword = true;

  // Citizen / User Registration fields
  final _regNameController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regEmergencyContactNameController = TextEditingController();
  final _regEmergencyContactPhoneController = TextEditingController();
  final _regDistrictController = TextEditingController(text: 'Yamuna Riverbank Ward 4');
  String _selectedBloodGroup = 'O+';
  final UserRole _regRole = UserRole.citizen;

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
    _regEmergencyContactNameController.dispose();
    _regEmergencyContactPhoneController.dispose();
    _regDistrictController.dispose();
    super.dispose();
  }

  void _loginAsPreset(UserModel user) {
    ref.read(authProvider.notifier).loginAs(user);
    ref.read(activeRoleProvider.notifier).state = user.role;
    if (user.role == UserRole.citizen) {
      ref.read(currentTabProvider.notifier).state = MainNavigationTab.citizenSos;
    } else if (user.role == UserRole.fieldResponder) {
      ref.read(currentTabProvider.notifier).state = MainNavigationTab.tacticalMap;
    } else {
      ref.read(currentTabProvider.notifier).state = MainNavigationTab.commandCenter;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.verifiedGreen,
        content: Text('Logged in successfully as ${user.name} (${user.role.title})'),
      ),
    );
  }

  void _submitManualLogin() {
    final customUser = UserModel(
      id: 'USR-CUSTOM-${DateTime.now().millisecondsSinceEpoch % 1000}',
      citizenId: 'RQ-AUTH-${DateTime.now().millisecondsSinceEpoch % 9000 + 1000}',
      name: _emailController.text.split('@').first,
      email: _emailController.text,
      role: _selectedRole,
      badgeOrJurisdiction: 'Verified ${_selectedRole.title} Session',
      phoneMasked: '+91 98*** **000',
      emergencyContactName: 'Disaster Control Desk',
      emergencyContactPhone: '112 / 1078',
      bloodGroup: 'B+',
      isVerified: true,
      loggedInAt: DateTime.now(),
    );

    ref.read(authProvider.notifier).loginAs(customUser);
    ref.read(activeRoleProvider.notifier).state = _selectedRole;
    if (_selectedRole == UserRole.citizen) {
      ref.read(currentTabProvider.notifier).state = MainNavigationTab.citizenSos;
    } else if (_selectedRole == UserRole.fieldResponder) {
      ref.read(currentTabProvider.notifier).state = MainNavigationTab.tacticalMap;
    } else {
      ref.read(currentTabProvider.notifier).state = MainNavigationTab.commandCenter;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.verifiedGreen,
        content: Text('Welcome back, ${customUser.name}! Role: ${_selectedRole.title}'),
      ),
    );
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
    if (emergencyPhone.isEmpty) {
      _showError('CRITICAL: Emergency Contact Number is mandatory for Citizen ID');
      return;
    }

    final newCitizenId = 'RQ-CIT-2026-${DateTime.now().millisecondsSinceEpoch % 9000 + 1000}';
    final newUser = UserModel(
      id: 'USR-${DateTime.now().millisecondsSinceEpoch % 1000}',
      citizenId: newCitizenId,
      name: name,
      email: _regEmailController.text.trim().isEmpty ? '$name@citizen.resqai.org'.toLowerCase().replaceAll(' ', '.') : _regEmailController.text.trim(),
      role: _regRole,
      badgeOrJurisdiction: _regDistrictController.text.trim().isEmpty ? 'Registered Citizen' : _regDistrictController.text.trim(),
      phoneMasked: phone.length >= 4 
          ? '+91 *** ***${phone.substring(phone.length - 4)}'
          : '+91 98*** **123',
      emergencyContactName: emergencyName.isEmpty ? 'Next of Kin' : emergencyName,
      emergencyContactPhone: emergencyPhone,
      bloodGroup: _selectedBloodGroup,
      isVerified: true,
      loggedInAt: DateTime.now(),
    );

    ref.read(authProvider.notifier).loginAs(newUser);
    ref.read(activeRoleProvider.notifier).state = _regRole;
    if (_regRole == UserRole.citizen) {
      ref.read(currentTabProvider.notifier).state = MainNavigationTab.citizenSos;
    } else if (_regRole == UserRole.fieldResponder) {
      ref.read(currentTabProvider.notifier).state = MainNavigationTab.tacticalMap;
    } else {
      ref.read(currentTabProvider.notifier).state = MainNavigationTab.commandCenter;
    }

    Navigator.of(context).pop();

    // Show Digital Citizen Emergency ID Badge
    _showCitizenDisasterCardDialog(context, newUser);
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
          side: const BorderSide(color: AppColors.primary),
        ),
        title: const Row(
          children: [
            Icon(Icons.badge, color: AppColors.primaryLight, size: 24),
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
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.darkSurfaceCard],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryLight.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('RESQAI DISASTER CARD', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold, color: Colors.white70)),
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
                  Text('District / Sector: ${user.badgeOrJurisdiction}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your Citizen ID is linked to 1-Tap SOS. In case of emergency, your emergency contact will be notified automatically with your GPS coordinates.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Enter Dashboard', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ResQAI Multi-Role Access Portal',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          'Sign in or generate an official Citizen Disaster Card with emergency contact',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Tab Bar
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primaryLight,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(icon: Icon(Icons.bolt, size: 16), text: '1-Click Role Login'),
                  Tab(icon: Icon(Icons.login, size: 16), text: 'Sign In Form'),
                  Tab(icon: Icon(Icons.badge, size: 16), text: 'Create Citizen ID'),
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
                  'InnoTech Exhibition Presets: Tap any role below to authenticate instantly and load its custom-governed dashboard.',
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
            case UserRole.fieldResponder:
              icon = Icons.local_hospital;
              roleColor = AppColors.primaryLight;
              break;
            case UserRole.incidentCommander:
              icon = Icons.military_tech;
              roleColor = AppColors.criticalRed;
              break;
            case UserRole.ngoLead:
              icon = Icons.volunteer_activism;
              roleColor = Colors.orange;
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
                'ID: ${user.citizenId} • SOS Contact: ${user.emergencyContactPhone}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
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
          const Text('Select Your Role:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
              hintText: 'e.g. officer@ndrf.gov.in',
            ),
          ),
          const SizedBox(height: 14),

          const Text('Password or Auth Token:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
            label: const Text('Sign In & Open Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: _submitManualLogin,
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.criticalRed.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.criticalRed.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppColors.criticalRed, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Requirement: Citizen ID creation requires a verified Emergency Contact Number to facilitate family notification during 1-Tap SOS dispatch.',
                    style: TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          const Text('Full Name *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TextField(
            controller: _regNameController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person, size: 18),
              hintText: 'e.g. Amit Kumar',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Primary Phone *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _regPhoneController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.phone, size: 18),
                        hintText: '+91 98765 43210',
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
          const SizedBox(height: 10),

          // EMERGENCY CONTACT SECTION (MANDATORY REQUIREMENT)
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
                      'Emergency Contact Details (Mandatory) *',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.criticalRed),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _regEmergencyContactNameController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.people_outline, size: 18),
                    hintText: 'Emergency Contact Person (e.g. Mother / Spouse / Brother)',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _regEmergencyContactPhoneController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.phone_in_talk, size: 18),
                    hintText: 'Emergency Phone Number (e.g. +91 98765 00112)',
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          const Text('District / Area / Ward:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TextField(
            controller: _regDistrictController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.location_on, size: 18),
              hintText: 'e.g. Yamuna Khadar Sector 4, East Delhi',
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.verifiedGreen,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.badge, color: Colors.white),
            label: const Text('Generate Citizen ID & Enter Portal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: _submitRegistration,
          ),
        ],
      ),
    );
  }
}
