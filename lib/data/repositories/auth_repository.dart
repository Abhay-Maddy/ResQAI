import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/user_model.dart';
import '../services/storage_service.dart';

class AuthNotifier extends StateNotifier<UserModel?> {
  AuthNotifier() : super(_loadInitialUser());

  static UserModel? _loadInitialUser() {
    try {
      final savedJson = StorageService.getString(StorageService.keyCurrentUser);
      if (savedJson != null && savedJson.isNotEmpty) {
        final decoded = jsonDecode(savedJson) as Map<String, dynamic>;
        return UserModel.fromJson(decoded);
      }
    } catch (_) {}
    return defaultCitizen;
  }

  static final UserModel defaultCitizen = UserModel(
    id: 'USR-CITIZEN-01',
    citizenId: 'RQ-CIT-2026-1042',
    name: 'Rohan Verma',
    email: 'rohan.verma@example.com',
    role: UserRole.citizen,
    badgeOrJurisdiction: 'Yamuna Khadar Ward 4, Delhi',
    phoneMasked: '+91 98*** **412',
    emergencyContactName: 'Kavita Verma (Mother)',
    emergencyContactPhone: '+91 98765 00112',
    bloodGroup: 'B+',
    isVerified: true,
    verificationStatus: 'APPROVED',
    loggedInAt: DateTime.now(),
  );

  static final List<UserModel> demoAccounts = [
    UserModel(
      id: 'USR-CITIZEN-01',
      citizenId: 'RQ-CIT-2026-1042',
      name: 'Rohan Verma',
      email: 'rohan.verma@example.com',
      role: UserRole.citizen,
      badgeOrJurisdiction: 'Yamuna Lowland Ward 4, Delhi',
      phoneMasked: '+91 98*** **412',
      emergencyContactName: 'Kavita Verma (Mother)',
      emergencyContactPhone: '+91 98765 00112',
      bloodGroup: 'B+',
      isVerified: true,
      verificationStatus: 'APPROVED',
      loggedInAt: DateTime.now(),
    ),
    UserModel(
      id: 'USR-VOL-01',
      citizenId: 'RQ-VOL-2026-081',
      name: 'Pooja Sharma',
      email: 'pooja.volunteer@resqai.org',
      role: UserRole.volunteer,
      badgeOrJurisdiction: 'Delhi Civil Defense Volunteer',
      phoneMasked: '+91 98*** **334',
      emergencyContactName: 'Ramesh Sharma (Father)',
      emergencyContactPhone: '+91 98111 22334',
      bloodGroup: 'O+',
      isVerified: true,
      verificationStatus: 'APPROVED',
      skills: ['First Aid Certified', 'Flood Rescue', 'Food Distribution'],
      availability: 'AVAILABLE',
      serviceArea: 'Yamuna Riverbank & East Delhi',
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
      verificationStatus: 'APPROVED',
      organization: 'Indian Red Cross Society',
      regNumber: 'DARPAN-DL-2024-00192',
      serviceArea: 'National Capital Region',
      loggedInAt: DateTime.now(),
    ),
    UserModel(
      id: 'USR-DOCTOR-01',
      citizenId: 'RQ-MED-2026-014',
      name: 'Dr. Arvind Saxena, MD',
      email: 'arvind.saxena@aiims.edu',
      role: UserRole.doctor,
      badgeOrJurisdiction: 'AIIMS Emergency & Trauma Center',
      phoneMasked: '+91 97*** **555',
      emergencyContactName: 'Dr. Meera Saxena (Spouse)',
      emergencyContactPhone: '+91 97123 45678',
      bloodGroup: 'A+',
      isVerified: true,
      verificationStatus: 'APPROVED',
      organization: 'AIIMS Trauma Response Corps',
      regNumber: 'DMC-REG-2018-84210',
      skills: ['Emergency Triage', 'Trauma Surgery', 'Pediatric Life Support'],
      availability: 'ON_DUTY',
      serviceArea: 'Delhi Central & North',
      loggedInAt: DateTime.now(),
    ),
    UserModel(
      id: 'USR-RESCUE-01',
      citizenId: 'RQ-RESCUE-2026-008',
      name: 'Commander Vikram Rathore',
      email: 'vikram.rathore@ndrf.gov.in',
      role: UserRole.rescueTeam,
      badgeOrJurisdiction: '8th Battalion NDRF Flood Rescue Unit',
      phoneMasked: '+91 94*** **777',
      emergencyContactName: 'NDRF Control Ops Desk',
      emergencyContactPhone: '+91 11 2436 3260',
      bloodGroup: 'B+',
      isVerified: true,
      verificationStatus: 'APPROVED',
      organization: 'National Disaster Response Force (NDRF)',
      regNumber: 'NDRF-BAT8-CMD-044',
      skills: ['Deep Water Inflatable Boats', 'Collapsed Structure Search', 'Night Vision Ops'],
      availability: 'AVAILABLE',
      serviceArea: 'Yamuna Flood Plains & Hindon Basin',
      loggedInAt: DateTime.now(),
    ),
    UserModel(
      id: 'USR-COMMANDER-01',
      citizenId: 'RQ-GOV-2026-001',
      name: 'Dr. Sunita Rao (IAS)',
      email: 'sunita.rao@delhi.gov.in',
      role: UserRole.govtOfficial,
      badgeOrJurisdiction: 'District Disaster Magistrate & DM East Delhi',
      phoneMasked: '+91 98*** **001',
      emergencyContactName: 'Control Room Officer in Charge',
      emergencyContactPhone: '+91 11 2345 6789',
      bloodGroup: 'A+',
      isVerified: true,
      verificationStatus: 'APPROVED',
      organization: 'Delhi Disaster Management Authority (DDMA)',
      regNumber: 'IAS-DL-2014-0891',
      serviceArea: 'District East Delhi',
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
      verificationStatus: 'APPROVED',
      organization: 'State Disaster Management Authority (SDMA)',
      serviceArea: 'All Jurisdictions',
      loggedInAt: DateTime.now(),
    ),
  ];

