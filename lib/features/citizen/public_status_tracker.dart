import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/incident_model.dart';
import '../../data/repositories/incident_repository.dart';
import '../../shared/widgets/status_tracker_stepper.dart';
import '../../shared/widgets/truth_badge_widget.dart';

class PublicStatusTracker extends ConsumerStatefulWidget {
  const PublicStatusTracker({super.key});

  @override
  ConsumerState<PublicStatusTracker> createState() => _PublicStatusTrackerState();
}

class _PublicStatusTrackerState extends ConsumerState<PublicStatusTracker> {
  final _searchController = TextEditingController(text: 'RQ-101');
  IncidentModel? _searchedIncident;
  bool _hasSearched = false;

  void _search() {
    final query = _searchController.text.trim().toUpperCase();
    final incidents = ref.read(incidentsProvider);
    final match = incidents.where((i) => i.id.toUpperCase() == query).toList();

    setState(() {
      _hasSearched = true;
      _searchedIncident = match.isNotEmpty ? match.first : null;
    });
  }

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Public Incident Status Tracking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                    'Track the live status of your emergency request using your Reference ID (e.g., RQ-101, RQ-102, RQ-104).',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Enter Reference ID (e.g. RQ-101)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          onSubmitted: (_) => _search(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                        onPressed: _search,
                        child: const Text('Track', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (_hasSearched) ...[
            if (_searchedIncident != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _searchedIncident!.id,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight, fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _searchedIncident!.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const TruthBadgeWidget(type: TruthBadgeType.piiMasked),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Status Progression Stepper (Feature 6: Received, Under Review, Verified, Help Assigned)
                      const Text('Dispatch & Verification Progression', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 12),
                      StatusTrackerStepper(currentStatus: _searchedIncident!.status),

                      const Divider(height: 32),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Original Description', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text(_searchedIncident!.descriptionOriginal, style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 12),
                                const Text('Translated / Responders View', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text(_searchedIncident!.descriptionTranslated, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Location', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text(_searchedIncident!.address, style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 12),
                                const Text('Assigned Team', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text(
                                  _searchedIncident!.assignedTeam ?? 'Pending team dispatch',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _searchedIncident!.assignedTeam != null ? AppColors.verifiedGreen : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (_searchedIncident!.vulnerableGroups.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('Protected Flags:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: _searchedIncident!.vulnerableGroups.map((g) {
                            return Chip(
                              label: Text(g, style: const TextStyle(fontSize: 11)),
                              backgroundColor: AppColors.primary.withOpacity(0.15),
                              padding: EdgeInsets.zero,
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.search_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text('No incident found matching "${_searchController.text.trim()}"', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Please verify the Reference ID format (e.g. RQ-101, RQ-102, RQ-104) and try again.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
