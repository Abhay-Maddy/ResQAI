import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/incident_repository.dart';
import '../../shared/models/incident_model.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';

class DisasterMapScreen extends ConsumerStatefulWidget {
  final String routePath;

  const DisasterMapScreen({super.key, this.routePath = AppRoutes.disasterMap});

  @override
  ConsumerState<DisasterMapScreen> createState() => _DisasterMapScreenState();
}

class _DisasterMapScreenState extends ConsumerState<DisasterMapScreen> {
  final MapController _mapController = MapController();
  IncidentModel? _selectedIncident;
  bool _showShelters = true;
  bool _showHazards = true;
  bool _showRoadBlockage = true;
  String _severityFilter = 'ALL'; // 'ALL', 'CRITICAL', 'MODERATE'

  // Delhi Yamuna Hazard Blockage Polyline
  final List<LatLng> _blockedRoute = const [
    LatLng(28.6200, 77.2150),
    LatLng(28.6250, 77.2200),
    LatLng(28.6300, 77.2280),
  ];

  @override
  Widget build(BuildContext context) {
    final incidents = ref.watch(incidentsProvider);
    final shelters = ref.watch(sheltersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;

    // Filter incidents by severity
    final displayedIncidents = incidents.where((i) {
      if (_severityFilter == 'CRITICAL') return i.priorityScore >= 80;
      if (_severityFilter == 'MODERATE') return i.priorityScore >= 50 && i.priorityScore < 80;
      return true;
    }).toList();

    return AppShell(
      currentRoute: widget.routePath,
      title: 'Tactical Disaster Map GIS',
      breadcrumbs: const ['Disaster Map', 'Tactical GIS'],
      child: Stack(
        children: [
          // 1. OPENSTREETMAP WORKSPACE
          Row(
            children: [
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: LatLng(28.6200, 77.2150),
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'org.resqai.disaster',
                    ),

                    // Road Hazard Blockage Line
                    if (_showRoadBlockage)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _blockedRoute,
                            strokeWidth: 4.5,
                            color: AppColors.criticalRed,
                            pattern: StrokePattern.dashed(segments: const [10, 8]),
                          ),
                        ],
                      ),

                    // Relief Shelters Markers
                    if (_showShelters)
                      MarkerLayer(
                        markers: shelters.map((s) {
                          return Marker(
                            point: LatLng(s.latitude, s.longitude),
                            width: 36,
                            height: 36,
                            child: Tooltip(
                              message: 'Shelter: ${s.name}',
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.successGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                ),
                                child: const Icon(Icons.night_shelter, color: Colors.white, size: 20),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    // Incident Markers
                    if (_showHazards)
                      MarkerLayer(
                        markers: displayedIncidents.map((inc) {
                          final isCrit = inc.priorityScore >= 80;
                          final isSelected = _selectedIncident?.id == inc.id;

                          return Marker(
                            point: LatLng(inc.latitude, inc.longitude),
                            width: isSelected ? 48 : 38,
                            height: isSelected ? 48 : 38,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _selectedIncident = inc);
                                if (!isDesktop) _showMobileDetailSheet(context, inc);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isCrit ? AppColors.criticalRed : AppColors.warningOrange,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Colors.yellowAccent : Colors.white,
                                    width: isSelected ? 3 : 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isCrit ? AppColors.criticalRed : AppColors.warningOrange).withOpacity(0.5),
                                      blurRadius: isSelected ? 12 : 6,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  inc.source == 'ONE_TAP_SOS' ? Icons.emergency : Icons.warning_amber_rounded,
                                  color: Colors.white,
                                  size: isSelected ? 24 : 18,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),

              // DESKTOP CONTEXTUAL RIGHT SIDE PANEL
              if (isDesktop && _selectedIncident != null)
                Container(
                  width: 360,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    border: Border(left: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                  ),
                  child: _buildDesktopDetailPanel(context, _selectedIncident!, isDark),
                ),
            ],
          ),

          // 2. FLOATING MAP CONTROLS & FILTER BAR
          Positioned(
            top: 16,
            left: 16,
            right: isDesktop ? (360 + 16) : 16,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All Incidents', _severityFilter == 'ALL', () => setState(() => _severityFilter = 'ALL')),
                  const SizedBox(width: 8),
                  _buildFilterChip('Critical SOS (≥80)', _severityFilter == 'CRITICAL', () => setState(() => _severityFilter = 'CRITICAL'), color: AppColors.criticalRed),
                  const SizedBox(width: 8),
                  _buildFilterChip('Moderate (50-79)', _severityFilter == 'MODERATE', () => setState(() => _severityFilter = 'MODERATE'), color: AppColors.warningOrange),
                  const SizedBox(width: 12),
                  _buildToggleChip('Shelters', _showShelters, () => setState(() => _showShelters = !_showShelters), Icons.night_shelter),
                  const SizedBox(width: 8),
                  _buildToggleChip('Incident Pins', _showHazards, () => setState(() => _showHazards = !_showHazards), Icons.crisis_alert),
                  const SizedBox(width: 8),
                  _buildToggleChip('Road Hazards', _showRoadBlockage, () => setState(() => _showRoadBlockage = !_showRoadBlockage), Icons.warning),
                ],
              ),
            ),
          ),

          // 3. FLOATING GEOLOCATION & RE-CENTER BUTTON
          Positioned(
            bottom: 24,
            right: isDesktop ? (360 + 20) : 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              tooltip: 'Re-center to GPS',
              onPressed: () {
                _mapController.move(const LatLng(28.6200, 77.2150), 13.0);
              },
              child: const Icon(Icons.my_location, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, {Color? color}) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: (color ?? AppColors.primaryBlue).withOpacity(0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isSelected ? (color ?? AppColors.primaryBlue) : Colors.black87,
      ),
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildToggleChip(String label, bool isEnabled, VoidCallback onTap, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 14, color: isEnabled ? AppColors.primaryBlue : Colors.grey),
      label: Text(label),
      labelStyle: TextStyle(fontSize: 12, fontWeight: isEnabled ? FontWeight.bold : FontWeight.normal),
      onPressed: onTap,
    );
  }

  Widget _buildDesktopDetailPanel(BuildContext context, IncidentModel incident, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Panel Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Incident Workspace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _selectedIncident = null),
              ),
            ],
          ),
        ),

        // Panel Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.criticalRed.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PRIORITY: ${incident.priorityScore.toStringAsFixed(0)}/100',
                        style: const TextStyle(color: AppColors.criticalRed, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('ID: ${incident.id}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  incident.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.deepNavy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Locality: ${incident.address}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                const Text('Field Description:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(incident.descriptionOriginal, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Dispatch Status:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  incident.status.label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 42),
                  ),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Open Detailed Case File'),
                  onPressed: () {
                    Navigator.pushNamed(context, '${AppRoutes.citizenReports}/${incident.id}');
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showMobileDetailSheet(BuildContext context, IncidentModel incident) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(incident.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text('Location: ${incident.address}', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              Text('Priority Score: ${incident.priorityScore.toStringAsFixed(0)}/100', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.criticalRed)),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '${AppRoutes.citizenReports}/${incident.id}');
                },
                child: const Text('View Full Case & Verification'),
              ),
            ],
          ),
        );
      },
    );
  }
}
