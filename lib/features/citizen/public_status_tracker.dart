import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/incident_model.dart';
import '../../data/repositories/incident_repository.dart';
import '../../data/repositories/auth_repository.dart';
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

  void _reopenCase(IncidentModel inc) {
    final reasonController = TextEditingController();
    final currentUser = ref.read(authProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.warningAmber),
        ),
        title: const Row(
          children: [
            Icon(Icons.replay, color: AppColors.warningAmber, size: 24),
            SizedBox(width: 8),
            Text('Request Case Reopening / Escalation', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Incident / Case: ${inc.id} (${inc.title})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
            const SizedBox(height: 8),
            const Text(
              'If field relief has not arrived, damage was under-assessed, or conditions worsened, submit an official escalation reason:',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Water level entered first floor overnight; elderly resident requires immediate evacuation.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warningAmber, foregroundColor: Colors.black),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              ref.read(incidentsProvider.notifier).reopenIncident(
                    inc.id,
                    reasonController.text.trim(),
                    currentUser?.name ?? 'Affected Citizen',
                  );
              Navigator.pop(ctx);
              _search();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.warningAmber,
                  content: Text('✓ Case ${inc.id} escalated to District Magistrate Review Desk.'),
                ),
              );
            },
            child: const Text('Submit Escalation', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  Widget build(BuildContext context) {
    // Keep updated with live state changes
    final incidents = ref.watch(incidentsProvider);
    if (_searchedIncident != null) {
      final updated = incidents.where((i) => i.id == _searchedIncident!.id).toList();
      if (updated.isNotEmpty) {
        _searchedIncident = updated.first;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: AppColors.darkSurfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Live Disaster & Assistance Case Tracker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                    'Track the end-to-end verification, field inspection, and relief dispatch status using your Reference / Case ID (e.g. RQ-101, RQ-102, RQ-104, RQ-CASE-2026-1001).',
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
                            hintText: 'Enter Reference / Case ID (e.g. RQ-101)',
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
                        child: const Text('Track Live Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                color: AppColors.darkSurfaceCard,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with ID, Status Chip & Privacy Badge
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
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight, fontSize: 15),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _searchedIncident!.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          _buildStatusBadge(_searchedIncident!.status),
                          const SizedBox(width: 8),
                          const TruthBadgeWidget(type: TruthBadgeType.piiMasked),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Traceable Stepper (Part 7: Traceable Lifecycle)
                      const Text('Disaster Response & Assistance Lifecycle Stage:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 12),
                      StatusTrackerStepper(currentStatus: _searchedIncident!.status),
                      const Divider(height: 28),

                      // Core Details Grid
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Incident / Damage Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text(_searchedIncident!.descriptionOriginal, style: const TextStyle(fontSize: 13, height: 1.4)),
                                if (_searchedIncident!.urgentMedicalNeeds != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Urgent Medical Needs: ${_searchedIncident!.urgentMedicalNeeds}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.criticalRed, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Location & Jurisdiction', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text(_searchedIncident!.address, style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 10),
                                const Text('Assigned Department / Team', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text(
                                  _searchedIncident!.departmentAssigned ?? _searchedIncident!.assignedTeam ?? 'Queued for departmental assignment',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: (_searchedIncident!.assignedTeam != null || _searchedIncident!.departmentAssigned != null)
                                        ? AppColors.verifiedGreen
                                        : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Damage Particulars if present (Part 6)
                      if (_searchedIncident!.affectedProperties.isNotEmpty || _searchedIncident!.estimatedLossInr != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Government Assistance Claim Particulars:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryLight)),
                                  if (_searchedIncident!.estimatedLossInr != null)
                                    Text('Estimated Loss: ₹${_searchedIncident!.estimatedLossInr!.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warningAmber)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              if (_searchedIncident!.affectedProperties.isNotEmpty) ...[
                                const Text('Affected Properties:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  children: _searchedIncident!.affectedProperties.map((p) => Chip(
                                    label: Text(p, style: const TextStyle(fontSize: 10)),
                                    padding: EdgeInsets.zero,
                                    backgroundColor: AppColors.primary.withOpacity(0.15),
                                  )).toList(),
                                ),
                              ],
                              if (_searchedIncident!.reliefRequirements.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                const Text('Relief Supplies Requested:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  children: _searchedIncident!.reliefRequirements.map((r) => Chip(
                                    label: Text(r, style: const TextStyle(fontSize: 10)),
                                    padding: EdgeInsets.zero,
                                    backgroundColor: AppColors.verifiedGreen.withOpacity(0.15),
                                  )).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      // Official Reviewer Notes & Decision Reason (Part 7)
                      if (_searchedIncident!.reviewerName != null || _searchedIncident!.decisionReason != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.verifiedGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.verifiedGreen.withOpacity(0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.verified_user, color: AppColors.verifiedGreen, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'DDMA Official Verification Decision (${_searchedIncident!.reviewerRole ?? "Authorized Reviewer"})',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.verifiedGreen),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Reviewer: ${_searchedIncident!.reviewerName ?? "State Inspector"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              if (_searchedIncident!.decisionReason != null)
                                Text('Decision Reason: ${_searchedIncident!.decisionReason}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                              if (_searchedIncident!.reviewerNotes != null)
                                Text('Official Field Notes: ${_searchedIncident!.reviewerNotes}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                            ],
                          ),
                        ),
                      ],

                      // Verification Timeline / Audit Log (Part 7 & 15)
                      if (_searchedIncident!.verificationHistory.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('Traceable Lifecycle History & Field Audit Log:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _searchedIncident!.verificationHistory.map((log) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ', style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
                                    Expanded(child: Text(log, style: const TextStyle(fontSize: 11, color: Colors.white70))),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],

                      const Divider(height: 24),

                      // Escalation / Reopening Option (Part 7: "Allow reopening and escalation when appropriate")
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Priority Rating: ${_searchedIncident!.priorityScore.toStringAsFixed(1)} / 100', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.warningAmber,
                              side: const BorderSide(color: AppColors.warningAmber),
                            ),
                            icon: const Icon(Icons.replay, size: 16),
                            label: const Text('Request Escalation / Reopen', style: TextStyle(fontSize: 12)),
                            onPressed: () => _reopenCase(_searchedIncident!),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                color: AppColors.darkSurfaceCard,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.search_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text('No incident or claim found matching "${_searchController.text.trim()}"', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Please verify your Reference ID (e.g. RQ-101, RQ-102, RQ-103, RQ-SOS-2026-0001, RQ-CASE-2026-1001) and try again.', style: TextStyle(color: Colors.grey, fontSize: 12)),
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

  Widget _buildStatusBadge(IncidentStatus status) {
    Color color;
    switch (status) {
      case IncidentStatus.received:
        color = Colors.blue;
        break;
      case IncidentStatus.pendingReview:
        color = Colors.indigoAccent;
        break;
      case IncidentStatus.underReview:
        color = Colors.orange;
        break;
      case IncidentStatus.verified:
        color = AppColors.verifiedGreen;
        break;
      case IncidentStatus.unverified:
        color = Colors.grey;
        break;
      case IncidentStatus.duplicate:
        color = Colors.deepPurple;
        break;
      case IncidentStatus.helpAssigned:
        color = AppColors.criticalRed;
        break;
      case IncidentStatus.inProgress:
        color = Colors.teal;
        break;
      case IncidentStatus.resolved:
        color = Colors.green;
        break;
      case IncidentStatus.closed:
        color = Colors.blueGrey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(6), border: Border.all(color: color)),
      child: Text(status.label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}
