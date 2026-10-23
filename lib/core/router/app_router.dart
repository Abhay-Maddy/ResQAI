import 'package:flutter/material.dart';
import '../../features/home/home_portal_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/citizen/citizen_dashboard_screen.dart';
import '../../features/citizen/citizen_sos_screen.dart';
import '../../features/citizen/citizen_reports_screen.dart';
import '../../features/citizen/citizen_new_report_screen.dart';
import '../../features/citizen/citizen_report_detail_screen.dart';
import '../../features/citizen/citizen_shelters_screen.dart';
import '../../features/citizen/citizen_alerts_screen.dart';
import '../../features/map/disaster_map_screen.dart';
import '../../features/transparency/transparency_overview_screen.dart';
import '../../features/transparency/transparency_organizations_screen.dart';
import '../../features/transparency/transparency_funds_screen.dart';
import '../../features/transparency/transparency_areas_screen.dart';
import '../../features/intelligence/intelligence_dashboard_screen.dart';
import '../../features/intelligence/risk_forecast_screen.dart';
import '../../features/intelligence/needs_forecast_screen.dart';
import '../../features/intelligence/resource_optimization_screen.dart';
import '../../features/intelligence/anomalies_screen.dart';
import '../../features/intelligence/scenario_simulation_screen.dart';
import '../../features/intelligence/model_performance_screen.dart';
import '../../features/ngo/ngo_dashboard_screen.dart';
import '../../features/ngo/ngo_management_screen.dart';
import '../../features/volunteer/volunteer_dashboard_screen.dart';
import '../../features/volunteer/volunteer_portal_screen.dart';
import '../../features/government/government_command_centre_screen.dart';
import '../../features/government/government_financial_screen.dart';
import '../../features/government/government_operations_screen.dart';
import '../../features/medical/medical_dashboard_screen.dart';
import '../../features/rescue/responder_dashboard_screen.dart';
import '../../features/preparedness/preparedness_screen.dart';

class AppRoutes {
  // Public
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String transparency = '/transparency';
  static const String transparencyOrgs = '/transparency/organizations';
  static const String transparencyFunds = '/transparency/funds';
  static const String transparencyAreas = '/transparency/areas';
  static const String preparedness = '/preparedness';
  static const String disasterMap = '/disaster-map';

  // Citizen
  static const String citizenDashboard = '/citizen/dashboard';
  static const String citizenMap = '/citizen/map';
  static const String citizenAlerts = '/citizen/alerts';
  static const String citizenSos = '/citizen/sos';
  static const String citizenReports = '/citizen/reports';
  static const String citizenNewReport = '/citizen/reports/new';
  static const String citizenReportDetail = '/citizen/reports/:id';
  static const String citizenAssistance = '/citizen/assistance';
  static const String citizenShelters = '/citizen/shelters';
  static const String citizenNotifications = '/citizen/notifications';
  static const String citizenProfile = '/citizen/profile';
  static const String citizenEmergencyContacts = '/citizen/emergency-contacts';

  // NGO
  static const String ngoDashboard = '/ngo/dashboard';
  static const String ngoOperations = '/ngo/operations';
  static const String ngoCampaigns = '/ngo/campaigns';
  static const String ngoDonations = '/ngo/donations';
  static const String ngoFinances = '/ngo/finances';
  static const String ngoExpenses = '/ngo/expenses';
  static const String ngoResources = '/ngo/resources';
  static const String ngoBeneficiaries = '/ngo/beneficiaries';
  static const String ngoCoverageMap = '/ngo/coverage-map';
  static const String ngoVolunteers = '/ngo/volunteers';
  static const String ngoVerification = '/ngo/verification';
  static const String ngoReports = '/ngo/reports';

  // Volunteer
  static const String volunteerDashboard = '/volunteer/dashboard';
  static const String volunteerOpportunities = '/volunteer/opportunities';
  static const String volunteerTasks = '/volunteer/tasks';
  static const String volunteerTaskDetail = '/volunteer/tasks/:id';
  static const String volunteerMap = '/volunteer/map';
  static const String volunteerAvailability = '/volunteer/availability';
  static const String volunteerTraining = '/volunteer/training';
  static const String volunteerDonations = '/volunteer/donations';
  static const String volunteerHistory = '/volunteer/history';
  static const String volunteerProfile = '/volunteer/profile';

