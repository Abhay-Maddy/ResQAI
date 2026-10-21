import { AffectedArea, Incident, OfficialAlert, HazardPrediction, RescueTeam, DrillSession } from '../types';

// Seed scenario implementing PRD Part E6 worked example & synthetic demo data
export const SEED_AREAS: AffectedArea[] = [
  {
    id: 'area-a',
    name: 'Sector A (North River Basin)',
    district: 'Patna',
    state: 'Bihar',
    latitude: 25.612,
    longitude: 85.144,
    needs: {
      FOOD: {
        required: 500,
        available: 500,
        reserved: 50,
        dispatched: 350,
        delivered: 100,
        pending: 0,
        lastVerified: '10 mins ago'
      }, // 100% covered!
      WATER: {
        required: 1000,
        available: 800,
        reserved: 100,
        dispatched: 500,
        delivered: 200,
        pending: 200,
        lastVerified: '15 mins ago'
      }, // 80% covered
      MEDICINE: {
        required: 300,
        available: 60,
        reserved: 10,
        dispatched: 30,
        delivered: 20,
        pending: 240,
        lastVerified: '5 mins ago'
      }, // 20% covered - URGENT SHORTAGE
      SHELTER_KITS: {
        required: 150,
        available: 130,
        reserved: 20,
        dispatched: 80,
        delivered: 30,
        pending: 20,
        lastVerified: '20 mins ago'
      },
      BOATS: {
        required: 6,
        available: 6,
        reserved: 1,
        dispatched: 4,
        delivered: 1,
        pending: 0,
        lastVerified: '12 mins ago'
      },
      PERSONNEL: {
        required: 40,
        available: 35,
        reserved: 5,
        dispatched: 25,
        delivered: 5,
        pending: 5,
        lastVerified: '8 mins ago'
      }
    }
  },
  {
    id: 'area-b',
    name: 'Sector B (Lowland Colony)',
    district: 'Patna',
    state: 'Bihar',
    latitude: 25.594,
    longitude: 85.122,
    needs: {
      FOOD: {
        required: 400,
        available: 160,
        reserved: 20,
        dispatched: 100,
        delivered: 40,
        pending: 240,
        lastVerified: '25 mins ago'
      }, // 40% covered
      WATER: {
        required: 800,
        available: 0,
        reserved: 0,
        dispatched: 0,
        delivered: 0,
        pending: 800,
        lastVerified: '3 mins ago'
      }, // 0% covered - CRITICAL WATER SHORTAGE
      MEDICINE: {
        required: 200,
        available: 120,
        reserved: 15,
        dispatched: 80,
        delivered: 25,
        pending: 80,
        lastVerified: '18 mins ago'
      }, // 60% covered
      SHELTER_KITS: {
        required: 100,
        available: 50,
        reserved: 10,
        dispatched: 30,
        delivered: 10,
        pending: 50,
        lastVerified: '30 mins ago'
      },
      BOATS: {
        required: 8,
        available: 2,
        reserved: 0,
        dispatched: 2,
        delivered: 0,
        pending: 6,
        lastVerified: '5 mins ago'
      },
      PERSONNEL: {
        required: 30,
        available: 15,
        reserved: 2,
        dispatched: 10,
        delivered: 3,
        pending: 15,
        lastVerified: '15 mins ago'
      }
    }
  },
  {
    id: 'area-c',
    name: 'Sector C (Elevated Ridge)',
    district: 'Patna',
    state: 'Bihar',
    latitude: 25.628,
    longitude: 85.168,
    needs: {
      FOOD: {
        required: 200,
        available: 190,
        reserved: 20,
        dispatched: 140,
        delivered: 30,
        pending: 10,
        lastVerified: '1 hour ago'
      }, // 95% covered
      WATER: {
        required: 500,
        available: 450,
        reserved: 50,
        dispatched: 350,
        delivered: 50,
        pending: 50,
        lastVerified: '45 mins ago'
      }, // 90% covered
      MEDICINE: {
        required: 100,
        available: 90,
        reserved: 10,
        dispatched: 70,
        delivered: 10,
        pending: 10,
        lastVerified: '35 mins ago'
      }, // 90% covered - Monitor Only
      SHELTER_KITS: {
        required: 50,
        available: 48,
        reserved: 5,
        dispatched: 35,
        delivered: 8,
        pending: 2,
        lastVerified: '1 hour ago'
      },
      BOATS: {
        required: 2,
        available: 2,
        reserved: 0,
        dispatched: 2,
        delivered: 0,
        pending: 0,
        lastVerified: '1 hour ago'
      },
      PERSONNEL: {
        required: 15,
        available: 15,
        reserved: 2,
        dispatched: 12,
        delivered: 1,
        pending: 0,
        lastVerified: '1 hour ago'
      }
    }
  }
];

