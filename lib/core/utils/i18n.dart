import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/storage_service.dart';

class I18nService {
  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'app_title': 'ResQAI — Disaster Response System',
      'sos_button': 'EMERGENCY SOS',
      'sos_subtitle': 'One-tap reporting with automatic GPS',
      'report_incident': 'Report an Incident',
      'track_status': 'Track Report Status',
      'command_center': 'Command Dashboard',
      'tactical_map': 'Live Tactical Map',
      'responder_tasks': 'Responder Tasks',
      'shelter_board': 'Shelter & Resources',
      'official_alerts': 'Official Alerts (IMD/NDMA)',
      'what_if_analysis': 'AI What-If Priority Simulation',
      'silent_zone': 'Silent-Zone Blackout Detector',
      'rumor_tracker': 'Rumor & Misinformation Tracker',
      'volunteer_matching': 'Volunteer Skill Matching',
      'preparedness_mode': 'Family Preparedness & Kits',
      'situation_summary': 'Situation Summary (SitRep)',
      'after_action': 'After-Action Review Replay',
      'system_health': 'System Health & Backup Status',
      'language_toggle': 'हिंदी',
      'current_role': 'Active Role',
      'offline_queued': 'Offline Queued Changes',
      'sync_status': 'Synced with Server',
      'category': 'Category',
      'location': 'Location',
      'priority': 'Priority Score',
      'vulnerable_groups': 'Vulnerable Groups Detected',
      'duplicate_warning': 'Possible Duplicate Detected',
      'confirm_duplicate': 'Human Confirmation Required',
      'not_verified_safe': 'NOT VERIFIED SAFE ROUTE',
      'voice_note': 'Optional Voice Note',
      'submit_report': 'Submit Emergency Report',
      'reference_id': 'Reference ID',
      'search_ref': 'Search Reference ID (e.g. RQ-901)',
      'safety_disclaimer': 'ResQAI is an AI-assisted decision support system and does not replace emergency 112 services.',
      'notifications': 'Notifications & Alerts',
      'received': 'Received',
      'sent': 'Sent',
      'unread': 'Unread',
      'all': 'All',
      'critical': 'Critical',
      'mark_all_read': 'Mark all read',
      'donate_relief': 'Donate Relief Now',
      'browse_campaigns': 'Browse Campaigns',
      'find_shelter': 'Find Shelter',
      'request_aid': 'Request Aid',
      'check_updates': 'Check for Updates',
      'options': 'Options',
      'settings': 'Settings',
      'profile': 'Profile Settings',
      'sign_out': 'Sign Out',
    },
    'hi': {
      'app_title': 'रेस्क्यू एआई (ResQAI) — आपदा प्रबंधन प्रणाली',
      'sos_button': 'आपातकालीन एसओएस (SOS)',
      'sos_subtitle': 'स्वचालित जीपीएस के साथ एक-टैप रिपोर्टिंग',
      'report_incident': 'आपदा की सूचना दें',
      'track_status': 'रिपोर्ट स्थिति ट्रैक करें',
      'command_center': 'कमांड डैशबोर्ड',
      'tactical_map': 'लाइव मानचित्र व सुरक्षित मार्ग',
      'responder_tasks': 'बचावकर्मियों के कार्य',
      'shelter_board': 'राहत शिविर व सामग्री',
      'official_alerts': 'आधिकारिक चेतावनियां (IMD/NDMA)',
      'what_if_analysis': 'एआई व्हाट-इफ प्राथमिकता विश्लेषण',
      'silent_zone': 'मौन क्षेत्र ब्लैकआउट संसूचक',
      'rumor_tracker': 'अफवाह व भ्रामक सूचना ट्रैकर',
      'volunteer_matching': 'स्वयंसेवक कौशल मिलान',
      'preparedness_mode': 'पारिवारिक आपदा तैयारी व किट',
      'situation_summary': 'स्थिति रिपोर्ट (SitRep)',
      'after_action': 'घटना टाइमलाइन समीक्षा',
      'system_health': 'सिस्टम स्वास्थ्य व बैकअप',
      'language_toggle': 'English',
      'current_role': 'सक्रिय भूमिका',
      'offline_queued': 'ऑफ़लाइन कतारबद्ध बदलाव',
      'sync_status': 'सर्वर से सिंक्रनाइज़',
      'category': 'श्रेणी',
      'location': 'स्थान',
      'priority': 'प्राथमिकता अंक',
      'vulnerable_groups': 'संवेदनशील समूह उपस्थित',
      'duplicate_warning': 'संभावित डुप्लिकेट रिपोर्ट मिली',
      'confirm_duplicate': 'मानवीय सत्यापन आवश्यक',
      'not_verified_safe': 'अपुष्ट असुरक्षित मार्ग',
      'voice_note': 'वॉयस नोट (वैकल्पिक)',
      'submit_report': 'आपातकालीन रिपोर्ट भेजें',
      'reference_id': 'संदर्भ संख्या (ID)',
      'search_ref': 'संदर्भ संख्या खोजें (उदा. RQ-901)',
      'safety_disclaimer': 'ResQAI एक निर्णय सहायता प्रणाली है और यह 112 आपातकालीन सेवाओं का विकल्प नहीं है।',
      'notifications': 'सूचनाएं और चेतावनियां',
      'received': 'प्राप्त',
      'sent': 'भेजी गई',
      'unread': 'अपठित',
      'all': 'सभी',
      'critical': 'अति-गंभीर',
      'mark_all_read': 'सभी पढ़ी गई चिन्हित करें',
      'donate_relief': 'राहत सहायता दान करें',
      'browse_campaigns': 'अभियान देखें',
      'find_shelter': 'आश्रय स्थल खोजें',
      'request_aid': 'सहायता अनुरोध करें',
      'check_updates': 'अपडेट जांचें',
      'options': 'विकल्प',
      'settings': 'सेटिंग्स',
      'profile': 'प्रोफाइल सेटिंग्स',
      'sign_out': 'लॉग आउट',
    }
  };

  static String text(String key, String lang) {
    return _strings[lang]?[key] ?? _strings['en']?[key] ?? key;
  }
}

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super(_loadInitialLanguage());

  static String _loadInitialLanguage() {
    try {
      final saved = StorageService.getString(StorageService.keyLanguage);
      if (saved != null && (saved == 'en' || saved == 'hi')) {
        return saved;
      }
    } catch (_) {}
    return 'en';
  }

  void setLanguage(String lang) {
    state = lang;
    try {
      StorageService.setString(StorageService.keyLanguage, lang);
    } catch (_) {}
  }

  void toggleLanguage() {
    final next = state == 'en' ? 'hi' : 'en';
    setLanguage(next);
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

final currentLanguageTextProvider = Provider.family<String, String>((ref, key) {
  final lang = ref.watch(languageProvider);
  return I18nService.text(key, lang);
});