  // Government
  static const String governmentDashboard = '/government/dashboard';
  static const String governmentCommandCentre = '/government/command-centre';
  static const String governmentIncidents = '/government/incidents';
  static const String governmentIncidentDetail = '/government/incidents/:id';
  static const String governmentVerification = '/government/verification';
  static const String governmentDispatch = '/government/dispatch';
  static const String governmentTeams = '/government/teams';
  static const String governmentHospitals = '/government/hospitals';
  static const String governmentShelters = '/government/shelters';
  static const String governmentResources = '/government/resources';
  static const String governmentReliefPrograms = '/government/relief-programs';
  static const String governmentFinancialTransparency = '/government/financial-transparency';
  static const String governmentAreaCoverage = '/government/area-coverage';
  static const String governmentAnalytics = '/government/analytics';
  static const String governmentAudit = '/government/audit';
  static const String governmentAnnouncements = '/government/announcements';

  // Responder & Medical
  static const String responderDashboard = '/responder/dashboard';
  static const String responderAssignments = '/responder/assignments';
  static const String responderAssignmentDetail = '/responder/assignments/:id';
  static const String responderMap = '/responder/map';
  static const String medicalDashboard = '/medical/dashboard';
  static const String medicalRequests = '/medical/requests';
  static const String medicalHospitals = '/medical/hospitals';
  static const String medicalResources = '/medical/resources';

