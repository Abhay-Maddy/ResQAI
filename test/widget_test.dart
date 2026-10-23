import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resqai/app.dart';
import 'package:resqai/core/constants/app_constants.dart';
import 'package:resqai/core/utils/i18n.dart';
import 'package:resqai/shared/models/incident_model.dart';
import 'package:resqai/shared/models/user_model.dart';
import 'package:resqai/data/repositories/incident_repository.dart';
import 'package:resqai/data/repositories/auth_repository.dart';
import 'package:resqai/features/volunteer/volunteer_portal_screen.dart';
import 'package:resqai/features/medical/medical_doctor_portal_screen.dart';
import 'package:resqai/features/rescue/rescue_team_operations_screen.dart';

void main() {
  group('ResQAI Unit & Logic Tests', () {
    test('Incident priority calculation unit test with multiple factors', () {
      final highRiskScore = IncidentModel.calculatePriority(
        category: IncidentCategory.flood,
        casualties: 2,
        trappedCount: 10,
        hasVulnerable: true,
        waterLevelMeters: 2.5,
        isNightTime: true,
      );

      // Verify high priority score logic (clamp 10-100)
      expect(highRiskScore, greaterThanOrEqualTo(85.0));

      final lowRiskScore = IncidentModel.calculatePriority(
        category: IncidentCategory.foodWater,
        casualties: 0,
        trappedCount: 0,
        hasVulnerable: false,
        waterLevelMeters: 0.0,
        isNightTime: false,
      );

      expect(lowRiskScore, lessThan(highRiskScore));
      expect(lowRiskScore, greaterThanOrEqualTo(10.0));
    });

    test('Incident status lifecycle transitions test', () {
      final incident = IncidentModel(
        id: 'RQ-999',
        title: 'Test Incident',
        descriptionOriginal: 'Test Description',
        descriptionTranslated: 'Test Description Translated',
        category: IncidentCategory.flood,
        latitude: 28.61,
        longitude: 77.20,
        address: 'Test Address',
        status: IncidentStatus.received,
        priorityScore: 75.0,
        priorityExplanation: 'Test explanation',
        vulnerableGroups: ['Elderly'],
        reporterPhoneMasked: '+91 98*** **111',
        reportedAt: DateTime.now(),
        source: 'CITIZEN_WEB',
      );

      expect(incident.status, equals(IncidentStatus.received));

      final updatedIncident = incident.copyWith(status: IncidentStatus.verified);
      expect(updatedIncident.status, equals(IncidentStatus.verified));
      expect(updatedIncident.id, equals('RQ-999'));
    });

    test('Bilingual i18n dictionary translations test', () {
      expect(I18nService.text('sos_button', 'en'), equals('EMERGENCY SOS'));
      expect(I18nService.text('sos_button', 'hi'), equals('आपातकालीन एसओएस (SOS)'));
      expect(I18nService.text('command_center', 'hi'), equals('कमांड डैशबोर्ड'));
    });

    test('IncidentNotifier Riverpod state mutations test', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialIncidents = container.read(incidentsProvider);
      expect(initialIncidents.isNotEmpty, isTrue);

      final initialCount = initialIncidents.length;
      final testIncident = IncidentModel(
        id: 'RQ-TEST-1',
        title: 'New Riverpod Test Incident',
        descriptionOriginal: 'Original',
        descriptionTranslated: 'Translated',
        category: IncidentCategory.fire,
        latitude: 28.5,
        longitude: 77.3,
        address: 'Noida Sector 62',
        status: IncidentStatus.received,
        priorityScore: 60.0,
        priorityExplanation: 'Auto-assessed',
        vulnerableGroups: [],
        reporterPhoneMasked: '+91 99*** **999',
        reportedAt: DateTime.now(),
        source: 'WEB_TEST',
      );

      container.read(incidentsProvider.notifier).addIncident(testIncident);
      final updatedList = container.read(incidentsProvider);
      expect(updatedList.length, equals(initialCount + 1));
      expect(updatedList.first.id, equals('RQ-TEST-1'));

      // Test status update
      container.read(incidentsProvider.notifier).updateStatus('RQ-TEST-1', IncidentStatus.helpAssigned);
      final verifiedIncident = container.read(incidentsProvider).firstWhere((i) => i.id == 'RQ-TEST-1');
      expect(verifiedIncident.status, equals(IncidentStatus.helpAssigned));
    });

    test('UserModel citizen registration with mandatory emergency contact test', () {
      final citizen = UserModel(
        id: 'USR-99',
        citizenId: 'RQ-CIT-2026-9999',
        name: 'Aarav Sharma',
        email: 'aarav@example.com',
        role: UserRole.citizen,
        badgeOrJurisdiction: 'Yamuna East Ward 3',
        phoneMasked: '+91 98*** **333',
        emergencyContactName: 'Pooja Sharma (Sister)',
        emergencyContactPhone: '+91 98111 22334',
        bloodGroup: 'O+',
        loggedInAt: DateTime.now(),
      );

      expect(citizen.role, equals(UserRole.citizen));
      expect(citizen.emergencyContactPhone, equals('+91 98111 22334'));
      expect(citizen.bloodGroup, equals('O+'));
      expect(citizen.citizenId.startsWith('RQ-CIT-'), isTrue);
    });

    test('UserModel JSON serialization & persistent login roundtrip test', () {
      final doctor = UserModel(
        id: 'USR-DOC-TEST',
        citizenId: 'RQ-MED-2026-9901',
        name: 'Dr. Test Physician',
        email: 'doc.test@aiims.gov.in',
        role: UserRole.doctor,
        badgeOrJurisdiction: 'AIIMS Emergency',
        phoneMasked: '+91 98*** **888',
        emergencyContactName: 'Hospital Supt',
        emergencyContactPhone: '+91 11 2616 5000',
        bloodGroup: 'A+',
        isVerified: false,
        verificationStatus: 'PENDING',
        organization: 'AIIMS Trauma Relief',
        regNumber: 'MCI-88992',
        serviceArea: 'Delhi East',
        skills: ['Triage', 'Emergency Medicine'],
        preferredLanguage: 'hi',
        notificationPreferences: 'CRITICAL_ONLY',
        specialAssistance: 'NONE',
        stateName: 'Delhi',
        district: 'East Delhi',
        isLocationPermissionGranted: true,
        loggedInAt: DateTime(2026, 10, 23, 12, 0),
      );

      final json = doctor.toJson();
      final restored = UserModel.fromJson(json);

      expect(restored.id, equals(doctor.id));
      expect(restored.name, equals(doctor.name));
      expect(restored.role, equals(UserRole.doctor));
      expect(restored.verificationStatus, equals('PENDING'));
      expect(restored.isVerified, isFalse);
      expect(restored.regNumber, equals('MCI-88992'));
      expect(restored.preferredLanguage, equals('hi'));
      expect(restored.notificationPreferences, equals('CRITICAL_ONLY'));
    });

    test('PendingApprovalsNotifier privileged role authorization workflow test', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final applicant = UserModel(
        id: 'USR-APPLICANT-01',
        citizenId: 'RQ-NGO-2026-TEST',
        name: 'Relief Foundation NGO',
        email: 'ngo@relief.org',
        role: UserRole.ngoLead,
        badgeOrJurisdiction: 'Yamuna Flood Basin',
        phoneMasked: '+91 99*** **777',
        isVerified: false,
        verificationStatus: 'PENDING',
        organization: 'Relief Foundation',
        regNumber: 'DARPAN-DL-2024-999',
        loggedInAt: DateTime.now(),
      );

      // Add to pending queue
      container.read(pendingApprovalsProvider.notifier).addPending(applicant);
      final queue = container.read(pendingApprovalsProvider);
      expect(queue.any((u) => u.id == 'USR-APPLICANT-01'), isTrue);

      // Verify pending status
      final queuedApplicant = queue.firstWhere((u) => u.id == 'USR-APPLICANT-01');
      expect(queuedApplicant.verificationStatus, equals('PENDING'));
      expect(queuedApplicant.isVerified, isFalse);

      // Administrator authorizes the account
      container.read(pendingApprovalsProvider.notifier).approveUser('USR-APPLICANT-01');
      final approvedApplicant = container.read(pendingApprovalsProvider).firstWhere((u) => u.id == 'USR-APPLICANT-01');
      expect(approvedApplicant.verificationStatus, equals('APPROVED'));
      expect(approvedApplicant.isVerified, isTrue);
    });

    test('Disaster Damage & Relief Claim Model test with economic loss and property claims', () {
      final damageClaim = IncidentModel(
        id: 'RQ-CASE-2026-1001',
        title: 'Severe Inundation & Crop Damage at Yamuna Ward 4',
        descriptionOriginal: 'Ground floor submerged in 1.8m flood water. Lost standing paddy crops and poultry.',
        descriptionTranslated: 'Ground floor submerged in 1.8m flood water. Lost standing paddy crops and poultry.',
        category: IncidentCategory.flood,
        latitude: 28.6139,
        longitude: 77.2090,
        address: 'Yamuna Khadar Sector 4, East Delhi',
        status: IncidentStatus.received,
        priorityScore: 85.0,
        priorityExplanation: 'High economic loss and family displacement',
        source: 'DAMAGE_REPORT',
        reporterPhoneMasked: '+91 98*** **412',
        reportedAt: DateTime.now(),
        affectedProperties: ['Home / Housing', 'Agricultural Land & Standing Crops', 'Livestock & Cattle'],
        estimatedLossInr: 250000.0,
        householdMembersCount: 6,
        urgentMedicalNeeds: 'Insulin for elderly grandfather',
        reliefRequirements: ['Drinking Water', 'Food / Dry Rations', 'Waterproof Tarpaulins'],
        preferredFollowUp: 'SMS Notification',
      );

      expect(damageClaim.source, equals('DAMAGE_REPORT'));
      expect(damageClaim.estimatedLossInr, equals(250000.0));
      expect(damageClaim.householdMembersCount, equals(6));
      expect(damageClaim.affectedProperties.length, equals(3));
      expect(damageClaim.reliefRequirements.contains('Waterproof Tarpaulins'), isTrue);
    });

    test('Traceable Incident Verification Lifecycle & Government Decision Decision Reason logging test', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final incident = IncidentModel(
        id: 'RQ-VERIFY-TEST',
        title: 'Reported Riverbank Breach',
        descriptionOriginal: 'Water entering settlement.',
        descriptionTranslated: 'Water entering settlement.',
        category: IncidentCategory.flood,
        latitude: 28.62,
        longitude: 77.21,
        address: 'Mayur Vihar Phase 1 lowlands',
        status: IncidentStatus.received,
        priorityScore: 70.0,
        priorityExplanation: 'Initial citizen report',
        reporterPhoneMasked: '+91 99*** **123',
        reportedAt: DateTime.now(),
      );

      container.read(incidentsProvider.notifier).addIncident(incident);

      // Official Magistrate Review
      container.read(incidentsProvider.notifier).recordVerificationDecision(
        'RQ-VERIFY-TEST',
        newStatus: IncidentStatus.verified,
        reviewerId: 'GOV-IAS-2026',
        reviewerName: 'Dr. Sunita Rao (IAS)',
        reviewerRole: 'District Disaster Magistrate',
        notes: 'Ground drone survey confirmed breach at 28.62 N. Immediate deployment ordered.',
        reason: 'Physical breach confirmed by SDRF reconnaissance unit.',
        departmentAssigned: 'NDRF 8th Battalion Flood Unit',
      );

      final verified = container.read(incidentsProvider).firstWhere((i) => i.id == 'RQ-VERIFY-TEST');
      expect(verified.status, equals(IncidentStatus.verified));
      expect(verified.reviewerName, equals('Dr. Sunita Rao (IAS)'));
      expect(verified.departmentAssigned, equals('NDRF 8th Battalion Flood Unit'));
      expect(verified.verificationHistory.isNotEmpty, isTrue);
      expect(verified.verificationHistory.first.contains('SDRF reconnaissance unit'), isTrue);

      // Reopening and Escalation by Citizen
      container.read(incidentsProvider.notifier).reopenIncident(
        'RQ-VERIFY-TEST',
        'Water level rose by 1 foot overnight; need additional rescue boats',
        'Rohan Verma',
      );

      final reopened = container.read(incidentsProvider).firstWhere((i) => i.id == 'RQ-VERIFY-TEST');
      expect(reopened.status, equals(IncidentStatus.underReview));
      expect(reopened.escalatedTo, equals('District Disaster Magistrate Review Desk'));
      expect(reopened.verificationHistory.first.contains('Reopened by Rohan Verma'), isTrue);
    });

    test('Phase 4 Volunteer Portal task acceptance and completion lifecycle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialTasks = container.read(volunteerTasksProvider);
      expect(initialTasks.isNotEmpty, isTrue);

      final firstTask = initialTasks.first;
      expect(firstTask.isAccepted, isFalse);
      expect(firstTask.isCompleted, isFalse);

      // Volunteer accepts task
      container.read(volunteerTasksProvider.notifier).acceptTask(firstTask.id);
      var updated = container.read(volunteerTasksProvider).firstWhere((t) => t.id == firstTask.id);
      expect(updated.isAccepted, isTrue);

      // Volunteer marks complete with delivery proof
      container.read(volunteerTasksProvider.notifier).completeTask(
        firstTask.id,
        'Delivered 250 food packets to Camp Ward 4; verified by camp incharge.',
      );
      updated = container.read(volunteerTasksProvider).firstWhere((t) => t.id == firstTask.id);
      expect(updated.isCompleted, isTrue);
      expect(updated.deliveryProofNote, contains('Delivered 250 food packets'));
    });

    test('Phase 4 Medical Doctor triage and hospital referral workflow', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialCases = container.read(medicalCasesProvider);
      expect(initialCases.isNotEmpty, isTrue);

      final urgentCase = initialCases.first;
      expect(urgentCase.status, equals('PENDING_TRIAGE'));

      // Doctor accepts case
      container.read(medicalCasesProvider.notifier).acceptCase(urgentCase.id);
      var updated = container.read(medicalCasesProvider).firstWhere((c) => c.id == urgentCase.id);
      expect(updated.isAccepted, isTrue);
      expect(updated.status, equals('ATTENDING'));

      // Doctor provides clinical notes and hospital referral
      container.read(medicalCasesProvider.notifier).updateTreatmentOutcome(
        urgentCase.id,
        'REFERRED',
        'Stabilized wound; transferred for tertiary surgical intervention.',
        referredHospital: 'AIIMS Trauma Center & Emergency',
      );
      updated = container.read(medicalCasesProvider).firstWhere((c) => c.id == urgentCase.id);
      expect(updated.status, equals('REFERRED'));
      expect(updated.referredHospital, equals('AIIMS Trauma Center & Emergency'));
      expect(updated.attendingDoctorNotes, contains('Stabilized wound'));
    });

    test('Phase 4 Rescue Team 4-stage mission dispatch progression', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final missions = container.read(rescueMissionsProvider);
      expect(missions.isNotEmpty, isTrue);

      final testMission = missions.firstWhere((m) => m.id == 'MISSION-NDRF-02');
      expect(testMission.stage, equals(RescueMissionStage.dispatched));

      // Advance to EN ROUTE
      container.read(rescueMissionsProvider.notifier).advanceStage(testMission.id, RescueMissionStage.enRoute);
      var updated = container.read(rescueMissionsProvider).firstWhere((m) => m.id == testMission.id);
      expect(updated.stage, equals(RescueMissionStage.enRoute));

      // Advance to ON SCENE
      container.read(rescueMissionsProvider.notifier).advanceStage(testMission.id, RescueMissionStage.onScene);
      updated = container.read(rescueMissionsProvider).firstWhere((m) => m.id == testMission.id);
      expect(updated.stage, equals(RescueMissionStage.onScene));

      // Resolve mission with evacuated count and safe shelter
      container.read(rescueMissionsProvider.notifier).advanceStage(
        testMission.id,
        RescueMissionStage.resolved,
        evacuated: 5,
        shelter: 'Kashmere Gate Safe Camp',
        notes: 'Wheelchair patients lifted with safety harness into rescue boat.',
      );
      updated = container.read(rescueMissionsProvider).firstWhere((m) => m.id == testMission.id);
      expect(updated.stage, equals(RescueMissionStage.resolved));
      expect(updated.victimsEvacuated, equals(5));
      expect(updated.evacuationShelter, equals('Kashmere Gate Safe Camp'));
    });
  });

  group('ResQAI Widget Smoke Tests', () {
    testWidgets('ResQAI App smoke and brand title render', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: ResQAIApp(),
        ),
      );

      // Verify App Name is present in app bar
      expect(find.text(AppConstants.appName), findsOneWidget);
    });
  });
}
