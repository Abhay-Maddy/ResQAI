import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/incident_repository.dart';
import '../../shared/models/user_model.dart';
import '../auth/auth_screen.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const UserProfileScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _smsAlerts = true;
  bool _pushAlerts = true;
  bool _whatsappAlerts = true;
  bool _locationPermission = true;
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 4),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.emergencyRed, size: 22),
            SizedBox(width: 8),
            Text('Sign Out of ResQAI'),
          ],
        ),
        content: const Text(
          'Are you sure you wish to end your authenticated session? You can sign back in anytime to access your role workspace.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
              ref.read(activeRoleProvider.notifier).state = UserRole.citizen;
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.primaryBlue,
                  content: Text('✓ Successfully signed out. Session terminated.'),
                ),
              );
            },
            child: const Text('Confirm Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return AppShell(
      currentRoute: AppRoutes.citizenProfile,
      title: 'Account & Profile',
      breadcrumbs: const ['Account', 'Profile Settings'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: currentUser == null
                ? _buildUnauthenticatedCard(context, isDark, isMobile)
                : _buildProfileContent(context, currentUser, isDark, isMobile),
          ),
        ),
      ),
    );
  }

  Widget _buildUnauthenticatedCard(BuildContext context, bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 36),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline, size: 48, color: AppColors.primaryBlue),
          ),
          const SizedBox(height: 18),
          Text(
            'Not Signed In',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in or create an account to access specialized disaster response workflows, emergency telemetry, and role workspaces.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen(isRegisterMode: false)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                ),
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen(isRegisterMode: true)),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                ),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, UserModel user, bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Profile Header Card
        Container(
          padding: EdgeInsets.all(isMobile ? 18 : 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: isMobile ? 26 : 32,
                    backgroundColor: AppColors.primaryBlue,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              user.name,
                              style: TextStyle(
                                fontSize: isMobile ? 18 : 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : AppColors.deepNavy,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (user.isVerified ? AppColors.successGreen : AppColors.warningOrange).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    user.isVerified ? Icons.verified : Icons.hourglass_top,
                                    size: 13,
                                    color: user.isVerified ? AppColors.successGreen : AppColors.warningOrange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    user.verificationStatus,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: user.isVerified ? AppColors.successGreen : AppColors.warningOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _buildPill(user.role.title, AppColors.primaryBlue),
                            _buildPill('ID: ${user.citizenId}', Colors.grey),
                            if (user.district.isNotEmpty) _buildPill('📍 ${user.district}', AppColors.successGreen),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 2. Navigation Tabs
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primaryBlue,
            unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
            indicatorColor: AppColors.primaryBlue,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.person, size: 16), text: 'My Profile'),
              Tab(icon: Icon(Icons.settings, size: 16), text: 'Settings'),
              Tab(icon: Icon(Icons.notifications, size: 16), text: 'Alert Preferences'),
              Tab(icon: Icon(Icons.security, size: 16), text: 'Security & Session'),
              Tab(icon: Icon(Icons.help_outline, size: 16), text: 'Help & Helplines'),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 3. Tab Views Container
        SizedBox(
          height: 480,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMyProfileTab(user, isDark),
              _buildSettingsTab(user, isDark),
              _buildNotificationsTab(isDark),
              _buildSecurityTab(user, isDark),
              _buildHelpTab(isDark),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 4. Log Out Action
        OutlinedButton.icon(
          onPressed: _handleLogout,
          icon: const Icon(Icons.logout, color: AppColors.emergencyRed, size: 18),
          label: const Text('Sign Out of Account', style: TextStyle(color: AppColors.emergencyRed, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.emergencyRed),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _editProfileDialog(UserModel user) {
    final nameCtrl = TextEditingController(text: user.name);
    final contactNameCtrl = TextEditingController(text: user.emergencyContactName);
    final contactPhoneCtrl = TextEditingController(text: user.emergencyContactPhone);
    final districtCtrl = TextEditingController(text: user.district);
    final bloodGroup = user.bloodGroup;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: AppColors.primaryBlue, size: 24),
            SizedBox(width: 8),
            Text('Update Profile Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Full Name *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(controller: nameCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
              const SizedBox(height: 10),
              const Text('Emergency Contact Person *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(controller: contactNameCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
              const SizedBox(height: 10),
              const Text('Emergency Contact Phone (Mandatory) *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(controller: contactPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
              const SizedBox(height: 10),
              const Text('District / Territory', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(controller: districtCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final trimmedName = nameCtrl.text.trim();
              final trimmedPhone = contactPhoneCtrl.text.trim();
              if (trimmedName.isEmpty || trimmedPhone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(backgroundColor: AppColors.emergencyRed, content: Text('Please fill all mandatory fields.')),
                );
                return;
              }

              final updatedUser = user.copyWith(
                name: trimmedName,
                emergencyContactName: contactNameCtrl.text.trim(),
                emergencyContactPhone: trimmedPhone,
                district: districtCtrl.text.trim(),
                bloodGroup: bloodGroup,
              );

              ref.read(authProvider.notifier).loginAs(updatedUser);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.successGreen,
                  content: Text('✓ Profile updated successfully. Session preserved.'),
                ),
              );
            },
            child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMyProfileTab(UserModel user, bool isDark) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Personal & Jurisdiction Record', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Divider(height: 20),
            _buildDetailRow('Full Name', user.name),
            _buildDetailRow('Email Address', user.email),
            _buildDetailRow('Primary Phone (Masked)', user.phoneMasked),
            _buildDetailRow('Mandatory Emergency Contact', '${user.emergencyContactName} (${user.emergencyContactPhone})'),
            _buildDetailRow('Blood Group', user.bloodGroup),
            _buildDetailRow('Assigned Role', user.role.title),
            _buildDetailRow('Jurisdiction / Area', user.badgeOrJurisdiction.isNotEmpty ? user.badgeOrJurisdiction : user.district),
            if (user.organization != null) _buildDetailRow('Affiliated Organization', user.organization!),
            if (user.regNumber != null) _buildDetailRow('Statutory Reg / MCI / DARPAN ID', user.regNumber!),
            if (user.skills.isNotEmpty) _buildDetailRow('Certified Skills', user.skills.join(', ')),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Update Profile Details', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _editProfileDialog(user),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab(UserModel user, bool isDark) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Application Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Divider(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.language, color: AppColors.primaryBlue),
              title: const Text('Interface Language', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: const Text('Bilingual English & Hindi disaster prompts'),
              trailing: DropdownButton<String>(
                value: _selectedLanguage,
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'hi', child: Text('हिंदी (Hindi)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedLanguage = val);
                },
              ),
            ),
            const Divider(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.gps_fixed, color: AppColors.primaryBlue),
              title: const Text('Live GPS Telemetry', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: const Text('Provides precision coordinates during emergency SOS dispatch'),
              value: _locationPermission,
              activeColor: AppColors.primaryBlue,
              onChanged: (val) => setState(() => _locationPermission = val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsTab(bool isDark) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Life-Safety Alert Channels', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            const Text('Statutory broadcast channels from NDMA, IMD, and District Control Rooms.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.priority_high, color: AppColors.emergencyRed),
              title: const Text('Critical Emergency Push Alerts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: const Text('Immediate evacuation warnings (Bypasses DND)'),
              value: _pushAlerts,
              activeColor: AppColors.primaryBlue,
              onChanged: (val) => setState(() => _pushAlerts = val),
            ),
            const Divider(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.sms, color: AppColors.primaryBlue),
              title: const Text('SMS Early Warnings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: const Text('Fallback SMS broadcast during network congestion'),
              value: _smsAlerts,
              activeColor: AppColors.primaryBlue,
              onChanged: (val) => setState(() => _smsAlerts = val),
            ),
            const Divider(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.chat, color: AppColors.successGreen),
              title: const Text('WhatsApp Disaster Bulletins', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: const Text('Daily flood maps, relief camp locations, and water levels'),
              value: _whatsappAlerts,
              activeColor: AppColors.successGreen,
              onChanged: (val) => setState(() => _whatsappAlerts = val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTab(UserModel user, bool isDark) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Security, Storage & Session Integrity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Divider(height: 20),
            _buildDetailRow('Session Persistence', 'Active & Verified (Local Secure Storage)'),
            _buildDetailRow('User Identifier (UID)', user.id),
            _buildDetailRow('Citizen ID / Officer Badge', user.citizenId),
            _buildDetailRow('Last Session Timestamp', user.loggedInAt.toIso8601String()),
            _buildDetailRow('DPDP Act 2023 Compliance', 'Phone masked in public feeds • Telemetry protected'),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpTab(bool isDark) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('24x7 Statutory Emergency Helplines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            const Text('Immediate toll-free government hotlines for life-safety emergencies.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(height: 20),
            _buildHelplineRow('112', 'National Emergency Response System (All Emergencies)', AppColors.emergencyRed),
            _buildHelplineRow('1077', 'District Disaster Control Room (East Delhi & NCR)', AppColors.primaryBlue),
            _buildHelplineRow('1070', 'State Disaster Management Authority (SDMA)', AppColors.primaryBlue),
            _buildHelplineRow('108', 'Free Emergency Medical Ambulance Service', AppColors.successGreen),
            _buildHelplineRow('101', 'Fire & Rescue Emergency Service', AppColors.warningOrange),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHelplineRow(String number, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phone, size: 14, color: color),
                const SizedBox(width: 6),
                Text(number, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
