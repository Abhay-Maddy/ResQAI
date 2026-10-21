// ResQAI Unified Domain Types — strictly aligned with PRD Part G & Part L Item 4

export type RoleType = 
  | 'CITIZEN' 
  | 'ADMIN' 
  | 'GOVT_OFFICER' 
  | 'RESPONDER' 
  | 'NGO' 
  | 'DONOR' 
  | 'AUDITOR';

export type IncidentCategory = 
  | 'FLOOD' 
  | 'CYCLONE' 
  | 'LANDSLIDE' 
  | 'HEATWAVE' 
  | 'FIRE' 
  | 'MEDICAL' 
  | 'ANIMAL_LIVESTOCK' 
  | 'OTHER';

export type IncidentStatus = 
  | 'RECEIVED' 
  | 'TRIAGE' 
  | 'UNDER_REVIEW' 
  | 'VERIFIED' 
  | 'UNVERIFIED' 
  | 'DUPLICATE' 
  | 'RESPONSE_ASSIGNED' 
  | 'IN_PROGRESS' 
  | 'RESOLVED' 
  | 'CLOSED' 
  | 'ESCALATED' 
  | 'REJECTED';

export type UrgencyLevel = 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW';

export type ResourceType = 'FOOD' | 'WATER' | 'MEDICINE' | 'SHELTER_KITS' | 'BOATS' | 'PERSONNEL';

export interface User {
  id: string;
  name: string;
  phone?: string;
  email?: string;
  role: RoleType;
  jurisdictionRegionId?: string;
  isVerified: boolean;
  createdAt: string;
}

export interface IncidentReport {
  id: string;
  incidentId?: string;
  sourceType: 'CITIZEN_PWA' | 'SMS_ADAPTER' | 'CALL_112' | 'SOCIAL_MONITOR' | 'SYNTHETIC_DRILL';
  reportedAt: string;
  category: IncidentCategory;
  description: string;
  latitude: number;
  longitude: number;
  locationName: string;
  urgency: UrgencyLevel;
  peopleCount: number;
  contactPhone?: string;
  isAnonymous: boolean;
  mediaUrls: string[];
  idempotencyKey?: string;
  isPendingSync?: boolean;
}

export interface Verification {
  id: string;
  incidentId: string;
  reviewerId: string;
  reviewerName: string;
  decision: 'VERIFIED' | 'UNVERIFIED' | 'DUPLICATE';
  timestamp: string;
  reason: string;
  evidenceRefs: string[];
  confidence: number;
  unresolvedUncertainty?: string;
  mergedIntoIncidentId?: string;
}

export interface Incident {
  id: string;
  title: string;
  category: IncidentCategory;
  status: IncidentStatus;
  urgency: UrgencyLevel;
  priorityScore: number;
  whyPriorityExplanation?: string;
  latitude: number;
  longitude: number;
  locationName: string;
  areaId: string;
  peopleAffected: number;
  reportedAt: string;
  lastUpdatedAt: string;
  slaDeadlineMinutes: number;
  isSimulatedDrill: boolean;
  reports: IncidentReport[];
  verifications: Verification[];
  assignedTeamId?: string;
}

export interface RescueTeam {
  id: string;
  name: string;
  type: 'NDRF' | 'SDRF' | 'CIVIL_DEFENSE' | 'COMMUNITY_VOLUNTEER';
  status: 'IDLE' | 'ASSIGNED' | 'EN_ROUTE' | 'ON_SCENE' | 'RESOLVING' | 'RESTING';
  assignedIncidentId?: string;
  latitude: number;
  longitude: number;
  capacity: number;
  skills: string[];
  contactNumber: string;
  jurisdictionArea: string;
}

export interface Assignment {
  id: string;
  incidentId: string;
  teamId: string;
  assignedAt: string;
  acknowledgedAt?: string;
  arrivedAtSceneAt?: string;
  resolvedAt?: string;
  status: 'ASSIGNED' | 'ACCEPTED' | 'EN_ROUTE' | 'ON_SCENE' | 'RESOLVED' | 'DECLINED';
  notes?: string;
  escalatedToSupervisor: boolean;
}

