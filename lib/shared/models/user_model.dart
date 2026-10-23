import '../../core/constants/app_constants.dart';

class UserModel {
  final String id;
  final String citizenId;
  final String name;
  final String email;
  final UserRole role;
  final String badgeOrJurisdiction;
  final String phoneMasked;
  final String? phoneRaw;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String bloodGroup;
  final bool isVerified;
  final String verificationStatus; // 'APPROVED', 'PENDING', 'REJECTED'
  final String? organization;
  final String? regNumber; // DARPAN, Medical ID, Govt Employee ID, FCRA
  final String? serviceArea;
  final List<String> skills;
  final String availability; // 'AVAILABLE', 'ON_DUTY', 'OFFLINE'
  final String preferredLanguage; // 'en', 'hi', 'bn', 'ta', etc.
  final String notificationPreferences; // 'ALL_ALERTS_SMS', 'CRITICAL_ONLY', 'IN_APP_ONLY'
  final String specialAssistance; // 'NONE', 'ELDERLY', 'MOBILITY', 'CHRONIC_CARE', 'INFANT'
  final String stateName;
  final String district;
  final bool isLocationPermissionGranted;
  final DateTime loggedInAt;

  const UserModel({
    required this.id,
    required this.citizenId,
    required this.name,
    required this.email,
    required this.role,
    required this.badgeOrJurisdiction,
    required this.phoneMasked,
    this.phoneRaw,
    this.emergencyContactName = 'Next of Kin / Family',
    this.emergencyContactPhone = '+91 98765 00112',
    this.bloodGroup = 'O+',
    this.isVerified = true,
    this.verificationStatus = 'APPROVED',
    this.organization,
    this.regNumber,
    this.serviceArea,
    this.skills = const [],
    this.availability = 'AVAILABLE',
    this.preferredLanguage = 'en',
    this.notificationPreferences = 'ALL_ALERTS_SMS',
    this.specialAssistance = 'NONE',
    this.stateName = 'Delhi',
    this.district = 'East Delhi',
    this.isLocationPermissionGranted = true,
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
    String? phoneRaw,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? bloodGroup,
    bool? isVerified,
    String? verificationStatus,
    String? organization,
    String? regNumber,
    String? serviceArea,
    List<String>? skills,
    String? availability,
    String? preferredLanguage,
    String? notificationPreferences,
    String? specialAssistance,
    String? stateName,
    String? district,
    bool? isLocationPermissionGranted,
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
      phoneRaw: phoneRaw ?? this.phoneRaw,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      isVerified: isVerified ?? this.isVerified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      organization: organization ?? this.organization,
      regNumber: regNumber ?? this.regNumber,
      serviceArea: serviceArea ?? this.serviceArea,
      skills: skills ?? this.skills,
      availability: availability ?? this.availability,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
      specialAssistance: specialAssistance ?? this.specialAssistance,
      stateName: stateName ?? this.stateName,
      district: district ?? this.district,
      isLocationPermissionGranted: isLocationPermissionGranted ?? this.isLocationPermissionGranted,
      loggedInAt: loggedInAt ?? this.loggedInAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'citizenId': citizenId,
      'name': name,
      'email': email,
      'role': role.name,
      'badgeOrJurisdiction': badgeOrJurisdiction,
      'phoneMasked': phoneMasked,
      'phoneRaw': phoneRaw,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'bloodGroup': bloodGroup,
      'isVerified': isVerified,
      'verificationStatus': verificationStatus,
      'organization': organization,
      'regNumber': regNumber,
      'serviceArea': serviceArea,
      'skills': skills,
      'availability': availability,
      'preferredLanguage': preferredLanguage,
      'notificationPreferences': notificationPreferences,
      'specialAssistance': specialAssistance,
      'stateName': stateName,
      'district': district,
      'isLocationPermissionGranted': isLocationPermissionGranted,
      'loggedInAt': loggedInAt.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    UserRole parsedRole = UserRole.citizen;
    for (final r in UserRole.values) {
      if (r.name == json['role'] || r.title == json['role']) {
        parsedRole = r;
        break;
      }
    }

    return UserModel(
      id: json['id'] as String? ?? 'USR-UNKNOWN',
      citizenId: json['citizenId'] as String? ?? 'RQ-CIT-2026-0000',
      name: json['name'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      role: parsedRole,
      badgeOrJurisdiction: json['badgeOrJurisdiction'] as String? ?? '',
      phoneMasked: json['phoneMasked'] as String? ?? '+91 98*** **000',
      phoneRaw: json['phoneRaw'] as String?,
      emergencyContactName: json['emergencyContactName'] as String? ?? 'Family',
      emergencyContactPhone: json['emergencyContactPhone'] as String? ?? '+91 98765 00112',
      bloodGroup: json['bloodGroup'] as String? ?? 'O+',
      isVerified: json['isVerified'] as bool? ?? true,
      verificationStatus: json['verificationStatus'] as String? ?? 'APPROVED',
      organization: json['organization'] as String?,
      regNumber: json['regNumber'] as String?,
      serviceArea: json['serviceArea'] as String?,
      skills: (json['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      availability: json['availability'] as String? ?? 'AVAILABLE',
      preferredLanguage: json['preferredLanguage'] as String? ?? 'en',
      notificationPreferences: json['notificationPreferences'] as String? ?? 'ALL_ALERTS_SMS',
      specialAssistance: json['specialAssistance'] as String? ?? 'NONE',
      stateName: json['stateName'] as String? ?? 'Delhi',
      district: json['district'] as String? ?? 'East Delhi',
      isLocationPermissionGranted: json['isLocationPermissionGranted'] as bool? ?? true,
      loggedInAt: json['loggedInAt'] != null 
          ? DateTime.tryParse(json['loggedInAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
