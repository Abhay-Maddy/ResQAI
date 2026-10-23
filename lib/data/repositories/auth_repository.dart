import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/user_model.dart';

class AuthNotifier extends StateNotifier<UserModel?> {
  AuthNotifier() : super(defaultCitizen);

  static final UserModel defaultCitizen = UserModel(
    id: 'USR-CITIZEN-01',
    citizenId: 'RQ-CIT-2026-1042',
    name: 'Rohan Verma',
    email: 'rohan.verma@example.com',
    role: UserRole.citizen,
    badgeOrJurisdiction: 'Yamuna Khadar Ward 4',
    phoneMasked: '+91 98*** **412',
    emergencyContactName: 'Kavita Verma (Mother)',
    emergencyContactPhone: '+91 98765 00112',
    bloodGroup: 'B+',
    isVerified: true,
    loggedInAt: DateTime.now(),
  );

  static final List<UserModel> demoAccounts = [
    UserModel(
      id: 'USR-CITIZEN-01',
      citizenId: 'RQ-CIT-2026-1042',
      name: 'Rohan Verma',
      email: 'rohan.verma@example.com',
      role: UserRole.citizen,
      badgeOrJurisdiction: 'Yamuna Lowland Citizen',
      phoneMasked: '+91 98*** **412',
      emergencyContactName: 'Kavita Verma (Mother)',
      emergencyContactPhone: '+91 98765 00112',
      bloodGroup: 'B+',
      isVerified: true,
      loggedInAt: DateTime.now(),
    ),
    UserModel(
      id: 'USR-RESPONDER-04',
      citizenId: 'RQ-RESP-2026-004',
      name: 'Inspector Rajesh Kumar',
      email: 'rajesh.ndrf@gov.in',
      role: UserRole.fieldResponder,
      badgeOrJurisdiction: 'NDRF Quick Response Team 4',
      phoneMasked: '+91 94*** **880',
      emergencyContactName: 'Sunita Kumar (Spouse)',
      emergencyContactPhone: '+91 94567 11223',
      bloodGroup: 'O+',
      isVerified: true,
      loggedInAt: DateTime.now(),
    ),
    UserModel(
      id: 'USR-COMMANDER-01',
      citizenId: 'RQ-CMD-2026-001',
      name: 'Dr. Sunita Rao (IAS)',
      email: 'sunita.rao@delhi.gov.in',
      role: UserRole.incidentCommander,
      badgeOrJurisdiction: 'District Disaster Magistrate',
      phoneMasked: '+91 98*** **001',
      emergencyContactName: 'Control Room Officer in Charge',
      emergencyContactPhone: '+91 11 2345 6789',
      bloodGroup: 'A+',
      isVerified: true,
      loggedInAt: DateTime.now(),
    ),
    UserModel(
      id: 'USR-NGO-03',
      citizenId: 'RQ-NGO-2026-033',
      name: 'Ananya Gupta',
      email: 'ananya@redcross.org',
      role: UserRole.ngoLead,
      badgeOrJurisdiction: 'Red Cross Relief Logistics',
      phoneMasked: '+91 99*** **331',
      emergencyContactName: 'Vikram Gupta (Brother)',
      emergencyContactPhone: '+91 99123 44556',
      bloodGroup: 'AB+',
      isVerified: true,
      loggedInAt: DateTime.now(),
    ),
    UserModel(
      id: 'USR-ADMIN-01',
      citizenId: 'RQ-ADM-2026-001',
      name: 'System SuperAdmin',
      email: 'admin@resqai.org',
      role: UserRole.admin,
      badgeOrJurisdiction: 'SDMA IT & Governance',
      phoneMasked: '+91 98*** **999',
      emergencyContactName: 'SDMA Emergency Desk',
      emergencyContactPhone: '112 / 1070',
      bloodGroup: 'O+',
      isVerified: true,
      loggedInAt: DateTime.now(),
    ),
  ];

  void loginAs(UserModel user) {
    state = user;
  }

  void logout() {
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  return AuthNotifier();
});