export interface AffectedArea {
  id: string;
  name: string;
  district: string;
  state: string;
  latitude: number;
  longitude: number;
  polygonGeoJson?: any;
  needs: Record<ResourceType, {
    required: number;
    available: number;
    reserved: number;
    dispatched: number;
    delivered: number;
    pending: number;
    lastVerified: string;
  }>;
}

export interface OfficialAlert {
  id: string;
  source: 'IMD' | 'CWC' | 'NDMA_SACHET' | 'STATE_SDMA';
  title: string;
  description: string;
  severity: 'CRITICAL' | 'WARN' | 'INFO';
  affectedRegion: string;
  issuedAt: string;
  validUntil: string;
  capFeedId?: string;
}

export interface HazardPrediction {
  id: string;
  hazardType: 'FLOOD' | 'HEAVY_RAIN' | 'HEATWAVE' | 'CYCLONE_EXPOSURE';
  regionId: string;
  regionName: string;
  timeWindowHours: number;
  riskLevel: 'CRITICAL' | 'HIGH' | 'MODERATE' | 'LOW';
  calibratedProbability: number;
  uncertaintyInterval: [number, number];
  topShapFactors: { factor: string; contribution: number }[];
  dataFreshnessTimestamp: string;
  modelVersion: string;
  isAvailable: boolean;
  unavailableReason?: string;
}

// PRD Part L Item 4 Specific Tables:
export interface RumourReport {
  id: string;
  reportedClaim: string;
  sourcePlatform: string;
  counterVerificationStatus: 'DEBUNKED' | 'OFFICIALLY_CONFIRMED' | 'INVESTIGATING';
  officialCorrectionNotice?: string;
  timestamp: string;
}

export interface RoadClosure {
  id: string;
  roadName: string;
  areaId: string;
  cause: 'FLOODING' | 'LANDSLIDE' | 'BRIDGE_DAMAGE';
  startCoordinates: [number, number];
  endCoordinates: [number, number];
  isPassableForEmergency: boolean;
  reportedAt: string;
}

export interface EvacuationZone {
  id: string;
  zoneName: string;
  areaId: string;
  urgencyLevel: UrgencyLevel;
  safeShelterIds: string[];
  evacuationRoutesNotes: string;
  pickUpPointsForElderlyDisabled: string[];
  activeStatus: 'STANDBY' | 'EVACUATION_ORDERED' | 'ALL_CLEAR';
}

export interface MissingPersonRecord {
  id: string;
  fullName: string;
  age: number;
  gender: string;
  lastKnownLocation: string;
  lastSeenTime: string;
  reportedByUserId: string;
  status: 'SEARCHING' | 'FOUND_SAFE' | 'AT_SHELTER' | 'HOSPITALIZED';
  shelterId?: string;
  isChild: boolean;
  childProtectionConsentVerified: boolean;
}

export interface DrillSession {
  id: string;
  drillName: string;
  scenarioType: 'URBAN_FLASH_FLOOD' | 'CATEGORY_4_CYCLONE';
  startedAt: string;
  endedAt?: string;
  status: 'ACTIVE' | 'CONCLUDED';
  isWatermarkedSynthetic: true;
  totalSyntheticIncidents: number;
}

export interface ConsentRecord {
  id: string;
  userId?: string;
  incidentId?: string;
  purpose: 'EMERGENCY_RESCUE' | 'DONATION_FCRA' | 'MEDICAL_LOG' | 'SHELTER_REGISTRATION';
  dpdpConsentCaptured: boolean;
  timestamp: string;
  ipHash?: string;
}

export interface AuditLog {
  id: string;
  actionType: 'VERIFICATION' | 'ASSIGNMENT' | 'ALLOCATION' | 'DONATION_PAYOUT' | 'DATA_EXPORT';
  actorId: string;
  actorRole: RoleType;
  entityId: string;
  timestamp: string;
  details: string;
  beforeStateJson?: string;
  afterStateJson?: string;
}
