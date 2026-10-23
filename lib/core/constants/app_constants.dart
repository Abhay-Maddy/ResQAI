class AppConstants {
  static const String appName = 'ResQAI';
  static const String appFullName = 'AI-Powered Disaster Response and Management System';
  static const String appTagline = 'College InnoTech Exhibition 2026';
  static const String githubRepo = 'https://github.com/rxhulsingh16/ResQAI';

  // Local storage keys
  static const String keyLanguage = 'resqai_language';
  static const String keyTheme = 'resqai_theme';
  static const String keyAuthToken = 'resqai_auth_token';
  static const String keyUserRole = 'resqai_user_role';
  static const String keyOfflineDrafts = 'resqai_offline_drafts';

  // API Base URL (Node.js Express backend)
  static const String defaultApiUrl = 'http://localhost:5000/api';

  // Disclaimers (Safety & Emergency)
  static const String safetyNotice = 
      'NOTICE: ResQAI is an AI-assisted decision support system for disaster management and coordination. '
      'It does not replace official emergency services, NDMA, or 112 emergency calls. '
      'Do not assume routes or shelters are guaranteed safe without responder verification.';
}

enum UserRole {
  citizen('Citizen', 'Public reporter & aid tracker'),
  fieldResponder('Field Responder', 'Rescue team on the ground'),
  ngoLead('NGO Coordinator', 'Relief material & camp manager'),
  reliefStaff('Relief Staff', 'Shelter & supplies allocator'),
  analyst('Data Analyst', 'Early warning & AI monitoring'),
  incidentCommander('Incident Commander', 'District disaster manager'),
  admin('System Admin', 'Super-user with full governance & audit rights');

  final String title;
  final String description;
  const UserRole(this.title, this.description);
}

enum IncidentStatus {
  received('Received', 'Report logged into triage queue'),
  underReview('Under Review', 'AI & human verification in progress'),
  verified('Verified', 'Confirmed genuine by responder'),
  helpAssigned('Help Assigned', 'Rescue team or relief unit en route'),
  resolved('Resolved', 'Assistance delivered & case closed');

  final String label;
  final String description;
  const IncidentStatus(this.label, this.description);
}

enum IncidentCategory {
  flood('Flood / Waterlogging', 0.9),
  earthquake('Structural Collapse / Earthquake', 0.95),
  cyclone('Cyclone / Storm Surge', 0.85),
  fire('Fire / Chemical Hazard', 0.9),
  landslide('Landslide / Road Blockage', 0.8),
  medical('Medical Emergency', 0.95),
  foodWater('Food & Drinking Water Shortage', 0.7);

  final String label;
  final double baseWeight;
  const IncidentCategory(this.label, this.baseWeight);
}