  // AI Intelligence
  static const String intelligenceDashboard = '/intelligence/dashboard';
  static const String intelligenceRiskForecast = '/intelligence/risk-forecast';
  static const String intelligenceImpactAnalysis = '/intelligence/impact-analysis';
  static const String intelligenceNeedsForecast = '/intelligence/needs-forecast';
  static const String intelligenceResourceOptimization = '/intelligence/resource-optimization';
  static const String intelligenceAnomalies = '/intelligence/anomalies';
  static const String intelligenceSimulation = '/intelligence/simulation';
  static const String intelligenceModelPerformance = '/intelligence/model-performance';
}

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? AppRoutes.home);
    final path = uri.path;

    // Parameterized Route Matching: /citizen/reports/:id or /government/incidents/:id
    if (path.startsWith('/citizen/reports/') && path != AppRoutes.citizenNewReport) {
      final id = path.replaceFirst('/citizen/reports/', '');
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => CitizenReportDetailScreen(incidentId: id),
      );
    }

    if (path.startsWith('/government/incidents/')) {
      final id = path.replaceFirst('/government/incidents/', '');
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => CitizenReportDetailScreen(incidentId: id),
      );
    }

    Widget page;
    switch (path) {
      // Public
      case AppRoutes.home:
        page = const HomePortalScreen();
        break;
      case AppRoutes.login:
        page = const AuthScreen(isRegisterMode: false);
        break;
      case AppRoutes.register:
      case AppRoutes.forgotPassword:
        page = const AuthScreen(isRegisterMode: true);
        break;
      case AppRoutes.disasterMap:
      case AppRoutes.citizenMap:
      case AppRoutes.responderMap:
      case AppRoutes.volunteerMap:
        page = DisasterMapScreen(routePath: path);
        break;
      case AppRoutes.transparency:
        page = const TransparencyOverviewScreen();
        break;
      case AppRoutes.transparencyOrgs:
        page = const TransparencyOrganizationsScreen();
        break;
      case AppRoutes.transparencyFunds:
        page = const TransparencyFundsScreen();
        break;
      case AppRoutes.transparencyAreas:
        page = const TransparencyAreasScreen();
        break;
      case AppRoutes.preparedness:
        page = const PreparednessScreen();
        break;

      // Citizen
      case AppRoutes.citizenDashboard:
        page = const CitizenDashboardScreen();
        break;
      case AppRoutes.citizenSos:
        page = const CitizenSosScreen();
        break;
      case AppRoutes.citizenReports:
      case AppRoutes.citizenAssistance:
        page = const CitizenReportsScreen();
        break;
      case AppRoutes.citizenNewReport:
        page = const CitizenNewReportScreen();
        break;
      case AppRoutes.citizenAlerts:
      case AppRoutes.citizenNotifications:
        page = const CitizenAlertsScreen();
        break;
      case AppRoutes.citizenShelters:
        page = const CitizenSheltersScreen();
        break;
      case AppRoutes.citizenProfile:
      case AppRoutes.citizenEmergencyContacts:
        page = const CitizenDashboardScreen();
        break;

      // NGO
      case AppRoutes.ngoDashboard:
      case AppRoutes.ngoOperations:
      case AppRoutes.ngoVolunteers:
      case AppRoutes.ngoVerification:
      case AppRoutes.ngoReports:
        page = const NgoDashboardScreen();
        break;
      case AppRoutes.ngoCampaigns:
      case AppRoutes.ngoDonations:
      case AppRoutes.ngoFinances:
      case AppRoutes.ngoExpenses:
      case AppRoutes.ngoResources:
      case AppRoutes.ngoBeneficiaries:
      case AppRoutes.ngoCoverageMap:
        page = const NgoManagementScreen();
        break;

      // Volunteer
      case AppRoutes.volunteerDashboard:
      case AppRoutes.volunteerHistory:
      case AppRoutes.volunteerProfile:
      case AppRoutes.volunteerAvailability:
      case AppRoutes.volunteerTraining:
      case AppRoutes.volunteerDonations:
        page = const VolunteerDashboardScreen();
        break;
      case AppRoutes.volunteerOpportunities:
      case AppRoutes.volunteerTasks:
        page = const VolunteerPortalScreen();
        break;

      // Government
      case AppRoutes.governmentDashboard:
      case AppRoutes.governmentCommandCentre:
      case AppRoutes.governmentDispatch:
      case AppRoutes.governmentTeams:
      case AppRoutes.governmentAnnouncements:
        page = const GovernmentCommandCentreScreen();
        break;
      case AppRoutes.governmentIncidents:
      case AppRoutes.governmentVerification:
      case AppRoutes.governmentReliefPrograms:
      case AppRoutes.governmentHospitals:
      case AppRoutes.governmentShelters:
      case AppRoutes.governmentResources:
      case AppRoutes.governmentAnalytics:
      case AppRoutes.governmentAudit:
        page = const GovernmentOperationsScreen();
        break;
      case AppRoutes.governmentFinancialTransparency:
        page = const GovernmentFinancialScreen();
        break;
      case AppRoutes.governmentAreaCoverage:
        page = const TransparencyAreasScreen();
        break;

      // Responder & Medical
      case AppRoutes.responderDashboard:
      case AppRoutes.responderAssignments:
        page = const ResponderDashboardScreen();
        break;
      case AppRoutes.medicalDashboard:
      case AppRoutes.medicalRequests:
      case AppRoutes.medicalHospitals:
      case AppRoutes.medicalResources:
        page = const MedicalDashboardScreen();
        break;

      // AI Intelligence
      case AppRoutes.intelligenceDashboard:
        page = const IntelligenceDashboardScreen();
        break;
      case AppRoutes.intelligenceRiskForecast:
      case AppRoutes.intelligenceImpactAnalysis:
        page = const RiskForecastScreen();
        break;
      case AppRoutes.intelligenceNeedsForecast:
        page = const NeedsForecastScreen();
        break;
      case AppRoutes.intelligenceResourceOptimization:
        page = const ResourceOptimizationScreen();
        break;
      case AppRoutes.intelligenceAnomalies:
        page = const AnomaliesScreen();
        break;
      case AppRoutes.intelligenceSimulation:
        page = const ScenarioSimulationScreen();
        break;
      case AppRoutes.intelligenceModelPerformance:
        page = const ModelPerformanceScreen();
        break;

      default:
        page = const HomePortalScreen();
        break;
    }

    return MaterialPageRoute(
      settings: settings,
      builder: (_) => page,
    );
  }
}
