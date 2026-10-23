import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resqai/app.dart';
import 'package:resqai/core/constants/app_constants.dart';
import 'package:resqai/core/utils/i18n.dart';
import 'package:resqai/shared/models/incident_model.dart';
import 'package:resqai/shared/models/user_model.dart';
import 'package:resqai/data/repositories/incident_repository.dart';

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
