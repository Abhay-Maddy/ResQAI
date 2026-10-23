import '../../core/constants/app_constants.dart';

class UserModel {
  final String id;
  final String citizenId;
  final String name;
  final String email;
  final UserRole role;
  final String badgeOrJurisdiction;
  final String phoneMasked;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String bloodGroup;
  final bool isVerified;
  final DateTime loggedInAt;

  const UserModel({
    required this.id,
    required this.citizenId,
    required this.name,
    required this.email,
    required this.role,
    required this.badgeOrJurisdiction,
    required this.phoneMasked,
    this.emergencyContactName = 'Next of Kin / Family',
    this.emergencyContactPhone = '+91 98765 00112',
    this.bloodGroup = 'O+',
    this.isVerified = true,
    required this.loggedInAt,
  });

  UserModel copyWith({
    String? id,
    String? citizenId,
    String? name,
    String? email,
    UserRole? role,
    String? badgeOrJurisdiction,
    String? phoneMasked,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? bloodGroup,
    bool? isVerified,
    DateTime? loggedInAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      citizenId: citizenId ?? this.citizenId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      badgeOrJurisdiction: badgeOrJurisdiction ?? this.badgeOrJurisdiction,
      phoneMasked: phoneMasked ?? this.phoneMasked,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      isVerified: isVerified ?? this.isVerified,
      loggedInAt: loggedInAt ?? this.loggedInAt,
    );
  }
}
