import React, { useEffect, useRef, useState } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { 
  Layers, 
  Compass, 
  Navigation, 
  X
} from 'lucide-react';
import { TruthBadge } from './TruthBadge';
import './LiveGISMap.css';

interface LayerToggles {
  officialAlerts: boolean;
  verifiedIncidents: boolean;
  unverifiedReports: boolean;
  mlRiskZones: boolean;
  rescueTeams: boolean;
  safeShelters: boolean;
  roadClosures: boolean;
}

export const LiveGISMap: React.FC = () => {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const layerGroupRef = useRef<L.LayerGroup | null>(null);

  const [toggles, setToggles] = useState<LayerToggles>({
    officialAlerts: true,
    verifiedIncidents: true,
    unverifiedReports: true,
    mlRiskZones: true,
    rescueTeams: true,
    safeShelters: true,
    roadClosures: true
  });

  const [gisData, setGisData] = useState<any>(null);
  const [selectedEntity, setSelectedEntity] = useState<any>(null);
  const [radiusFilterKm, setRadiusFilterKm] = useState<number>(15);
  const [safeRouteActive, setSafeRouteActive] = useState<boolean>(false);
  const [routeInfo, setRouteInfo] = useState<any>(null);

  // Initialize Leaflet map
  useEffect(() => {
    if (!mapContainerRef.current) return;

    if (!mapInstanceRef.current) {
      // Center on Patna pilot area (PRD E6)
      const map = L.map(mapContainerRef.current, {
        center: [25.612, 85.144],
        zoom: 13,
        zoomControl: false
      });

      L.control.zoom({ position: 'topright' }).addTo(map);

      // OpenStreetMap dark / tactical tiles
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OpenStreetMap contributors • ResQAI GIS Engine',
        maxZoom: 18
      }).addTo(map);

      const layerGroup = L.layerGroup().addTo(map);
      layerGroupRef.current = layerGroup;
      mapInstanceRef.current = map;
    }

    return () => {
      // Cleanup on unmount if needed
    };
  }, []);

  // Fetch GIS Layers from server
  const loadGisLayers = async () => {
    try {
      const res = await fetch('/api/v1/gis/layers');
      if (res.ok) {
        const data = await res.json();
        setGisData(data.layers);
      }
    } catch {
      // Offline fallback
    }
  };

  useEffect(() => {
    loadGisLayers();
  }, []);

  // Render markers and polygons based on toggles & PRD H2 marker language
  useEffect(() => {
    if (!mapInstanceRef.current || !layerGroupRef.current || !gisData) return;

    const layerGroup = layerGroupRef.current;
    layerGroup.clearLayers();

    // 1. Official Alerts (PRD H2: Square marker)
    if (toggles.officialAlerts && gisData.officialAlerts) {
      gisData.officialAlerts.forEach((alt: any) => {
        const icon = L.divIcon({
          className: 'custom-gis-marker',
          html: `<div class="marker-official-square" title="${alt.title}"><span class="marker-symbol">🛡️</span></div>`,
          iconSize: [28, 28],
          iconAnchor: [14, 14]
        });

        // Near Digha Ghat river station
        const marker = L.marker([25.626, 85.132], { icon });
        marker.on('click', () => {
          setSelectedEntity({ type: 'OFFICIAL_ALERT', data: alt });
        });
        layerGroup.addLayer(marker);
      });
    }

    // 2. ML Hazard Prediction Polygons (FR-24: Hatched polygons/grid cells, never falsely precise points)
    if (toggles.mlRiskZones && gisData.mlPredictions) {
      gisData.mlPredictions.forEach((pred: any) => {
        const polygon = L.polygon(pred.polygonCoordinates, {
          color: '#7C3AED',
          weight: 2,
          dashArray: '6, 6',
          fillColor: '#7C3AED',
          fillOpacity: 0.22
        });

        polygon.on('click', () => {
          setSelectedEntity({ type: 'ML_RISK_ZONE', data: pred });
        });
        layerGroup.addLayer(polygon);
      });
    }

    // 3. Incidents (PRD H2: Verified = Filled Circle, Unverified = Hollow Circle)
    if (gisData.incidents) {
      gisData.incidents.forEach((inc: any) => {
        const isVerified = inc.status === 'VERIFIED' || inc.status === 'RESPONSE_ASSIGNED' || inc.status === 'IN_PROGRESS';
        
        if (isVerified && !toggles.verifiedIncidents) return;
        if (!isVerified && !toggles.unverifiedReports) return;

        const icon = L.divIcon({
          className: 'custom-gis-marker',
          html: isVerified
            ? `<div class="marker-verified-circle" title="${inc.title}"><span class="marker-symbol">⚠️</span></div>`
            : `<div class="marker-unverified-hollow" title="${inc.title}"><span class="marker-symbol">?</span></div>`,
          iconSize: [26, 26],
          iconAnchor: [13, 13]
        });

        const marker = L.marker([inc.latitude, inc.longitude], { icon });
        marker.on('click', () => {
          setSelectedEntity({ type: 'INCIDENT', data: inc });
        });
        layerGroup.addLayer(marker);
      });
    }

    // 4. Rescue Teams (PRD H2: Triangle marker)
    if (toggles.rescueTeams && gisData.teams) {
      gisData.teams.forEach((tm: any) => {
        const icon = L.divIcon({
          className: 'custom-gis-marker',
          html: `<div class="marker-team-triangle" title="${tm.name}"><span class="marker-symbol">🔺</span></div>`,
          iconSize: [28, 28],
          iconAnchor: [14, 14]
        });

        const marker = L.marker([tm.latitude, tm.longitude], { icon });
        marker.on('click', () => {
          setSelectedEntity({ type: 'RESCUE_TEAM', data: tm });
        });
        layerGroup.addLayer(marker);
      });
    }

    // 5. Safe Shelters (PRD H2: House icon)
    if (toggles.safeShelters && gisData.shelters) {
      gisData.shelters.forEach((sh: any) => {
        const icon = L.divIcon({
          className: 'custom-gis-marker',
          html: `<div class="marker-shelter-house" title="${sh.name}"><span class="marker-symbol">⛺</span></div>`,
          iconSize: [26, 26],
          iconAnchor: [13, 13]
        });

        const marker = L.marker([sh.latitude, sh.longitude], { icon });
        marker.on('click', () => {
          setSelectedEntity({ type: 'SHELTER', data: sh });
        });
        layerGroup.addLayer(marker);
      });
    }

    // 6. Road Closures (FR-23: Red striped polyline corridors)
    if (toggles.roadClosures && gisData.roadClosures) {
      gisData.roadClosures.forEach((rc: any) => {
        const line = L.polyline([
          [rc.start_lat, rc.start_lng],
          [rc.end_lat, rc.end_lng]
        ], {
          color: '#DC2626',
          weight: 6,
          dashArray: '8, 8'
        });

        line.on('click', () => {
          setSelectedEntity({ type: 'ROAD_CLOSURE', data: rc });
        });
        layerGroup.addLayer(line);
      });
    }
  }, [toggles, gisData]);

  // Request Safe Route avoiding Road Closures (FR-23)
  const calculateSafeRoute = async () => {
    if (!mapInstanceRef.current || !layerGroupRef.current) return;

    try {
      const res = await fetch('/api/v1/gis/safe-route', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          startLat: 25.6110, // NDRF Base
          startLng: 85.1410,
          endLat: 25.6190,   // Sector A Critical Rooftop
          endLng: 85.1520,
          avoidHazards: true
        })
      });

      if (res.ok) {
        const data = await res.json();
        setRouteInfo(data.safeRoute);
        setSafeRouteActive(true);

        // Draw safe route polyline on map
        const routeLine = L.polyline(data.safeRoute.waypoints, {
          color: '#0F9D8A', // Teal safe color
          weight: 5,
          opacity: 0.9
        });

        layerGroupRef.current.addLayer(routeLine);
        mapInstanceRef.current.fitBounds(routeLine.getBounds(), { padding: [40, 40] });
      }
    } catch {
      // Fallback
    }
  };

  const toggleLayer = (layerKey: keyof LayerToggles) => {
    setToggles(prev => ({ ...prev, [layerKey]: !prev[layerKey] }));
  };

  return (
    <div className="live-gis-container card">
      {/* Map Control Header */}
      <div className="gis-header-bar">
        <div className="gis-title-group">
          <Compass className="gis-header-icon" />
          <div>
            <h3>Live GIS Tactical Map Engine (FR-20 to FR-24)</h3>
            <p>Multi-agency geospatial synchronization with distinct marker shapes, ML risk polygons, and safe road routing.</p>
          </div>
        </div>

        <div className="gis-actions-group">
          <div className="radius-selector">
            <span className="radius-label">Radius Filter:</span>
            <select 
              value={radiusFilterKm} 
              onChange={e => setRadiusFilterKm(Number(e.target.value))}
              className="radius-dropdown"
            >
              <option value={5}>5 km Radius</option>
              <option value={15}>15 km (Sector A & B)</option>
              <option value={30}>30 km (District Wide)</option>
            </select>
          </div>

          <button className="safe-routing-btn" onClick={calculateSafeRoute}>
            <Navigation size={16} />
            <span>Generate Closed-Road Bypass Route</span>
          </button>
        </div>
      </div>

      {/* Main Map Viewport & Panels */}
      <div className="gis-body-layout">
        {/* Left Layer Control Panel (Grouped per PRD H4-5) */}
        <aside className="gis-layer-sidebar">
          <div className="sidebar-group-title">
            <Layers size={14} />
            <span>GEOSPATIAL LAYERS (FR-20)</span>
          </div>

          <div className="layer-toggles-list">
            <label className="layer-checkbox-item">
              <input 
                type="checkbox" 
                checked={toggles.officialAlerts}
                onChange={() => toggleLayer('officialAlerts')}
              />
              <span className="marker-preview shape-square">🛡️</span>
              <span className="layer-title">Official Warnings (IMD/CWC)</span>
            </label>

            <label className="layer-checkbox-item">
              <input 
                type="checkbox" 
                checked={toggles.verifiedIncidents}
                onChange={() => toggleLayer('verifiedIncidents')}
              />
              <span className="marker-preview shape-circle-filled">⚠️</span>
              <span className="layer-title">Verified Incidents</span>
            </label>

            <label className="layer-checkbox-item">
              <input 
                type="checkbox" 
                checked={toggles.unverifiedReports}
                onChange={() => toggleLayer('unverifiedReports')}
              />
              <span className="marker-preview shape-circle-hollow">?</span>
              <span className="layer-title">Unverified Citizen Reports</span>
            </label>

            <label className="layer-checkbox-item">
              <input 
                type="checkbox" 
                checked={toggles.mlRiskZones}
                onChange={() => toggleLayer('mlRiskZones')}
              />
              <span className="marker-preview shape-polygon-dashed">🟣</span>
              <span className="layer-title">ML Flood Risk Polygons</span>
            </label>

            <label className="layer-checkbox-item">
              <input 
                type="checkbox" 
                checked={toggles.rescueTeams}
                onChange={() => toggleLayer('rescueTeams')}
              />
              <span className="marker-preview shape-triangle">🔺</span>
              <span className="layer-title">NDRF / SDRF Rescue Teams</span>
            </label>

            <label className="layer-checkbox-item">
              <input 
                type="checkbox" 
                checked={toggles.safeShelters}
                onChange={() => toggleLayer('safeShelters')}
              />
              <span className="marker-preview shape-house">⛺</span>
              <span className="layer-title">Designated Safe Shelters</span>
            </label>

            <label className="layer-checkbox-item">
              <input 
                type="checkbox" 
                checked={toggles.roadClosures}
                onChange={() => toggleLayer('roadClosures')}
              />
              <span className="marker-preview shape-polyline-closed">🚫</span>
              <span className="layer-title">Road Closures & Washouts</span>
            </label>
          </div>

          {/* Safe Route Detour Alert Box */}
          {safeRouteActive && routeInfo && (
            <div className="active-route-box">
              <div className="route-box-header">
                <Navigation size={14} color="var(--color-safe)" />
                <strong>Safe Route Generated (FR-23)</strong>
              </div>
              <p>{routeInfo.detourReason}</p>
              <div className="route-stats">
                <span>Dist: {routeInfo.totalDistanceKm} km</span>
                <span>ETA: ~{routeInfo.estimatedMinutes} mins</span>
              </div>
            </div>
          )}
        </aside>

        {/* Leaflet Map Surface */}
        <div className="leaflet-map-wrapper">
          <div ref={mapContainerRef} className="leaflet-map-viewport" />

          {/* Floating Persistent Legend (Bottom-Left per PRD H4-5 & Part H2) */}
          <div className="persistent-gis-legend">
            <span className="legend-title">MARKER LANGUAGE (PRD H2)</span>
            <div className="legend-items-grid">
              <div className="legend-item">
                <div className="marker-official-square mini">🛡️</div>
                <span>Official (Square)</span>
              </div>
              <div className="legend-item">
                <div className="marker-verified-circle mini">⚠️</div>
                <span>Verified (Filled Circle)</span>
              </div>
              <div className="legend-item">
                <div className="marker-unverified-hollow mini">?</div>
                <span>Unverified (Hollow Circle)</span>
              </div>
              <div className="legend-item">
                <div className="marker-team-triangle mini">🔺</div>
                <span>Rescue Team (Triangle)</span>
              </div>
              <div className="legend-item">
                <div className="marker-shelter-house mini">⛺</div>
                <span>Shelter (House)</span>
              </div>
              <div className="legend-item">
                <div className="marker-polygon-preview mini">🟣</div>
                <span>ML Zone (Polygon Grid)</span>
              </div>
            </div>
          </div>
        </div>

        {/* Right Detail Panel (opens on clicking any marker) */}
        {selectedEntity && (
          <aside className="gis-detail-panel">
            <div className="detail-panel-header">
              <h4>Entity Inspector</h4>
              <button className="close-btn" onClick={() => setSelectedEntity(null)} aria-label="Close">
                <X size={18} />
              </button>
            </div>

            <div className="detail-panel-body">
              {selectedEntity.type === 'INCIDENT' && (
                <div className="entity-card">
                  <div className="entity-tags">
                    <TruthBadge 
                      type={selectedEntity.data.status === 'VERIFIED' ? 'VERIFIED_INCIDENT' : 'UNVERIFIED_REPORT'}
                      size="sm"
                    />
                    <span className="sla-badge">SLA: {selectedEntity.data.sla_deadline_minutes || 20}m</span>
                  </div>

                  <h4>{selectedEntity.data.title}</h4>
                  <p className="entity-loc">📍 {selectedEntity.data.location_name}</p>

                  <div className="entity-stats-grid">
                    <div>
                      <span>Priority</span>
                      <strong>{selectedEntity.data.priority_score}/100</strong>
                    </div>
                    <div>
                      <span>Affected</span>
                      <strong>{selectedEntity.data.people_affected} People</strong>
                    </div>
                    <div>
                      <span>Status</span>
                      <strong className="text-info">{selectedEntity.data.status}</strong>
                    </div>
                  </div>

                  <div className="panel-actions">
                    <button className="primary-btn" onClick={calculateSafeRoute}>
                      <Navigation size={14} />
                      <span>Dispatch Safe Route</span>
                    </button>
                  </div>
                </div>
              )}

              {selectedEntity.type === 'ML_RISK_ZONE' && (
                <div className="entity-card">
                  <TruthBadge type="ML_ASSESSMENT" size="sm" source="v1.2-xgb" />
                  <h4>{selectedEntity.data.areaName}</h4>
                  <p className="text-critical font-bold">Predicted Risk: {selectedEntity.data.riskLevel} ({Math.round(selectedEntity.data.calibratedProbability * 100)}%)</p>
                  
                  <div className="ml-factors-list">
                    <span>• 48h Precipitation: {selectedEntity.data.rainfall48h}</span>
                    <span>• River Gauge: {selectedEntity.data.cwcGaugeStatus}</span>
                  </div>

                  <div className="disclaimer-callout">
                    <span>⚠️ {selectedEntity.data.modelAssessmentNote}</span>
                  </div>
                </div>
              )}

              {selectedEntity.type === 'RESCUE_TEAM' && (
                <div className="entity-card">
                  <span className="team-pill">UNIT: {selectedEntity.data.type}</span>
                  <h4>{selectedEntity.data.name}</h4>
                  <p>Status: <strong className="text-safe">{selectedEntity.data.status}</strong></p>
                  <p>Capacity: <strong>{selectedEntity.data.capacity} Rescuers</strong></p>
                  <p>Contact: {selectedEntity.data.contact_number}</p>
                </div>
              )}

              {selectedEntity.type === 'ROAD_CLOSURE' && (
                <div className="entity-card">
                  <span className="road-closure-tag">🚫 ROAD CLOSED (FR-23)</span>
                  <h4>{selectedEntity.data.road_name}</h4>
                  <p>Cause: <strong className="text-critical">{selectedEntity.data.cause}</strong></p>
                  <p className="warning-note">Automated routing directs emergency vehicles away from this submerged passage.</p>
                </div>
              )}

              {selectedEntity.type === 'SHELTER' && (
                <div className="entity-card">
                  <h4>⛺ {selectedEntity.data.name}</h4>
                  <p>Capacity: {selectedEntity.data.currentOccupancy} / {selectedEntity.data.capacity} Occupants</p>
                  <div className="facilities-tags">
                    {selectedEntity.data.facilities?.map((f: string, i: number) => (
                      <span key={i} className="facility-pill">{f}</span>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </aside>
        )}
      </div>
    </div>
  );
};