export const SEED_INCIDENTS: Incident[] = [
  {
    id: 'INC-2026-001',
    title: 'Severe Waterlogging with 14 Families Stranded on Rooftops',
    category: 'FLOOD',
    status: 'TRIAGE',
    urgency: 'CRITICAL',
    priorityScore: 94,
    whyPriorityExplanation: 'Threat to life (9/10), 14 elderly/children trapped without drinking water, rising river gauge (+0.4m/hr).',
    latitude: 25.6135,
    longitude: 85.1425,
    locationName: 'Ward 12, Near Hanuman Mandir Ghat, Sector A',
    areaId: 'area-a',
    peopleAffected: 58,
    reportedAt: '12 minutes ago',
    lastUpdatedAt: 'Just now',
    slaDeadlineMinutes: 18,
    isSimulatedDrill: false,
    reports: [
      {
        id: 'REP-01',
        sourceType: 'CITIZEN_PWA',
        reportedAt: '12 minutes ago',
        category: 'FLOOD',
        description: 'Water has reached the 1st floor balcony. Need emergency boat rescue for 14 families including 3 infants.',
        latitude: 25.6135,
        longitude: 85.1425,
        locationName: 'Ward 12 Ghat Road',
        urgency: 'CRITICAL',
        peopleCount: 58,
        contactPhone: '+91 98765 43210',
        isAnonymous: false,
        mediaUrls: []
      }
    ],
    verifications: []
  },
  {
    id: 'INC-2026-002',
    title: 'Drinking Water Pipeline Contamination & Depletion',
    category: 'FLOOD',
    status: 'VERIFIED',
    urgency: 'HIGH',
    priorityScore: 82,
    whyPriorityExplanation: 'Zero clean water reported in Sector B lowland camp. High risk of waterborne illness.',
    latitude: 25.5942,
    longitude: 85.1235,
    locationName: 'Community Center Shelter, Sector B',
    areaId: 'area-b',
    peopleAffected: 210,
    reportedAt: '45 minutes ago',
    lastUpdatedAt: '10 minutes ago',
    slaDeadlineMinutes: 40,
    isSimulatedDrill: false,
    reports: [],
    verifications: [
      {
        id: 'VER-01',
        incidentId: 'INC-2026-002',
        reviewerId: 'OFFICER-03',
        reviewerName: 'Inspector Meera',
        decision: 'VERIFIED',
        timestamp: '10 mins ago',
        reason: 'Confirmed by Shelter Manager Rajesh via satellite phone. Tankers required immediately.',
        evidenceRefs: ['DOC-WATER-TEST-01'],
        confidence: 0.95
      }
    ]
  },
  {
    id: 'INC-2026-003',
    title: 'Tree Down Blocking Relief Road Access',
    category: 'LANDSLIDE',
    status: 'UNVERIFIED',
    urgency: 'LOW',
    priorityScore: 38,
    whyPriorityExplanation: 'Alternate route available via Sector C bypass; no casualties reported.',
    latitude: 25.6275,
    longitude: 85.1662,
    locationName: 'Eastern Bypass, Sector C',
    areaId: 'area-c',
    peopleAffected: 0,
    reportedAt: '1 hour ago',
    lastUpdatedAt: '1 hour ago',
    slaDeadlineMinutes: 120,
    isSimulatedDrill: false,
    reports: [],
    verifications: []
  }
];