  void loginAs(UserModel user) {
    state = user;
    _persistUser(user);
  }

  void logout() {
    state = null;
    StorageService.remove(StorageService.keyCurrentUser);
  }

  void updateProfile(UserModel updated) {
    state = updated;
    _persistUser(updated);
  }

  void _persistUser(UserModel user) {
    try {
      StorageService.setString(StorageService.keyCurrentUser, jsonEncode(user.toJson()));
    } catch (_) {}
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  return AuthNotifier();
});

// Pending accounts awaiting administrator authorization (FR-2, PART 4)
class PendingApprovalsNotifier extends StateNotifier<List<UserModel>> {
  PendingApprovalsNotifier() : super(_initialPending());

  static List<UserModel> _initialPending() {
    return [
      UserModel(
        id: 'USR-PENDING-01',
        citizenId: 'RQ-NGO-REQ-901',
        name: 'Goonj Disaster Relief Cell',
        email: 'relief@goonj.org',
        role: UserRole.ngoLead,
        badgeOrJurisdiction: 'Goonj National Network',
        phoneMasked: '+91 98*** **111',
        emergencyContactName: 'Operations Lead',
        emergencyContactPhone: '+91 11 2697 2351',
        bloodGroup: 'O+',
        isVerified: false,
        verificationStatus: 'PENDING',
        organization: 'Goonj Relief Trust',
        regNumber: 'DARPAN-DL-2020-00812',
        serviceArea: 'Delhi, UP, Bihar Floods',
        loggedInAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      UserModel(
        id: 'USR-PENDING-02',
        citizenId: 'RQ-MED-REQ-902',
        name: 'Dr. Priya Nambiar',
        email: 'priya.nambiar@delhihealth.gov.in',
        role: UserRole.doctor,
        badgeOrJurisdiction: 'Safdarjung Hospital Trauma Unit',
        phoneMasked: '+91 99*** **882',
        emergencyContactName: 'Hospital Superintendent',
        emergencyContactPhone: '+91 11 2616 5060',
        bloodGroup: 'B+',
        isVerified: false,
        verificationStatus: 'PENDING',
        organization: 'Safdarjung Trauma Relief Team',
        regNumber: 'MCI-REG-2019-33901',
        skills: ['Orthopedic Trauma', 'Triage', 'Emergency Medicine'],
        serviceArea: 'Delhi South & East',
        loggedInAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];
  }

  void addPending(UserModel user) {
    state = [user, ...state];
  }

  void approveUser(String userId) {
    state = state.map((u) {
      if (u.id == userId) {
        return u.copyWith(isVerified: true, verificationStatus: 'APPROVED');
      }
      return u;
    }).toList();
  }

  void rejectUser(String userId) {
    state = state.map((u) {
      if (u.id == userId) {
        return u.copyWith(isVerified: false, verificationStatus: 'REJECTED');
      }
      return u;
    }).toList();
  }
}

final pendingApprovalsProvider = StateNotifierProvider<PendingApprovalsNotifier, List<UserModel>>((ref) {
  return PendingApprovalsNotifier();
});

// Admin Master User & Role Management (Admin Full Control)
class SystemUsersNotifier extends StateNotifier<List<UserModel>> {
  SystemUsersNotifier() : super(List.from(AuthNotifier.demoAccounts));

  void createUserPosition({
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    String? department,
    String? designation,
    String? jurisdiction,
    String? regNumber,
  }) {
    final newUser = UserModel(
      id: 'USR-${role.name.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      citizenId: 'RQ-${role.name.toUpperCase().substring(0, 3)}-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
      name: name,
      email: email,
      phoneMasked: phone.length > 5 ? '${phone.substring(0, 3)}*** **${phone.substring(phone.length - 3)}' : phone,
      phoneRaw: phone,
      role: role,
      badgeOrJurisdiction: designation ?? department ?? jurisdiction ?? role.title,
      district: jurisdiction ?? 'District HQ',
      stateName: 'Delhi NCT',
      isVerified: true,
      verificationStatus: 'APPROVED',
      organization: department ?? 'Government Operations',
      regNumber: regNumber,
      loggedInAt: DateTime.now(),
    );

    state = [newUser, ...state];
  }

  void updateUserRole(
    String userId, 
    UserRole newRole, {
    String? designation,
    String? department,
    String? jurisdiction,
    String? status,
  }) {
    state = state.map((u) {
      if (u.id == userId || u.citizenId == userId) {
        return u.copyWith(
          role: newRole,
          badgeOrJurisdiction: designation ?? department ?? jurisdiction ?? u.badgeOrJurisdiction,
          organization: department ?? u.organization,
          district: jurisdiction ?? u.district,
          verificationStatus: status ?? 'APPROVED',
          isVerified: status != 'REJECTED',
        );
      }
      return u;
    }).toList();
  }

  void removeUser(String userId) {
    state = state.where((u) => u.id != userId && u.citizenId != userId).toList();
  }
}

final systemUsersProvider = StateNotifierProvider<SystemUsersNotifier, List<UserModel>>((ref) {
  return SystemUsersNotifier();
});
