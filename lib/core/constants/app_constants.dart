class AppConstants {
  static const String appName = 'ResQAI';
  static const String appFullName = 'AI-Powered Disaster Response and Management System';
  static const String appTagline = 'College InnoTech Exhibition 2026';
  static const String appVersion = '1.5.0';
  static const String latestKnownVersion = '1.5.0';
  static const String buildNumber = '2026.5';
  static const String githubRepo = 'https://github.com/rxhulsingh16/ResQAI';

  // Local storage keys
  static const String keyLanguage = 'resqai_language';
  static const String keyTheme = 'resqai_theme';
  static const String keyAuthToken = 'resqai_auth_token';
  static const String keyUserRole = 'resqai_user_role';
  static const String keyOfflineDrafts = 'resqai_offline_drafts';

  // API Server Base URL
  static const String apiBaseUrl = 'http://localhost:5000/api/v1';

  // Disclaimers (Safety & Emergency)
  static const String safetyNotice = 
      'NOTICE: ResQAI is an AI-assisted decision support system for disaster management and coordination. '
      'It does not replace official emergency services, NDMA, or 112 emergency calls. '
      'Do not assume routes or shelters are guaranteed safe without responder verification.';
}

enum UserRole {
  citizen('Citizen', 'Public reporter & assistance seeker'),
  volunteer('Volunteer', 'Community helper & field assistance'),
  ngoLead('NGO / Relief Org', 'Relief coordinator & campaign manager'),
  govtOfficial('Govt Official', 'District administration & magistrate'),
  doctor('Doctor / Medical', 'Medical volunteer & healthcare referral'),
  rescueTeam('Rescue Team', 'NDRF / SDRF / Emergency responder'),
  incidentCommander('Incident Commander', 'District disaster command authority'),
  fieldResponder('Field Responder', 'Rescue unit operator on the ground'),
  reliefStaff('Relief Staff', 'Shelter & supplies allocator'),
  analyst('Data Analyst', 'Early warning & AI monitoring'),
  admin('System Admin', 'Super-user with full governance & audit rights');

  final String title;
  final String description;
  const UserRole(this.title, this.description);
}

enum IncidentStatus {
  received('Submitted', 'Report logged into intake queue'),
  pendingReview('Pending Review', 'Awaiting triage and assignment'),
  underReview('Under Verification', 'Field or officer verification in progress'),
  verified('Verified', 'Confirmed genuine emergency'),
  unverified('Unverified', 'Insufficient evidence or unsubstantiated'),
  duplicate('Duplicate', 'Merged with existing primary incident'),
  helpAssigned('Response Assigned', 'Rescue team or relief unit dispatched'),
  inProgress('In Progress', 'Active operations on scene'),
  resolved('Resolved', 'Assistance delivered & life stabilized'),
  closed('Closed', 'Incident closed with post-action report');

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
  foodWater('Food & Drinking Water Shortage', 0.7),
  missingPerson('Missing Person / Family Tracing', 0.95),
  other('Other Disaster Emergency', 0.75);

  final String label;
  final double baseWeight;
  const IncidentCategory(this.label, this.baseWeight);
}
