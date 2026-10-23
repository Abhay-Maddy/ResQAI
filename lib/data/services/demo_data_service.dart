import '../../core/constants/app_constants.dart';
import '../../shared/models/incident_model.dart';
import '../../shared/models/alert_model.dart';
import '../../shared/models/shelter_model.dart';
import '../../shared/models/volunteer_model.dart';
import '../../shared/models/rumor_model.dart';
import '../../shared/models/sitrep_model.dart';

class DemoDataService {
  static List<IncidentModel> getInitialIncidents() {
    return [
      IncidentModel(
        id: 'RQ-101',
        title: 'Severe Waterlogging at Sector 4 Lowlands',
        descriptionOriginal: 'बाढ़ का पानी 2 मीटर तक बढ़ गया है। 15 लोग छत पर फंसे हैं, जिनमें 3 छोटे बच्चे हैं।',
        descriptionTranslated: 'Flood water has risen to 2 meters. 15 people trapped on rooftop, including 3 young children.',
        originalLanguage: 'hi',
        category: IncidentCategory.flood,
        latitude: 28.6139,
        longitude: 77.2090,
        address: 'Sector 4, Yamuna Riverside Block, Delhi NCR',
        status: IncidentStatus.verified,
        priorityScore: 92.5,
        priorityExplanation: 'High casualty risk: 15 trapped + 3 children detected + water level 2.0m > 1.5m threshold.',
        vulnerableGroups: ['Children (3)', 'Elderly (2)'],
        hasVoiceNote: true,
        source: 'CITIZEN_WEB',
        reporterPhoneMasked: '+91 98*** **412',
        reportedAt: DateTime.now().subtract(const Duration(minutes: 42)),
        assignedTeam: 'NDRF Team Bravo-3',
      ),
      IncidentModel(
        id: 'RQ-102',
        title: 'Yamuna Flood Water Entering Homes Sector 4',
        descriptionOriginal: 'Flooding in Sector 4 near river bank, family stuck on roof please send boat.',
        descriptionTranslated: 'Flooding in Sector 4 near river bank, family stuck on roof please send boat.',
        originalLanguage: 'en',
        category: IncidentCategory.flood,
        latitude: 28.6145,
        longitude: 77.2098,
        address: 'Yamuna Ghat Lane, Sector 4, Delhi NCR',
        status: IncidentStatus.underReview,
        priorityScore: 88.0,
        priorityExplanation: 'Proximity match with RQ-101 (85m distance, same category, same time window).',
        vulnerableGroups: ['Children'],
        source: 'SMS_GATEWAY',
        reporterPhoneMasked: '+91 91*** **890',
        reportedAt: DateTime.now().subtract(const Duration(minutes: 35)),
        isPossibleDuplicate: true,
        duplicateOfId: 'RQ-101',
        duplicateConfidence: 0.89,
      ),
      IncidentModel(
        id: 'RQ-103',
        title: 'Bridge Approach Collapsed on Highway 24',
        descriptionOriginal: 'Highway 24 culvert washed away by heavy storm runoff. Road completely impassable.',
        descriptionTranslated: 'Highway 24 culvert washed away by heavy storm runoff. Road completely impassable.',
        originalLanguage: 'en',
        category: IncidentCategory.landslide,
        latitude: 28.6250,
        longitude: 77.2200,
        address: 'National Highway 24 Km Marker 14, East Corridor',
        status: IncidentStatus.helpAssigned,
        priorityScore: 78.0,
        priorityExplanation: 'Critical transportation lifeline blocked. Detour required for emergency ambulances.',
        vulnerableGroups: [],
        source: '112_DISPATCH',
        reporterPhoneMasked: '+91 88*** **115',
        reportedAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 10)),
        assignedTeam: 'PWD Quick Clearance Unit',
      ),
      IncidentModel(
        id: 'RQ-104',
        title: 'Hospital Power Failure with Critical Oxygen Need',
        descriptionOriginal: 'District Sub-Hospital generator flooded. 8 patients on oxygen cylinders require evacuation or diesel pump.',
        descriptionTranslated: 'District Sub-Hospital generator flooded. 8 patients on oxygen cylinders require evacuation or diesel pump.',
        originalLanguage: 'en',
        category: IncidentCategory.medical,
        latitude: 28.6320,
        longitude: 77.2150,
        address: 'Community Health Center, Block C, Mayur Vihar',
        status: IncidentStatus.received,
        priorityScore: 98.0,
        priorityExplanation: 'Life support failure risk: Hospital facility flag raised. Immediate generator fuel / dispatch required.',
        vulnerableGroups: ['Hospital Patients (8)', 'Medical Equipment'],
        source: 'WHATSAPP',
        reporterPhoneMasked: '+91 99*** **773',
        reportedAt: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
    ];
  }

  static List<AlertModel> getOfficialAlerts() {
    return [
      AlertModel(
        id: 'ALT-IMD-01',
        agency: AlertAgency.imd,
        headline: 'Flash Flood & Extremely Heavy Rainfall Warning (Red Alert)',
        description: 'Active monsoon trough causing localized precipitation exceeding 160mm/24h in Yamuna catchment basin. Low-lying riverbanks advised to evacuate immediately.',
        severity: AlertSeverity.red,
        affectedRegion: 'Yamuna River Basin & East Delhi Plains',
        issuedAt: DateTime.now().subtract(const Duration(hours: 3)),
        lastFetchedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      AlertModel(
        id: 'ALT-NDMA-02',
        agency: AlertAgency.ndma,
        headline: 'NDMA Directive: Pre-Deployment of 6 NDRF Battalions',
        description: 'Civil defence units placed on highest alert. Emergency shelters in Sectors 2, 4, and 9 activated with dry rations and medical kits.',
        severity: AlertSeverity.orange,
        affectedRegion: 'National Capital Region & Downstream Districts',
        issuedAt: DateTime.now().subtract(const Duration(hours: 6)),
        lastFetchedAt: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
      AlertModel(
        id: 'ALT-GDACS-03',
        agency: AlertAgency.gdacs,
        headline: 'GDACS Severe Meteorological Hazard Assessment',
        description: 'Satellite precipitation radar indicates cloudburst pattern persisting for next 18 hours across northern sub-basin.',
        severity: AlertSeverity.yellow,
        affectedRegion: 'Northern Regional Drainage System',
        issuedAt: DateTime.now().subtract(const Duration(hours: 12)),
        lastFetchedAt: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
    ];
  }

  static List<ShelterModel> getShelters() {
    return [
      ShelterModel(
        id: 'SH-01',
        name: 'Government Model Senior Secondary School Shelter',
        address: 'Plot 12, Main Road, Mayur Vihar Phase 1',
        latitude: 28.6080,
        longitude: 77.2950,
        totalCapacity: 450,
        occupiedBeds: 310,
        waterLitersStock: 4800,
        foodMealsStock: 1200,
        hasMedicalUnit: true,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 15)),
        isCapacityStale: false,
      ),
      ShelterModel(
        id: 'SH-02',
        name: 'Community Center Relief Camp Sector 9',
        address: 'Sector 9 Civic Center Grounds, Rohini',
        latitude: 28.7150,
        longitude: 77.1210,
        totalCapacity: 300,
        occupiedBeds: 285,
        waterLitersStock: 950,
        foodMealsStock: 220,
        hasMedicalUnit: false,
        lastUpdated: DateTime.now().subtract(const Duration(hours: 5)),
        isCapacityStale: true, // Warns that capacity update is older than 4 hours
      ),
      ShelterModel(
        id: 'SH-03',
        name: 'Indoor Sports Stadium Emergency Evacuation Point',
        address: 'East Sports Enclave, Akshardham Extension',
        latitude: 28.6180,
        longitude: 77.2790,
        totalCapacity: 800,
        occupiedBeds: 140,
        waterLitersStock: 9500,
        foodMealsStock: 3500,
        hasMedicalUnit: true,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 25)),
        isCapacityStale: false,
      ),
      ShelterModel(
        id: 'SH-GZB-01',
        name: 'Kaushambi Community Center Shelter',
        address: 'Sector 14 Kaushambi, Near Metro Station, Ghaziabad',
        latitude: 28.6320,
        longitude: 77.3200,
        totalCapacity: 500,
        occupiedBeds: 280,
        waterLitersStock: 6000,
        foodMealsStock: 2200,
        hasMedicalUnit: true,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 10)),
        isCapacityStale: false,
      ),
      ShelterModel(
        id: 'SH-GZB-02',
        name: 'Vaishali Sector 4 Relief Camp',
        address: 'Vaishali Sector 4 Civic Center, Ghaziabad',
        latitude: 28.6480,
        longitude: 77.3380,
        totalCapacity: 350,
        occupiedBeds: 195,
        waterLitersStock: 4200,
        foodMealsStock: 1600,
        hasMedicalUnit: true,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 20)),
        isCapacityStale: false,
      ),
      ShelterModel(
        id: 'SH-GZB-03',
        name: 'Vasundhara Safe Haven Relief Point',
        address: 'Sector 16 Vasundhara High Grounds, Ghaziabad',
        latitude: 28.6620,
        longitude: 77.3550,
        totalCapacity: 600,
        occupiedBeds: 210,
        waterLitersStock: 7500,
        foodMealsStock: 2800,
        hasMedicalUnit: true,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 30)),
        isCapacityStale: false,
      ),
      ShelterModel(
        id: 'SH-GZB-04',
        name: 'Indirapuram Public School Safe Shelter',
        address: 'Ahinsa Khand 2, Indirapuram, Ghaziabad',
        latitude: 28.6420,
        longitude: 77.3800,
        totalCapacity: 450,
        occupiedBeds: 180,
        waterLitersStock: 5000,
        foodMealsStock: 1900,
        hasMedicalUnit: false,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 45)),
        isCapacityStale: false,
      ),
    ];
  }

  static List<VolunteerModel> getVolunteers() {
    return [
      VolunteerModel(
        id: 'VOL-01',
        name: 'Dr. Priya Sharma',
        phoneMasked: '+91 98*** **321',
        skills: ['Medical / First Aid', 'Translation (Hindi/English)'],
        latitude: 28.6150,
        longitude: 77.2100,
        district: 'Central District',
        isAvailable: true,
      ),
      VolunteerModel(
        id: 'VOL-02',
        name: 'Harpreet Singh',
        phoneMasked: '+91 97*** **654',
        skills: ['Boating / Water Rescue', 'Chainsaw & Debris Clearance'],
        latitude: 28.6180,
        longitude: 77.2180,
        district: 'Yamuna Riverbank Zone',
        isAvailable: true,
      ),
      VolunteerModel(
        id: 'VOL-03',
        name: 'Amit Patel',
        phoneMasked: '+91 94*** **998',
        skills: ['Cooking & Rations Distribution', 'Logistics Driving'],
        latitude: 28.6290,
        longitude: 77.2250,
        district: 'East District',
        isAvailable: false,
        matchedIncidentId: 'RQ-103',
      ),
    ];
  }

  static List<RumorModel> getRumors() {
    return [
      RumorModel(
        id: 'RUM-01',
        claimText: 'Wazirabad Barrage gates broken and entire old city will be under 15 feet water in 2 hours.',
        sourceChannel: 'WhatsApp Viral Forward / Audio Clip',
        reportedRegion: 'Old Delhi & Civil Lines',
        reportsCount: 42,
        status: RumorStatus.debunked,
        officialFactCheck: 'DEBUNKED BY IRRIGATION & FLOOD CONTROL DEPT: All 18 barrage gates are fully operational. Controlled discharge of 1.2 lakh cusecs is normal and under monitoring.',
        firstReported: DateTime.now().subtract(const Duration(hours: 4)),
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      RumorModel(
        id: 'RUM-02',
        claimText: 'Drinking water pipeline in Sector 4 contaminated with flood sewage.',
        sourceChannel: 'Twitter / Telegram Group',
        reportedRegion: 'Sector 4',
        reportsCount: 16,
        status: RumorStatus.investigating,
        officialFactCheck: 'FIELD VERIFICATION IN PROGRESS: Delhi Jal Board mobile testing lab dispatched to Sector 4 booster pumping station. Chlorination tablets distributed as precaution.',
        firstReported: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
    ];
  }

  static SitRepModel getLatestSitRep() {
    return SitRepModel(
      id: 'SITREP-2026-10-22-01',
      title: 'Monsoon Surge Situation Report #04',
      generatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      operationalSummary: 'Intense precipitation in Yamuna upper catchment has led to localized flooding in 4 low-lying sectors. 4 primary emergency incidents active, with 1 confirmed duplicate candidate identified by AI triage. Shelter capacity remains healthy at 54% aggregate availability. No fatalities reported. 1 road blockage on NH-24 marked as NOT VERIFIED SAFE route.',
      totalIncidentsReported: 4,
      verifiedIncidents: 2,
      resolvedIncidents: 1,
      activeFieldTeams: 8,
      peopleSheltered: 735,
      criticalUncertainties: [
        'Water intake pipe contamination in Sector 4 pending lab confirmation.',
        'Rainfall intensity forecast between 02:00 and 06:00 IST could impact culvert repairs on NH-24.'
      ],
      priorityDistribution: {
        'Critical (80-100)': 2,
        'High (60-79)': 1,
        'Medium (40-59)': 1,
        'Low (<40)': 0,
      },
    );
  }

  // Silent Zone Detection Data (Drop in reporting volume relative to historical baseline)
  static Map<String, dynamic> getSilentZoneAnalytics() {
    return {
      'monitoredArea': 'Sector 12 & Floodplain Lowlands',
      'baselineHourlyReports': 14.2, // Expected normal hourly reports during active disaster
      'currentHourlyReports': 0.8, // Current reporting count
      'dropPercentage': 94.3,
      'isBlackoutSuspected': true,
      'explanation': 'Unusual 94.3% drop in report frequency detected over the past 90 minutes. Cell tower battery backup failure suspected. Do NOT treat silence as proof of safety.',
      'lastReportTime': DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
      'recommendedAction': 'Dispatch satellite communication reconnaissance team to survey Sector 12.',
    };
  }

  // Family Preparedness Kits Checklist
  static List<Map<String, dynamic>> getPreparednessChecklists() {
    return [
      {
        'category': 'Emergency Go-Bag (First 72 Hours)',
        'items': [
          {'name': 'Bottled Drinking Water (3 liters per person/day)', 'checked': true},
          {'name': 'Non-perishable ready-to-eat dry rations / energy bars', 'checked': true},
          {'name': 'Waterproof pouch with Aadhaar, ration card, insurance papers', 'checked': true},
          {'name': 'Battery-operated flashlight with spare cells', 'checked': false},
          {'name': 'Power bank charged to 100% with charging cables', 'checked': false},
          {'name': 'First-aid kit (bandages, antiseptic, ORS sachets, personal Rx)', 'checked': false},
          {'name': 'Whistle to signal emergency rescue teams in dark/water', 'checked': false},
        ]
      },
      {
        'category': 'Flood & Cyclone Evacuation Checklist',
        'items': [
          {'name': 'Turn off main electrical breaker switch before water enters home', 'checked': false},
          {'name': 'Shut off LPG cylinder regulator valve', 'checked': false},
          {'name': 'Move medicines, documents, and infant supplies to top floor', 'checked': false},
          {'name': 'Do not attempt to walk or drive through flowing flood water > 15cm', 'checked': false},
        ]
      }
    ];
  }
}
