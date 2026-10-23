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
  final TextEditingController _nameController = TextEditingController(text: 'Aarav Sharma');
  final TextEditingController _emailController = TextEditingController(text: 'citizen@resqai.org');
  final TextEditingController _phoneController = TextEditingController(text: '+91 98765 43210');
  final TextEditingController _passwordController = TextEditingController(text: 'password123');
  final TextEditingController _emergencyContactController = TextEditingController(text: '+91 98111 22233');
  final TextEditingController _districtController = TextEditingController(text: 'East Delhi');
  bool _obscurePassword = true;

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
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 20 : 32),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      _isRegister ? 'Join ResQAI Network' : 'Welcome to ResQAI',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppColors.deepNavy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      _isRegister
                          ? 'Select your role to access specialized disaster workflows'
                          : 'Sign in to access your role-based disaster command workspace',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Account Type / Role Selector
                  const Text('Account Type & Role *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<UserRole>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    items: UserRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedRole = v);
                    },
                  ),
                  const SizedBox(height: 16),

                  if (_isRegister) ...[
                    const Text('Full Name *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Emergency Contact Phone (Mandatory) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emergencyContactController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.contact_phone_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Text('Email Address *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),

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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _handleAuthSubmit,
                    child: Text(
                      _isRegister ? 'Complete Registration & Enter' : 'Sign In to Workspace',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Switch between Login and Register
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _isRegister = !_isRegister),
                      child: Text(
                        _isRegister ? 'Already registered? Sign In' : 'New user? Create an Account',
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

  void _handleAuthSubmit() {
    final newUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      citizenId: 'CIT-DEL-9921',
      name: _nameController.text.isNotEmpty ? _nameController.text : 'Aarav Sharma',
      email: _emailController.text,
      phoneMasked: '+91 98*** **210',
      phoneRaw: _phoneController.text,
      role: _selectedRole,
      badgeOrJurisdiction: _selectedRole.title,
      emergencyContactPhone: _emergencyContactController.text,
      district: _districtController.text,
      stateName: 'Delhi',
      isLocationPermissionGranted: true,
      loggedInAt: DateTime.now(),
    );

    // Save into state & storage
    ref.read(authProvider.notifier).loginAs(newUser);
    ref.read(activeRoleProvider.notifier).state = _selectedRole;

    // Navigate to role workspace
    _navigateToRoleWorkspace(_selectedRole);
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
