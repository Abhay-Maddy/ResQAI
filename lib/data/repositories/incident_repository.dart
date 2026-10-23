import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/incident_model.dart';
import '../../shared/models/alert_model.dart';
import '../../shared/models/shelter_model.dart';
import '../../shared/models/volunteer_model.dart';
import '../../shared/models/rumor_model.dart';
import '../services/demo_data_service.dart';

// User and Role State
final activeRoleProvider = StateProvider<UserRole>((ref) => UserRole.incidentCommander);

// Incidents State Notifier
class IncidentsNotifier extends StateNotifier<List<IncidentModel>> {
  IncidentsNotifier() : super(DemoDataService.getInitialIncidents());

  void addIncident(IncidentModel incident) {
    state = [incident, ...state];
  }

  void updateStatus(String id, IncidentStatus newStatus, {String? team}) {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(
          status: newStatus,
          assignedTeam: team ?? item.assignedTeam,
        );
      }
      return item;
    }).toList();
  }

  void confirmDuplicate(String duplicateId, String masterId) {
    state = state.map((item) {
      if (item.id == duplicateId) {
        return item.copyWith(
          duplicateOfId: masterId,
          duplicateConfirmedByHuman: true,
          status: IncidentStatus.verified,
        );
      }
      return item;
    }).toList();
  }

  void rejectDuplicate(String incidentId) {
    state = state.map((item) {
      if (item.id == incidentId) {
        return item.copyWith(
          isPossibleDuplicate: false,
          duplicateOfId: null,
          duplicateConfidence: 0.0,
        );
      }
      return item;
    }).toList();
  }

  void updateWhatIfSimulation(String id, Map<String, dynamic> simData, double adjustedScore) {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(
          whatIfSimulation: simData,
          priorityScore: adjustedScore,
          priorityExplanation: 'Simulated What-If adjustment applied: ${simData['notes']}',
        );
      }
      return item;
    }).toList();
  }
}

final incidentsProvider = StateNotifierProvider<IncidentsNotifier, List<IncidentModel>>((ref) {
  return IncidentsNotifier();
});

final selectedIncidentProvider = StateProvider<IncidentModel?>((ref) {
  final list = ref.watch(incidentsProvider);
  return list.isNotEmpty ? list.first : null;
});

// Official Alerts Provider
final alertsProvider = StateProvider<List<AlertModel>>((ref) {
  return DemoDataService.getOfficialAlerts();
});

// Shelters Provider
class SheltersNotifier extends StateNotifier<List<ShelterModel>> {
  SheltersNotifier() : super(DemoDataService.getShelters());

  void updateOccupancy(String id, int newOccupancy) {
    state = state.map((shelter) {
      if (shelter.id == id) {
        return ShelterModel(
          id: shelter.id,
          name: shelter.name,
          address: shelter.address,
          latitude: shelter.latitude,
          longitude: shelter.longitude,
          totalCapacity: shelter.totalCapacity,
          occupiedBeds: newOccupancy.clamp(0, shelter.totalCapacity),
          waterLitersStock: shelter.waterLitersStock,
          foodMealsStock: shelter.foodMealsStock,
          hasMedicalUnit: shelter.hasMedicalUnit,
          lastUpdated: DateTime.now(),
          isCapacityStale: false,
        );
      }
      return shelter;
    }).toList();
  }
}

final sheltersProvider = StateNotifierProvider<SheltersNotifier, List<ShelterModel>>((ref) {
  return SheltersNotifier();
});

// Volunteers Provider
class VolunteersNotifier extends StateNotifier<List<VolunteerModel>> {
  VolunteersNotifier() : super(DemoDataService.getVolunteers());

  void assignVolunteer(String volunteerId, String incidentId) {
    state = state.map((v) {
      if (v.id == volunteerId) {
        return VolunteerModel(
          id: v.id,
          name: v.name,
          phoneMasked: v.phoneMasked,
          skills: v.skills,
          latitude: v.latitude,
          longitude: v.longitude,
          district: v.district,
          isAvailable: false,
          isVerified: v.isVerified,
          matchedIncidentId: incidentId,
        );
      }
      return v;
    }).toList();
  }
}

final volunteersProvider = StateNotifierProvider<VolunteersNotifier, List<VolunteerModel>>((ref) {
  return VolunteersNotifier();
});

// Rumors Provider
class RumorsNotifier extends StateNotifier<List<RumorModel>> {
  RumorsNotifier() : super(DemoDataService.getRumors());

  void updateRumorStatus(String id, RumorStatus newStatus, String factCheckNote) {
    state = state.map((r) {
      if (r.id == id) {
        return RumorModel(
          id: r.id,
          claimText: r.claimText,
          sourceChannel: r.sourceChannel,
          reportedRegion: r.reportedRegion,
          reportsCount: r.reportsCount,
          status: newStatus,
          officialFactCheck: factCheckNote,
          firstReported: r.firstReported,
          lastUpdated: DateTime.now(),
        );
      }
      return r;
    }).toList();
  }
}

final rumorsProvider = StateNotifierProvider<RumorsNotifier, List<RumorModel>>((ref) {
  return RumorsNotifier();
});

// AI Feedback Loop Audit Record
class AiFeedbackRecord {
  final String targetId;
  final String featureName; // PriorityScore, DuplicateCandidate, FloodRisk
  final String rating; // 'CORRECT', 'INCORRECT', 'UNCERTAIN'
  final String? comments;
  final DateTime recordedAt;

  AiFeedbackRecord({
    required this.targetId,
    required this.featureName,
    required this.rating,
    this.comments,
    required this.recordedAt,
  });
}

class AiFeedbackNotifier extends StateNotifier<List<AiFeedbackRecord>> {
  AiFeedbackNotifier() : super([]);

  void recordFeedback(String targetId, String feature, String rating, {String? comments}) {
    state = [
      AiFeedbackRecord(
        targetId: targetId,
        featureName: feature,
        rating: rating,
        comments: comments,
        recordedAt: DateTime.now(),
      ),
      ...state,
    ];
  }
}

final aiFeedbackProvider = StateNotifierProvider<AiFeedbackNotifier, List<AiFeedbackRecord>>((ref) {
  return AiFeedbackNotifier();
});

// Offline Draft Queue
final offlineDraftsProvider = StateProvider<List<IncidentModel>>((ref) => []);
