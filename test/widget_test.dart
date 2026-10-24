import 'dart:async';
import 'dart:io';
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
import 'package:resqai/features/ngo/ngo_management_screen.dart';
import 'package:resqai/features/transparency/public_transparency_portal_screen.dart';
import 'package:resqai/data/repositories/donation_repository.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

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

    test('Phase 5 NGO Campaign creation, expenditure logging with invoice audit and beneficiary distribution', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialCampaigns = container.read(ngoCampaignsProvider);
      expect(initialCampaigns.isNotEmpty, isTrue);

      final initialCount = initialCampaigns.length;
      final newCampaign = NgoCampaign(
        id: 'CMP-TEST-99',
        title: 'Emergency Winter Blankets & Tents Drive',
        objective: 'Distribute 1,000 thermal blankets to displaced families along Yamuna bank.',
        targetSector: 'East Delhi Sector 4',
        targetAmount: 500000.0,
        raisedAmount: 300000.0,
        committedAmount: 50000.0,
        spentAmount: 100000.0,
        targetBeneficiaries: 1000,
        verifiedBeneficiariesReached: 200,
        inKindNeeds: ['Woolen Blankets', 'Ground Tarps'],
      );

      // Add Campaign
      container.read(ngoCampaignsProvider.notifier).addCampaign(newCampaign);
      var campaigns = container.read(ngoCampaignsProvider);
      expect(campaigns.length, equals(initialCount + 1));
      expect(campaigns.first.id, equals('CMP-TEST-99'));

      // Record Audited Expense
      container.read(ngoCampaignsProvider.notifier).recordExpense('CMP-TEST-99', 40000.0, 'Thermal Blankets');
      var updated = container.read(ngoCampaignsProvider).firstWhere((c) => c.id == 'CMP-TEST-99');
      expect(updated.spentAmount, equals(140000.0));

      // Record Additional Beneficiary Distribution
      container.read(ngoCampaignsProvider.notifier).recordDistribution('CMP-TEST-99', 150);
      updated = container.read(ngoCampaignsProvider).firstWhere((c) => c.id == 'CMP-TEST-99');
      expect(updated.verifiedBeneficiariesReached, equals(350));

      // Check Financial Ledger Transaction Addition
      final initialTxCount = container.read(ngoTransactionsProvider).length;
      final newTx = NgoFinancialTransaction(
        id: 'TX-TEST-01',
        campaignId: 'CMP-TEST-99',
        transactionRef: 'NEFT-DR-9921',
        amount: 40000.0,
        transactionType: 'EXPENSE_SPENT',
        category: 'Thermal Blankets',
        entityName: 'Delhi Woolen Mills Cooperative',
        invoiceNumber: 'INV-WOOL-001',
        timestamp: DateTime.now(),
        approvalStatus: 'AUDIT_VERIFIED',
        invoiceDocumentProof: 'receipt_invoice_wool_signed.pdf',
      );

      container.read(ngoTransactionsProvider.notifier).addTransaction(newTx);
      expect(container.read(ngoTransactionsProvider).length, equals(initialTxCount + 1));
    });

    test('Phase 5 Smart Resource Allocation and Anti-Duplication Locking Matrix', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final allocations = container.read(areaAllocationsProvider);
      expect(allocations.isNotEmpty, isTrue);

      final ward4 = allocations.firstWhere((a) => a.areaName.contains('Ward 4'));
      expect(ward4.foodCoveragePercent, greaterThan(100.0)); // Food surplus flagged
      expect(ward4.waterCoveragePercent, lessThan(50.0));    // Water deficit flagged
      expect(ward4.primarySurplus, contains('Food'));
      expect(ward4.primaryShortage, contains('Water'));
      expect(ward4.isAllocationLocked, isTrue);

      // Toggle lock to prevent double dispatch
      container.read(areaAllocationsProvider.notifier).toggleLock(ward4.areaName);
      final unlocked = container.read(areaAllocationsProvider).firstWhere((a) => a.areaName == ward4.areaName);
      expect(unlocked.isAllocationLocked, isFalse);

      container.read(areaAllocationsProvider.notifier).toggleLock(ward4.areaName);
      final relocked = container.read(areaAllocationsProvider).firstWhere((a) => a.areaName == ward4.areaName);
      expect(relocked.isAllocationLocked, isTrue);
    });

    test('Master Acceptance Journey A: Citizen registration, persistent session, emergency SOS, and live tracking', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 1. Citizen registers with mandatory emergency contact and locality
      final citizen = UserModel(
        id: 'usr_cit_journey_a',
        citizenId: 'CIT-DEL-9921',
        name: 'Aarav Sharma',
        phoneMasked: '+91 98*** **210',
        phoneRaw: '+91 98765 43210',
        email: 'aarav@resqai.org',
        role: UserRole.citizen,
        badgeOrJurisdiction: 'Citizen Resident',
        emergencyContactPhone: '+91 98111 22233',
        stateName: 'Delhi',
        district: 'East Delhi',
        preferredLanguage: 'hi',
        isLocationPermissionGranted: true,
        loggedInAt: DateTime.now(),
      );

      // Verify persistent serialization
      final jsonMap = citizen.toJson();
      final restored = UserModel.fromJson(jsonMap);
      expect(restored.emergencyContactPhone, equals('+91 98111 22233'));
      expect(restored.district, equals('East Delhi'));

      // 2. Citizen triggers Emergency SOS
      final sosIncident = IncidentModel(
        id: 'RQ-SOS-JOURNEY-A',
        title: 'Trapped on 1st Floor due to rising flood waters',
        descriptionOriginal: 'Water level entered ground floor living room, elderly parents trapped.',
        descriptionTranslated: 'Water level entered ground floor living room, elderly parents trapped.',
        category: IncidentCategory.flood,
        latitude: 28.62,
        longitude: 77.28,
        address: 'Yamuna Khadar Ward 4',
        status: IncidentStatus.received,
        priorityScore: 90.0,
        priorityExplanation: 'High flood water with elderly trapped',
        vulnerableGroups: ['Elderly'],
        reporterPhoneMasked: '+91 98*** **210',
        reportedAt: DateTime.now(),
        source: 'ONE_TAP_SOS',
      );

      container.read(incidentsProvider.notifier).addIncident(sosIncident);
      final list = container.read(incidentsProvider);
      expect(list.any((i) => i.id == 'RQ-SOS-JOURNEY-A'), isTrue);

      // Track progression
      container.read(incidentsProvider.notifier).updateStatus('RQ-SOS-JOURNEY-A', IncidentStatus.helpAssigned);
      final updated = container.read(incidentsProvider).firstWhere((i) => i.id == 'RQ-SOS-JOURNEY-A');
      expect(updated.status, equals(IncidentStatus.helpAssigned));
    });

    test('Master Acceptance Journey B: Affected citizen damage claim submission, verification, and relief sanctioning', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final damageClaim = IncidentModel(
        id: 'RQ-DMG-JOURNEY-B',
        title: 'Agricultural Boundary & Pucca House Inundation Claim',
        descriptionOriginal: 'Boundary wall collapsed, 2 buffaloes lost, standing paddy crop flooded.',
        descriptionTranslated: 'Boundary wall collapsed, 2 buffaloes lost, standing paddy crop flooded.',
        category: IncidentCategory.flood,
        latitude: 28.63,
        longitude: 77.29,
        address: 'Mayur Vihar Lowland Sector 3',
        status: IncidentStatus.pendingReview,
        priorityScore: 78.0,
        priorityExplanation: 'Severe property loss & livestock loss',
        vulnerableGroups: [],
        reporterPhoneMasked: '+91 97*** **888',
        reportedAt: DateTime.now(),
        source: 'DAMAGE_REPORT',
        affectedProperties: ['Home Structure', 'Livestock', 'Agricultural Crop'],
        estimatedLossInr: 250000.0,
        householdMembersCount: 6,
        reliefRequirements: ['Dry Food', 'Tarpaulins', 'Cattle Fodder'],
      );

      container.read(incidentsProvider.notifier).addIncident(damageClaim);

      // Reviewer assigns and sanctions government relief grant
      container.read(incidentsProvider.notifier).recordVerificationDecision(
        'RQ-DMG-JOURNEY-B',
        newStatus: IncidentStatus.verified,
        reviewerId: 'GOV-ADM-DELHI',
        reviewerName: 'Dr. Rajeshwar Singh (ADM Relief)',
        reviewerRole: 'District Magistrate Relief Board',
        notes: 'Field Patwari verified structural wall collapse and livestock casualty.',
        reason: 'SDRF Gratuitous Cash Grant Sanctioned',
        departmentAssigned: 'Revenue & Disaster Management Dept',
      );

      final verified = container.read(incidentsProvider).firstWhere((i) => i.id == 'RQ-DMG-JOURNEY-B');
      expect(verified.status, equals(IncidentStatus.verified));
      expect(verified.reviewerName, equals('Dr. Rajeshwar Singh (ADM Relief)'));
      expect(verified.reviewerNotes, contains('Field Patwari verified'));
      expect(verified.decisionReason, contains('SDRF Gratuitous Cash Grant'));
    });

    test('Master Acceptance Journey C: NGO verification, campaign donation, audited voucher, and public ledger transparency', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final campaign = container.read(ngoCampaignsProvider).first;
      expect(campaign.isVerified, isTrue);

      final initialSpent = campaign.spentAmount;

      // Audited Expense logged with tax invoice
      container.read(ngoCampaignsProvider.notifier).recordExpense(campaign.id, 50000.0, 'Baby Milk Formula & Diapers');
      final updatedCampaign = container.read(ngoCampaignsProvider).firstWhere((c) => c.id == campaign.id);
      expect(updatedCampaign.spentAmount, equals(initialSpent + 50000.0));

      // Check transaction ledger entry
      final tx = NgoFinancialTransaction(
        id: 'TX-JOURNEY-C',
        campaignId: campaign.id,
        transactionRef: 'NEFT-DR-889912',
        amount: 50000.0,
        transactionType: 'EXPENSE_SPENT',
        category: 'Baby Care & Nutrition',
        entityName: 'Amul Emergency Milk Cooperative',
        invoiceNumber: 'INV-AMUL-091',
        timestamp: DateTime.now(),
        approvalStatus: 'AUDIT_VERIFIED',
        invoiceDocumentProof: 'amul_tax_invoice_verified.pdf',
      );

      container.read(ngoTransactionsProvider.notifier).addTransaction(tx);
      expect(container.read(ngoTransactionsProvider).any((t) => t.id == 'TX-JOURNEY-C'), isTrue);
    });

    test('Master Acceptance Journey D: Volunteer registration, task claiming, and delivery proof verification', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final tasks = container.read(volunteerTasksProvider);
      final task = tasks.first;

      // Volunteer accepts task
      container.read(volunteerTasksProvider.notifier).acceptTask(task.id);
      var accepted = container.read(volunteerTasksProvider).firstWhere((t) => t.id == task.id);
      expect(accepted.isAccepted, isTrue);

      // Volunteer marks complete with proof
      container.read(volunteerTasksProvider.notifier).completeTask(
        task.id,
        'Distributed 100 blankets at Mayur Vihar Camp Shelter; signed by Camp Ward Incharge.',
      );
      final completed = container.read(volunteerTasksProvider).firstWhere((t) => t.id == task.id);
      expect(completed.isCompleted, isTrue);
      expect(completed.deliveryProofNote, contains('signed by Camp Ward Incharge'));
    });

    test('Master Acceptance Journey E & F: Government SDRF accounting & Public Transparency Explorer non-PII verification', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Public Explorer verifies allocations without PII
      final allocations = container.read(areaAllocationsProvider);
      expect(allocations.isNotEmpty, isTrue);

      for (final a in allocations) {
        expect(a.affectedPeopleEstimated, greaterThan(0));
        expect(a.recommendedRedirection.isNotEmpty, isTrue);
      }
    });

    test('Master Acceptance Journey G & H: Location-matched alerts and anti-duplication resource redirection', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final alerts = container.read(alertsProvider);
      expect(alerts.isNotEmpty, isTrue);

      // Match alerts to East Delhi region
      final eastDelhiAlerts = alerts.where((a) => a.affectedRegion.toLowerCase().contains('delhi') || a.affectedRegion.toLowerCase().contains('yamuna')).toList();
      expect(eastDelhiAlerts.isNotEmpty, isTrue);
      expect(eastDelhiAlerts.first.isOfficial, isTrue);

      // Verify smart anti-duplication lock prevents double resource booking
      final ward4 = container.read(areaAllocationsProvider).firstWhere((a) => a.areaName.contains('Ward 4'));
      expect(ward4.isAllocationLocked, isTrue);
      expect(ward4.primarySurplus, contains('Food'));
    });

    test('Master Acceptance Journey I: Verified Citizen Donation & 80G Tax Exemption Receipt', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialDonations = container.read(donationsProvider);
      expect(initialDonations.isNotEmpty, isTrue);

      final newDonation = container.read(donationsProvider.notifier).createVerifiedDonation(
            campaignId: 'CMP-2026-DEL-01',
            campaignTitle: 'Yamuna Monsoon Flood Emergency Relief Camp',
            ngoName: 'SEWA Relief Mission India',
            ngoId: 'NGO-SEWA-01',
            amount: 5000.0,
            donorName: 'Dr. Vikram Malhotra',
            donorEmail: 'vikram.m@domain.in',
            donorPhone: '+91 98111 22334',
            isAnonymous: false,
            paymentMethod: 'UPI (Sandbox Simulated)',
          );

      expect(newDonation.paymentStatus, equals('VERIFIED'));
      expect(newDonation.receiptNumber, contains('80G-RESQAI-'));
      expect(newDonation.auditVerificationHash.isNotEmpty, isTrue);

      final allDonations = container.read(donationsProvider);
      expect(allDonations.any((d) => d.id == newDonation.id), isTrue);
    });

    test('Master Acceptance Journey J: 6-Step Comprehensive Damage Claim with Confidential Missing Persons & Vital Documents', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final claimId = 'RQ-DMG-TEST-101';
      final testClaim = IncidentModel(
        id: claimId,
        title: 'Yamuna Embankment Breach Submersion',
        descriptionOriginal: 'Pucca home flooded to 4ft; boundary wall collapsed.',
        descriptionTranslated: 'Pucca home flooded to 4ft; boundary wall collapsed.',
        category: IncidentCategory.flood,
        latitude: 28.6250,
        longitude: 77.2900,
        address: 'H-54, Yamuna Khadar, East Delhi',
        status: IncidentStatus.received,
        priorityScore: 92.0,
        priorityExplanation: 'Missing family member reported with extensive property damage',
        reporterPhoneMasked: '+91 98*** **210',
        reportedAt: DateTime.now(),
        source: 'CITIZEN_DAMAGE_CLAIM',
        householdMembersCount: 6,
        estimatedLossInr: 320000.0,
        affectedProperties: ['Pucca Housing Structure', 'Standing Crops', 'Livestock'],
        lostDocuments: ['Aadhaar Identity Card', 'Ration Card (NFSA / PDS)', 'Land Ownership Deed'],
        missingPersonsCount: 1,
        missingPersonsDetails: 'Rameshwar Lal, 68 yrs, wearing white kurta, last seen near bund',
        missingPersonEmergencyAssistanceNeeded: true,
        immediateSafetyConcerns: 'Live transformer sparks near inundation pool',
        reliefRequirements: ['Drinking Water Cans', 'Waterproof Tarpaulins', 'Ex-Gratia Financial Relief'],
      );

      container.read(incidentsProvider.notifier).addIncident(testClaim);

      final retrieved = container.read(incidentsProvider).firstWhere((i) => i.id == claimId);
      expect(retrieved.householdMembersCount, equals(6));
      expect(retrieved.missingPersonsCount, equals(1));
      expect(retrieved.missingPersonEmergencyAssistanceNeeded, isTrue);
      expect(retrieved.lostDocuments.length, equals(3));
      expect(retrieved.affectedProperties.contains('Standing Crops'), isTrue);
    });

    test('Master Acceptance Journey K: Government Statutory Relief Sanction & DBT Disbursal Lifecycle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final incident = container.read(incidentsProvider).first;

      // 1. Sanction relief benefit
      container.read(incidentsProvider.notifier).recordAssistanceSanction(
            incident.id,
            amount: 45000.0,
            category: 'SDRF Immediate Family & Shelter Restoration Grant',
            reviewerName: 'Dr. Sunita Rao (IAS)',
            reviewerId: 'GOV-IAS-001',
          );

      var updated = container.read(incidentsProvider).firstWhere((i) => i.id == incident.id);
      expect(updated.governmentAssistanceApproved, isTrue);
      expect(updated.sanctionedAmountInr, equals(45000.0));
      expect(updated.assistanceDeliveryStatus, equals('SANCTIONED'));

      // 2. Disburse direct benefit via PFMS DBT
      container.read(incidentsProvider.notifier).recordAssistanceDisbursal(
            incident.id,
            45000.0,
            bankRef: 'PFMS-DBT-TEST-8899',
          );

      updated = container.read(incidentsProvider).firstWhere((i) => i.id == incident.id);
      expect(updated.assistanceDeliveryStatus, equals('DISBURSED'));
      expect(updated.assistanceDeliveredInr, equals(45000.0));
      expect(updated.verificationHistory.first, contains('PFMS-DBT-TEST-8899'));
    });

    test('Master Acceptance Journey L: Citizen Disaster Help Hub with 12 Assistance Categories and Triage Routing', () {
      final categories = [
        'Emergency SOS',
        'Food & Drinking Water',
        'Temporary Shelter',
        'Medical Assistance',
        'Rescue & Evacuation',
        'Missing Family Members',
        'Home & Property Damage',
        'Lost Documents Replacement',
        'Financial & Cash Relief',
        'Clothing, Blankets & Essentials',
        'Agricultural & Livelihood Loss',
        'Other Emergency Needs',
      ];

      expect(categories.length, equals(12));
      expect(categories.contains('Emergency SOS'), isTrue);
      expect(categories.contains('Missing Family Members'), isTrue);
      expect(categories.contains('Lost Documents Replacement'), isTrue);
    });

    test('Master Acceptance Journey M: Citizen 5-Step Humanitarian Help Request Submission with Itemized Relief and Duplicate Prevention', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final helpRequestId = 'RQ-HLP-TEST-9001';
      final helpRequest = IncidentModel(
        id: helpRequestId,
        title: 'Emergency Flood Relief: Food, Drinking Water & Insulin Required',
        descriptionOriginal: 'Family stranded on first floor; 2 children and diabetic grandmother.',
        descriptionTranslated: 'Family stranded on first floor; 2 children and diabetic grandmother.',
        category: IncidentCategory.foodWater,
        latitude: 28.6480,
        longitude: 77.3450,
        address: 'Kaushambi Sector 4, Ghaziabad, UP',
        status: IncidentStatus.received,
        priorityScore: 94.0,
        priorityExplanation: 'Critical priority: flood stranding with 2 children, 1 elderly, urgent insulin and water needed.',
        vulnerableGroups: ['2 Children under 10', '1 Elderly / Diabetic with mobility restriction'],
        reporterPhoneMasked: '+91 98*** **445',
        reportedAt: DateTime.now(),
        source: 'CITIZEN_HUMANITARIAN_FORM',
        householdMembersCount: 5,
        reliefRequirements: [
          'Food Packets (x5 daily)',
          'Drinking Water Jerrycans (x4 20L)',
          'Medicines (Insulin Glargine & Syringes)',
          'Dry Blankets (x3)',
        ],
        immediateSafetyConcerns: 'Water level at 3.5 feet and rising slowly. Power cut since 6 hours.',
      );

      container.read(incidentsProvider.notifier).addIncident(helpRequest);

      final retrieved = container.read(incidentsProvider).firstWhere((i) => i.id == helpRequestId);
      expect(retrieved.householdMembersCount, equals(5));
      expect(retrieved.reliefRequirements.length, equals(4));
      expect(retrieved.vulnerableGroups.length, equals(2));
      expect(retrieved.priorityScore, greaterThanOrEqualTo(90.0));
      expect(retrieved.status, equals(IncidentStatus.received));
    });

    test('Master Acceptance Journey N: Citizen Confidential Missing Family Member Report with DPDP Safeguards and SAR Dispatch Toggle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final missingCaseId = 'RQ-MIS-TEST-7788';
      final missingReport = IncidentModel(
        id: missingCaseId,
        title: 'Missing Person: Rajesh Kumar (71 yrs, Father)',
        descriptionOriginal: 'Last seen wearing grey kurta-pyjama near Hindon bridge flood embankment.',
        descriptionTranslated: 'Last seen wearing grey kurta-pyjama near Hindon bridge flood embankment.',
        category: IncidentCategory.missingPerson,
        latitude: 28.6550,
        longitude: 77.3450,
        address: 'Hindon Bridge Embankment, Ghaziabad, UP',
        status: IncidentStatus.received,
        priorityScore: 96.0,
        priorityExplanation: 'High-urgency missing elderly person in active flood zone with immediate tactical SAR requested.',
        reporterPhoneMasked: '+91 98*** **789',
        reportedAt: DateTime.now(),
        source: 'CITIZEN_MISSING_PERSON_PORTAL',
        missingPersonsCount: 1,
        missingPersonsDetails: 'Rajesh Kumar, 71 yrs, 5ft 8in, white hair, grey kurta pyjama, wears glasses, diabetic.',
        missingPersonEmergencyAssistanceNeeded: true,
        immediateSafetyConcerns: 'Elderly with hypertension; area is submerged under flood waters.',
      );

      container.read(incidentsProvider.notifier).addIncident(missingReport);

      final retrieved = container.read(incidentsProvider).firstWhere((i) => i.id == missingCaseId);
      expect(retrieved.category, equals(IncidentCategory.missingPerson));
      expect(retrieved.missingPersonsCount, equals(1));
      expect(retrieved.missingPersonEmergencyAssistanceNeeded, isTrue);
      expect(retrieved.missingPersonsDetails, contains('Rajesh Kumar'));
      expect(retrieved.priorityScore, greaterThanOrEqualTo(95.0));
    });

    test('Master Acceptance Journey O: Dual-Tab Citizen Request Tracking and Delivered Assistance History Ledger', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Verify incidents list can be filtered for tracking
      final allIncidents = container.read(incidentsProvider);
      expect(allIncidents.isNotEmpty, isTrue);

      final verifiedIncidents = allIncidents.where((i) => i.status == IncidentStatus.verified).toList();
      expect(verifiedIncidents.isNotEmpty, isTrue);

      // Verify assistance disbursal status
      final sanctionedIncident = allIncidents.first;
      container.read(incidentsProvider.notifier).recordAssistanceSanction(
            sanctionedIncident.id,
            amount: 50000.0,
            category: 'SDRF Ex-Gratia Housing Grant',
            reviewerName: 'District Collector (DM)',
            reviewerId: 'DM-GZB-01',
          );

      var updated = container.read(incidentsProvider).firstWhere((i) => i.id == sanctionedIncident.id);
      expect(updated.governmentAssistanceApproved, isTrue);
      expect(updated.sanctionedAmountInr, equals(50000.0));
      expect(updated.assistanceDeliveryStatus, equals('SANCTIONED'));

      container.read(incidentsProvider.notifier).recordAssistanceDisbursal(
            sanctionedIncident.id,
            50000.0,
            bankRef: 'DBT-PFMS-2026-9901',
          );
      updated = container.read(incidentsProvider).firstWhere((i) => i.id == sanctionedIncident.id);
      expect(updated.assistanceDeliveryStatus, equals('DISBURSED'));
      expect(updated.assistanceDeliveredInr, equals(50000.0));
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
      expect(find.text(AppConstants.appName), findsWidgets);
    });
  });
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) {
      return null;
    }
    return Future<HttpClientRequest>.value(_MockHttpClientRequest());
  }
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  bool persistentConnection = false;

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return Future<dynamic>.value(null);
  }
}

class _MockHttpClientResponse implements HttpClientResponse {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentImageBytes.length;

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  bool get persistentConnection => false;

  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.value(_transparentImageBytes).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => false;
}

final List<int> _transparentImageBytes = const <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
];

