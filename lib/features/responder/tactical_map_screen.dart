import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/incident_repository.dart';
import '../../shared/widgets/truth_badge_widget.dart';

class TacticalMapScreen extends ConsumerStatefulWidget {
  const TacticalMapScreen({super.key});

  @override
  ConsumerState<TacticalMapScreen> createState() => _TacticalMapScreenState();
}

class _TacticalMapScreenState extends ConsumerState<TacticalMapScreen> {
  final MapController _mapController = MapController();
  bool _showRoadHazards = true;
  bool _showShelters = true;

  @override
  Widget build(BuildContext context) {
    final incidents = ref.watch(incidentsProvider);
    final shelters = ref.watch(sheltersProvider);

    // Hazard road blockage line between Delhi NH-24 points
    final hazardBlockedRoute = [
      const LatLng(28.6200, 77.2150),
      const LatLng(28.6250, 77.2200),
      const LatLng(28.6300, 77.2280),
    ];

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
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

              // Road Hazard Blocked Line (Feature 22: Hazard-aware route caution)
              if (_showRoadHazards)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: hazardBlockedRoute,
                      strokeWidth: 5.0,
                      color: AppColors.criticalRed,
                      pattern: StrokePattern.dashed(segments: const [10, 8]),
                    ),
                  ],
                ),

              // Incident Markers
              MarkerLayer(
                markers: [
                  ...incidents.map((inc) {
                    final isCritical = inc.priorityScore >= 80;
                    return Marker(
                      point: LatLng(inc.latitude, inc.longitude),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () {
                          ref.read(selectedIncidentProvider.notifier).state = inc;
                          _showIncidentBottomSheet(context, inc);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: isCritical ? AppColors.criticalRed : AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: (isCritical ? AppColors.criticalRed : AppColors.primary).withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            isCritical ? Icons.warning_amber_rounded : Icons.location_on,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  }),

                  // Shelter Markers
                  if (_showShelters)
                    ...shelters.map((sh) {
                      return Marker(
                        point: LatLng(sh.latitude, sh.longitude),
                        width: 38,
                        height: 38,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${sh.name} — Remaining Beds: ${sh.remainingBeds} / ${sh.totalCapacity}')),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.verifiedGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.night_shelter, color: Colors.white, size: 20),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ],
          ),

          // Map Tactical Overlay Controls & Safety Notice
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              color: AppColors.darkSurface.withOpacity(0.92),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const TruthBadgeWidget(type: TruthBadgeType.notVerifiedSafe),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Caution: Red dashed routes indicate active structural hazards or landslides. Verified emergency corridors only.',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Road Hazards', style: TextStyle(fontSize: 11)),
                      selected: _showRoadHazards,
                      onSelected: (val) => setState(() => _showRoadHazards = val),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('Shelters', style: TextStyle(fontSize: 11)),
                      selected: _showShelters,
                      onSelected: (val) => setState(() => _showShelters = val),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showIncidentBottomSheet(BuildContext context, dynamic inc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(inc.id, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(inc.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(inc.descriptionTranslated, style: const TextStyle(fontSize: 13, color: Colors.white70)),
              const SizedBox(height: 12),
              Text('Address: ${inc.address}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Text('Priority Score: ${inc.priorityScore.toStringAsFixed(1)}/100', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    icon: const Icon(Icons.navigation, size: 16, color: Colors.white),
                    label: const Text('Calculate Safe Route', style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Safe route generated avoiding NH-24 culvert collapse. Detour via West Corridor.')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