export const SEED_OFFICIAL_ALERTS: OfficialAlert[] = [
  {
    id: 'ALT-IMD-089',
    source: 'IMD',
    title: 'RED ALERT: Extremely Heavy Rainfall in Ganga Catchment Area',
    description: 'IMD has issued a Red Alert predicting 180mm-240mm localized rainfall over the next 24 hours. Low-lying areas advised to enact evacuation readiness.',
    severity: 'CRITICAL',
    affectedRegion: 'Patna, Vaishali, Saran',
    issuedAt: 'Today, 06:00 IST',
    validUntil: 'Tomorrow, 06:00 IST',
    capFeedId: 'CAP-IN-IMD-2026-1022-01'
  },
  {
    id: 'ALT-CWC-042',
    source: 'CWC',
    title: 'CWC Inflow Warning: River Ganga at Digha Ghat 0.85m Above Danger Level',
    description: 'Central Water Commission hydro-gauge station reports rising trend (+4cm/hr). Embankment patrols activated.',
    severity: 'WARN',
    affectedRegion: 'Patna Urban & Rural',
    issuedAt: 'Today, 07:30 IST',
    validUntil: 'Today, 19:30 IST',
    capFeedId: 'CAP-IN-CWC-2026-1022-04'
  }
];

export const SEED_HAZARD_PREDICTIONS: HazardPrediction[] = [
  {
    id: 'PRED-FL-01',
    hazardType: 'FLOOD',
    regionId: 'area-a',
    regionName: 'Sector A (North River Basin)',
    timeWindowHours: 12,
    riskLevel: 'CRITICAL',
    calibratedProbability: 0.87,
    uncertaintyInterval: [0.81, 0.92],
    topShapFactors: [
      { factor: 'Rainfall 48h Acc. (168mm)', contribution: 0.42 },
      { factor: 'River Inflow Level (CWC Digha +0.85m)', contribution: 0.31 },
      { factor: 'Elevation/Slope (SRTM low gradient)', contribution: 0.14 }
    ],
    dataFreshnessTimestamp: '15 mins ago',
    modelVersion: 'v1.2-xgb-bihar-flood',
    isAvailable: true
  },
  {
    id: 'PRED-FL-02',
    hazardType: 'FLOOD',
    regionId: 'area-b',
    regionName: 'Sector B (Lowland Colony)',
    timeWindowHours: 24,
    riskLevel: 'HIGH',
    calibratedProbability: 0.74,
    uncertaintyInterval: [0.68, 0.80],
    topShapFactors: [
      { factor: 'Drainage Canal Blockage Index', contribution: 0.38 },
      { factor: 'Soil Moisture Saturation (94%)', contribution: 0.28 },
      { factor: 'Forecast Precipitation (95mm)', contribution: 0.20 }
    ],
    dataFreshnessTimestamp: '20 mins ago',
    modelVersion: 'v1.2-xgb-bihar-flood',
    isAvailable: true
  }
];

export const SEED_RESCUE_TEAMS: RescueTeam[] = [
  {
    id: 'TEAM-NDRF-9A',
    name: 'NDRF 9th Battalion - Team Bravo',
    type: 'NDRF',
    status: 'IDLE',
    latitude: 25.6110,
    longitude: 85.1410,
    capacity: 25,
    skills: ['DEEP_WATER_RESCUE', 'INFLATABLE_BOATS', 'PARAMEDIC'],
    contactNumber: '+91 94310 11222',
    jurisdictionArea: 'Sector A & Ganga North'
  },
  {
    id: 'TEAM-SDRF-04',
    name: 'SDRF Quick Response Unit 4',
    type: 'SDRF',
    status: 'ASSIGNED',
    assignedIncidentId: 'INC-2026-002',
    latitude: 25.5960,
    longitude: 85.1210,
    capacity: 18,
    skills: ['WATER_LOGISTICS', 'FIRST_AID', 'CAMP_MANAGEMENT'],
    contactNumber: '+91 94310 33444',
    jurisdictionArea: 'Sector B Lowlands'
  }
];

export const SEED_DRILL: DrillSession = {
  id: 'DRILL-2026-DEMO',
  drillName: 'Operation Jal-Suraksha 2026 (Simulated)',
  scenarioType: 'URBAN_FLASH_FLOOD',
  startedAt: '2026-10-22T08:00:00Z',
  status: 'ACTIVE',
  isWatermarkedSynthetic: true,
  totalSyntheticIncidents: 12
};
