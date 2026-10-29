import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resqai/core/constants/app_constants.dart';
import 'package:resqai/core/router/app_router.dart';
import 'package:resqai/data/services/weather_service.dart';
import 'package:resqai/data/services/storage_service.dart';
import 'package:resqai/data/repositories/auth_repository.dart';
import 'package:resqai/shared/models/user_model.dart';
import 'package:resqai/shared/widgets/access_denied_screen.dart';
import 'package:resqai/features/auth/auth_screen.dart';
import 'package:resqai/features/citizen/widgets/live_weather_card.dart';
import 'package:resqai/features/citizen/widgets/sos_confirmation_dialog.dart';
import 'package:resqai/features/profile/user_profile_screen.dart';
import 'package:resqai/data/services/app_update_service.dart';
import 'package:resqai/data/services/app_version_provider.dart';
import 'package:resqai/data/repositories/incident_repository.dart';
import 'package:resqai/core/layout/app_shell.dart';

void main() {
  group('PRD v3.0 Acceptance Tests (Frontend)', () {
    test('PRD Section 3 (WX-1..5): WeatherModel deserializes correctly and identifies severe weather', () {
      final json = {
        'cached': false,
        'weather': {
          'temperature': 29.2,
          'feels_like': 32.8,
          'relative_humidity_2m': 84,
          'wind_speed_10m': 18.5,
          'precipitation_probability': 85,
          'condition': 'Severe Thunderstorm',
          'weather_code': 95,
        },
        'advisory': {
          'severity': 'SEVERE',
          'message': 'IMD Flash Flood Warning active in Hindon River basin',
        },
      };

      final model = WeatherModel.fromJson(
        json,
        locationName: 'Ghaziabad Sector 4',
      );

      expect(model.temperature, equals(29.2));
      expect(model.feelsLike, equals(32.8));
      expect(model.humidity, equals(84));
      expect(model.windSpeed, equals(18.5));
      expect(model.rainProbability, equals(85));
      expect(model.condition, equals('Severe Thunderstorm'));
      expect(model.isSevere, isTrue);
      expect(model.advisory, contains('IMD Flash Flood Warning'));
      expect(model.isCached, isFalse);
      expect(model.locationName, equals('Ghaziabad Sector 4'));
    });

    test('PRD Section 3 (WX-4): WeatherModel fallback creates offline cached state gracefully', () {
      final fallback = WeatherModel.fallback('Ghaziabad Lowlands');

      expect(fallback.isCached, isTrue);
      expect(fallback.locationName, equals('Ghaziabad Lowlands'));
      expect(fallback.temperature, greaterThan(0));
      expect(fallback.feelsLike, greaterThan(fallback.temperature));
    });

    testWidgets(
      'PRD Section 8 & SEC-1: AppRouter blocks unauthenticated access to private screens',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        // Clear current user session
        StorageService.clear();

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              onGenerateRoute: AppRouter.onGenerateRoute,
              initialRoute: AppRoutes.citizenHelpRequest,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // AuthScreen should render because citizenHelpRequest is private
        expect(find.byType(AuthScreen), findsOneWidget);
      },
    );

    testWidgets(
      'PRD Section 8 & SEC-2: AppRouter enforces role separation (Citizen blocked from Govt modules)',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        // Set citizen in storage
        final citizen = UserModel(
          id: 'USR-TEST-CIT',
          citizenId: 'RQ-CIT-TEST',
          name: 'Citizen Tester',
          email: 'citizen@test.com',
          role: UserRole.citizen,
          badgeOrJurisdiction: 'Delhi',
          phoneMasked: '+91 98*** **000',
          emergencyContactName: 'Contact Person',
          emergencyContactPhone: '+91 98765 00000',
          bloodGroup: 'O+',
          isVerified: true,
          verificationStatus: 'APPROVED',
          loggedInAt: DateTime.now(),
        );
        StorageService.setString(
          StorageService.keyCurrentUser,
          jsonEncode(citizen.toJson()),
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              onGenerateRoute: AppRouter.onGenerateRoute,
              initialRoute: AppRoutes.governmentCommandCentre,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should show AccessDeniedScreen (403)
        expect(find.byType(AccessDeniedScreen), findsOneWidget);
        expect(find.textContaining('Access Restricted (403)'), findsOneWidget);
        expect(find.textContaining('Incident Commander'), findsWidgets);
      },
    );

    testWidgets(
      'PRD Section 4 & SOS-4, SOS-7: SosConfirmationDialog renders reference and delivery checklist',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SosConfirmationDialog(
                incidentId: 'RQ-SOS-9912',
                locationAddress:
                    'Ghaziabad Hindon River (28.6480°N, 77.3450°E)',
                latitude: 28.6480,
                longitude: 77.3450,
                emergencyContacts: ['Kavita Verma (+91 98765 00112)'],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('RQ-SOS-9912'), findsOneWidget);
        expect(find.textContaining('Distress SOS Transmitted'), findsOneWidget);
        expect(
          find.textContaining('Admin EOC Queue Dispatched'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Emergency Contacts Alerted via SMS'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Live GPS Telemetry Fix Transmitted'),
          findsOneWidget,
        );
        expect(find.text('Add Details to this Emergency'), findsOneWidget);
        expect(find.text('Dial 112'), findsOneWidget);
        expect(find.text('I pressed by mistake'), findsOneWidget);
      },
    );

    testWidgets(
      'PRD Section 3 (WX-2, WX-5): LiveWeatherCard renders metrics and refresh button',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LiveWeatherCard(
                latitude: 28.6480,
                longitude: 77.3450,
                locationName: 'Ghaziabad, UP',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Live Microclimate & Weather'), findsOneWidget);
        expect(find.text('Humidity'), findsOneWidget);
        expect(find.text('Wind Speed'), findsOneWidget);
        expect(find.text('Rain Chance'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      },
    );

    testWidgets(
      'PRD Section 9 (DEL-1..8): UserProfileScreen contains Danger Zone and Download Data button',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final user = UserModel(
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
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith((ref) => AuthNotifier()..loginAs(user)),
            ],
            child: const MaterialApp(
              home: UserProfileScreen(initialTabIndex: 4),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Hidden Settings & Privacy'), findsOneWidget);
        expect(find.textContaining('Delete My Account'), findsOneWidget);
        expect(find.textContaining('Download My Data (DPDP'), findsOneWidget);
      },
    );
    test('Update System: Version comparison, normalization and next version calculation', () {
      expect(AppUpdateService.normalizeVersion('1.50'), '1.5.0');
      expect(AppUpdateService.normalizeVersion('v1.50'), '1.5.0');
      expect(AppUpdateService.normalizeVersion('1.5.0'), '1.5.0');

      // Equal versions
      expect(AppUpdateService.compareVersions('1.5.0', '1.5.0'), 0);
      expect(AppUpdateService.compareVersions('1.50', '1.5.0'), 0);
      expect(AppUpdateService.compareVersions('1.5.05', '1.5.05'), 0);

      // Newer releases
      expect(AppUpdateService.compareVersions('1.5.05', '1.5.0'), greaterThan(0));
      expect(AppUpdateService.compareVersions('1.5.0', '1.2.0'), greaterThan(0));
      expect(AppUpdateService.compareVersions('1.2.0', '1.5.0'), lessThan(0));

      // Next candidate calculation
      expect(AppUpdateService.computeNextVersion('1.2.0'), '1.5.0');
      expect(AppUpdateService.computeNextVersion('1.5.0'), '1.5.05');
      expect(AppUpdateService.computeNextVersion('1.50'), '1.5.05');
      expect(AppUpdateService.computeNextVersion('1.5.05'), '1.5.06');
    });

    test('Update System: Compiled binary version overrides stale cached version', () {
      // Simulate phone having old 1.0.0 in storage
      StorageService.setString(StorageService.keyInstalledAppVersion, '1.0.0');

      final notifier = AppVersionNotifier();
      // Should auto-upgrade to AppConstants.appVersion (1.5.0)
      expect(notifier.state, AppConstants.appVersion);
      expect(StorageService.getString(StorageService.keyInstalledAppVersion), AppConstants.appVersion);
    });

    testWidgets('Workstream 1: Guest user bottom navigation is strictly isolated from Government Command Center', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      StorageService.clear();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => AuthNotifier()..logout()),
            activeRoleProvider.overrideWith((ref) => UserRole.citizen),
          ],
          child: const MaterialApp(
            home: AppShell(
              currentRoute: AppRoutes.home,
              child: SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Guest must see Sign In, Map, Alerts
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);

      // Guest must NEVER see Command Center tabs
      expect(find.text('Command'), findsNothing);
      expect(find.text('SDRF'), findsNothing);
      expect(find.text('AI'), findsNothing);
    });

    testWidgets('3-Line Menu: UserProfileScreen 3-line menu bar opens bottom sheet with all 6 options', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = AuthNotifier.defaultCitizen;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => AuthNotifier()..loginAs(user)),
          ],
          child: const MaterialApp(
            home: UserProfileScreen(initialTabIndex: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the 3-line navigation menu bar
      final menuBar = find.textContaining('NAVIGATION MENU (☰)');
      expect(menuBar, findsOneWidget);
      await tester.tap(menuBar);
      await tester.pumpAndSettle();

      // Verify all 6 menu options are present in the bottom sheet
      expect(find.text('Three-Line Menu (☰)'), findsOneWidget);
      expect(find.text('Profile Settings'), findsWidgets);
      expect(find.text('Personal Security'), findsOneWidget);
      expect(find.text('Life-Safety Channels'), findsOneWidget);
      expect(find.text('Settings & Updates'), findsOneWidget);
      expect(find.text('Hidden Settings & Privacy'), findsOneWidget);
      expect(find.text('Helplines & Disaster Protocols'), findsOneWidget);
    });
  });
}
