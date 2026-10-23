import '../../core/constants/app_constants.dart';

class IncidentModel {
  final String id;
  final String title;
  final String descriptionOriginal;
  final String descriptionTranslated;
  final String originalLanguage;
  final IncidentCategory category;
  final double latitude;
  final double longitude;
  final String address;
  final bool isLocationApproximate;
  final IncidentStatus status;
  final double priorityScore;
  final String priorityExplanation;
  final List<String> vulnerableGroups; // Children, Elderly, Pregnant, Disability, Hospital
  final bool hasVoiceNote;
  final String? voiceNoteUrl;
  final String source; // CITIZEN_WEB, SMS_GATEWAY, WHATSAPP, 112_DISPATCH
  final String reporterPhoneMasked;
  final DateTime reportedAt;
  final String? assignedTeam;
  final bool isPossibleDuplicate;
  final String? duplicateOfId;
  final double duplicateConfidence;
  final bool duplicateConfirmedByHuman;
  final Map<String, dynamic>? whatIfSimulation;

  IncidentModel({
    required this.id,
    required this.title,
    required this.descriptionOriginal,
    required this.descriptionTranslated,
    this.originalLanguage = 'en',
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.isLocationApproximate = false,
    this.status = IncidentStatus.received,
    required this.priorityScore,
    required this.priorityExplanation,
    this.vulnerableGroups = const [],
    this.hasVoiceNote = false,
    this.voiceNoteUrl,
    this.source = 'CITIZEN_WEB',
    required this.reporterPhoneMasked,
    required this.reportedAt,
    this.assignedTeam,
    this.isPossibleDuplicate = false,
    this.duplicateOfId,
    this.duplicateConfidence = 0.0,
    this.duplicateConfirmedByHuman = false,
    this.whatIfSimulation,
  });

  IncidentModel copyWith({
    String? id,
    String? title,
    String? descriptionOriginal,
    String? descriptionTranslated,
    String? originalLanguage,
    IncidentCategory? category,
    double? latitude,
    double? longitude,
    String? address,
    bool? isLocationApproximate,
    IncidentStatus? status,
    double? priorityScore,
    String? priorityExplanation,
    List<String>? vulnerableGroups,
    bool? hasVoiceNote,
    String? voiceNoteUrl,
    String? source,
    String? reporterPhoneMasked,
    DateTime? reportedAt,
    String? assignedTeam,
    bool? isPossibleDuplicate,
    String? duplicateOfId,
    double? duplicateConfidence,
    bool? duplicateConfirmedByHuman,
    Map<String, dynamic>? whatIfSimulation,
  }) {
    return IncidentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      descriptionOriginal: descriptionOriginal ?? this.descriptionOriginal,
      descriptionTranslated: descriptionTranslated ?? this.descriptionTranslated,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      isLocationApproximate: isLocationApproximate ?? this.isLocationApproximate,
      status: status ?? this.status,
      priorityScore: priorityScore ?? this.priorityScore,
      priorityExplanation: priorityExplanation ?? this.priorityExplanation,
      vulnerableGroups: vulnerableGroups ?? this.vulnerableGroups,
      hasVoiceNote: hasVoiceNote ?? this.hasVoiceNote,
      voiceNoteUrl: voiceNoteUrl ?? this.voiceNoteUrl,
      source: source ?? this.source,
      reporterPhoneMasked: reporterPhoneMasked ?? this.reporterPhoneMasked,
      reportedAt: reportedAt ?? this.reportedAt,
      assignedTeam: assignedTeam ?? this.assignedTeam,
      isPossibleDuplicate: isPossibleDuplicate ?? this.isPossibleDuplicate,
      duplicateOfId: duplicateOfId ?? this.duplicateOfId,
      duplicateConfidence: duplicateConfidence ?? this.duplicateConfidence,
      duplicateConfirmedByHuman: duplicateConfirmedByHuman ?? this.duplicateConfirmedByHuman,
      whatIfSimulation: whatIfSimulation ?? this.whatIfSimulation,
    );
  }

  // Calculate explainable priority score
  static double calculatePriority({
    required IncidentCategory category,
    required int casualties,
    required int trappedCount,
    required bool hasVulnerable,
    required double waterLevelMeters,
    required bool isNightTime,
  }) {
    double score = category.baseWeight * 30.0;
    score += (casualties * 15.0).clamp(0, 30);
    score += (trappedCount * 5.0).clamp(0, 20);
    if (hasVulnerable) score += 15.0;
    if (waterLevelMeters > 1.5) score += 10.0;
    if (isNightTime) score += 5.0;
    return score.clamp(10.0, 100.0);
  }
}
