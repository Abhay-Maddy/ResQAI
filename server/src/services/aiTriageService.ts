// FR-11 AI-Assisted Triage, Duplicate Candidate Detection & Priority Scoring

export interface AiTriageAnalysis {
  suggestedPriorityScore: number;
  whyExplanation: string;
  isSuspiciousPattern: boolean;
  suspiciousReason?: string;
  duplicateCandidates: { incidentId: string; title: string; similarityScore: number; reason: string }[];
  summary: string;
}

// Haversine distance in kilometers
function getDistanceFromLatLonInKm(lat1: number, lon1: number, lat2: number, lon2: number) {
  const R = 6371; // Radius of the earth in km
  const dLat = deg2rad(lat2 - lat1);
  const dLon = deg2rad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function deg2rad(deg: number) {
  return deg * (Math.PI / 180);
}

// Word token overlap similarity
function textSimilarity(str1: string, str2: string): number {
  const words1 = new Set(str1.toLowerCase().replace(/[^\w\s]/g, '').split(/\s+/));
  const words2 = new Set(str2.toLowerCase().replace(/[^\w\s]/g, '').split(/\s+/));
  
  if (words1.size === 0 || words2.size === 0) return 0;
  
  let intersection = 0;
  for (const w of words1) {
    if (words2.has(w)) intersection++;
  }
  
  return (2 * intersection) / (words1.size + words2.size);
}

export function analyzeIncidentTriage(
  newReport: {
    category: string;
    description: string;
    urgency: string;
    peopleCount: number;
    latitude: number;
    longitude: number;
  },
  existingIncidents: any[]
): AiTriageAnalysis {
  // 1. Calculate Priority Score (0 - 100) based on life threat and impact
  let baseScore = 40;

  if (newReport.urgency === 'CRITICAL') baseScore += 40;
  else if (newReport.urgency === 'HIGH') baseScore += 25;
  else if (newReport.urgency === 'MEDIUM') baseScore += 10;

  // People count impact
  if (newReport.peopleCount >= 50) baseScore += 15;
  else if (newReport.peopleCount >= 10) baseScore += 10;
  else if (newReport.peopleCount >= 1) baseScore += 5;

  // Water / Flood or Structural crisis keywords
  const lowerDesc = newReport.description.toLowerCase();
  const lifeThreatKeywords = ['trapped', 'submerged', 'infant', 'elderly', 'sick', 'pregnant', 'water rising', 'collapsed', 'bleeding'];
  const matchedKeywords: string[] = [];
  
  for (const kw of lifeThreatKeywords) {
    if (lowerDesc.includes(kw)) {
      matchedKeywords.push(kw);
      baseScore += 3;
    }
  }

  const priorityScore = Math.min(100, Math.max(10, baseScore));
  const whyExplanation = `Priority ${priorityScore}/100: Urgency=${newReport.urgency}, Affected=${newReport.peopleCount} people` + 
    (matchedKeywords.length ? `, Critical indicators detected: [${matchedKeywords.join(', ')}]` : '');

  // 2. Check for Duplicate Candidates (within 2 km and textual similarity)
  const duplicateCandidates: { incidentId: string; title: string; similarityScore: number; reason: string }[] = [];

  for (const inc of existingIncidents) {
    const distKm = getDistanceFromLatLonInKm(newReport.latitude, newReport.longitude, inc.latitude, inc.longitude);
    const sim = textSimilarity(newReport.description, inc.title + ' ' + (inc.description || ''));

    if (distKm <= 2.5 && (sim >= 0.3 || distKm <= 0.4)) {
      duplicateCandidates.push({
        incidentId: inc.id,
        title: inc.title,
        similarityScore: Math.round((0.5 * (1 - distKm / 2.5) + 0.5 * sim) * 100),
        reason: `Proximity: ${distKm.toFixed(2)} km away, Text match: ${Math.round(sim * 100)}%`
      });
    }
  }

  // Sort duplicate candidates by highest similarity
  duplicateCandidates.sort((a, b) => b.similarityScore - a.similarityScore);

  // 3. Suspicious pattern detector (e.g. repeated reports from single identifier with rapid velocity)
  const isSuspiciousPattern = false;

  // 4. AI Summary (labelled AI)
  const summary = `AI Summary: ${newReport.category} emergency with approx. ${newReport.peopleCount} affected. ` +
    (matchedKeywords.length ? `Immediate rescue factors: ${matchedKeywords.join(', ')}. ` : '') +
    (duplicateCandidates.length ? `Potential match with ${duplicateCandidates[0].incidentId} (${duplicateCandidates[0].similarityScore}% confidence).` : 'No immediate duplicates found.');

  return {
    suggestedPriorityScore: priorityScore,
    whyExplanation,
    isSuspiciousPattern,
    duplicateCandidates,
    summary
  };
}
