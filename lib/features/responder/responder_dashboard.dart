import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/incident_model.dart';
import '../../data/repositories/incident_repository.dart';
import '../../shared/widgets/truth_badge_widget.dart';
import '../ai/what_if_analysis_tool.dart';
import '../ai/ai_feedback_widget.dart';

class ResponderDashboard extends ConsumerStatefulWidget {
  const ResponderDashboard({super.key});

  @override
  ConsumerState<ResponderDashboard> createState() => _ResponderDashboardState();
}

class _ResponderDashboardState extends ConsumerState<ResponderDashboard> {
  String _filterCategory = 'ALL';

  @override
  Widget build(BuildContext context) {
    final incidents = ref.watch(incidentsProvider);
    final selectedIncident = ref.watch(selectedIncidentProvider) ?? (incidents.isNotEmpty ? incidents.first : null);

    final filteredIncidents = incidents.where((inc) {
      if (_filterCategory == 'ALL') return true;
      if (_filterCategory == 'UNASSIGNED') return inc.assignedTeam == null;
      if (_filterCategory == 'CRITICAL') return inc.priorityScore >= 80;
      if (_filterCategory == 'DUPLICATES') return inc.isPossibleDuplicate;
      return true;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Incident List Panel
                  SizedBox(
                    width: 380,
                    child: _buildIncidentList(filteredIncidents, selectedIncident),
                  ),
                  const VerticalDivider(width: 1),
                  // Right Incident Detail & AI Tools Panel
                  Expanded(
                    child: selectedIncident != null
                        ? _buildDetailPanel(selectedIncident)
                        : const Center(child: Text('Select an incident to review triage & AI assessments.')),
                  ),
                ],
              )
            : _buildMobileView(filteredIncidents, selectedIncident);
      },
    );
  }

  Widget _buildIncidentList(List<IncidentModel> list, IncidentModel? selected) {
    return Column(
      children: [
        // Filter Chips (Feature 10: Escalations, Feature 15: Duplicates)
        Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(label: 'All (${list.length})', isSelected: _filterCategory == 'ALL', onSelected: () => setState(() => _filterCategory = 'ALL')),
                const SizedBox(width: 6),
                _FilterChip(label: 'Unassigned (>15m)', isSelected: _filterCategory == 'UNASSIGNED', onSelected: () => setState(() => _filterCategory = 'UNASSIGNED')),
                const SizedBox(width: 6),
                _FilterChip(label: 'Critical Priority', isSelected: _filterCategory == 'CRITICAL', onSelected: () => setState(() => _filterCategory = 'CRITICAL')),
                const SizedBox(width: 6),
                _FilterChip(label: 'Duplicate Triage', isSelected: _filterCategory == 'DUPLICATES', onSelected: () => setState(() => _filterCategory = 'DUPLICATES')),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, idx) {
              final inc = list[idx];
              final isSelected = selected?.id == inc.id;
              final isCritical = inc.priorityScore >= 80;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                color: isSelected ? AppColors.primary.withOpacity(0.12) : null,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : (isCritical ? AppColors.criticalRed.withOpacity(0.5) : AppColors.darkBorder),
                    width: isSelected ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: isCritical ? AppColors.criticalRed.withOpacity(0.2) : AppColors.primary.withOpacity(0.2),
                    child: Text(
                      inc.priorityScore.toStringAsFixed(0),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isCritical ? AppColors.criticalRed : AppColors.primaryLight,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(inc.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryLight)),
                      const SizedBox(width: 6),
                      if (inc.isPossibleDuplicate)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: AppColors.warningAmber.withOpacity(0.2), borderRadius: BorderRadius.circular(3)),
                          child: const Text('DUP?', style: TextStyle(color: AppColors.warningAmber, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(inc.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('${inc.category.label} • ${inc.address}', style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1),
                    ],
                  ),
                  onTap: () {
                    ref.read(selectedIncidentProvider.notifier).state = inc;
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailPanel(IncidentModel inc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                child: Text(inc.id, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(inc.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              TruthBadgeWidget(type: inc.priorityScore >= 80 ? TruthBadgeType.officialAlert : TruthBadgeType.aiAssisted),
            ],
          ),
          const SizedBox(height: 12),

          // Action Status Toolbar (Feature 4, 11: Field updates)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.darkSurfaceCard, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Text('Dispatch Status:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                DropdownButton<IncidentStatus>(
                  value: inc.status,
                  underline: const SizedBox(),
                  items: IncidentStatus.values.map((st) {
                    return DropdownMenuItem(value: st, child: Text(st.label, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (newSt) {
                    if (newSt != null) {
                      ref.read(incidentsProvider.notifier).updateStatus(inc.id, newSt);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${inc.id} status updated to ${newSt.label}')),
                      );
                    }
                  },
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  icon: const Icon(Icons.group_add, size: 16, color: Colors.white),
                  label: Text(inc.assignedTeam ?? 'Assign Rescue Team', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  onPressed: () {
                    ref.read(incidentsProvider.notifier).updateStatus(inc.id, IncidentStatus.helpAssigned, team: 'NDRF Fast Response Team Alpha-1');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('NDRF Fast Response Team Alpha-1 dispatched to site.')),
                    );
                  },
                ),
              ],
            ),
          ),

          // Duplicate Detection Human Confirmation Modal / Banner (Feature 15)
          if (inc.isPossibleDuplicate && !inc.duplicateConfirmedByHuman) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warningAmber.withOpacity(0.12),
                border: Border.all(color: AppColors.warningAmber),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.copy, color: AppColors.warningAmber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'AI Duplicate Candidate: Matches with ${inc.duplicateOfId} (${(inc.duplicateConfidence * 100).toStringAsFixed(0)}% Similarity)',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.warningAmber, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Safety Rule: ResQAI never automatically merges reports. A human commander must verify if this is the same physical incident.',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.close, size: 16, color: Colors.white70),
                        label: const Text('Reject (Independent Incident)', style: TextStyle(color: Colors.white70)),
                        onPressed: () {
                          ref.read(incidentsProvider.notifier).rejectDuplicate(inc.id);
                        },
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.warningAmber),
                        icon: const Icon(Icons.check, size: 16, color: Colors.black),
                        label: const Text('Confirm Duplicate & Link', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          ref.read(incidentsProvider.notifier).confirmDuplicate(inc.id, inc.duplicateOfId ?? 'RQ-101');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Bilingual Text & Reporter Details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Original Community Report (Hindi / English)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(inc.descriptionOriginal, style: const TextStyle(fontSize: 14)),
                  const Divider(height: 20),
                  const Text('Automatic Translation for Responders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(inc.descriptionTranslated, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Text('Source: ${inc.source}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const Spacer(),
                      Text('Reporter: ${inc.reporterPhoneMasked}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // AI Feedback loop button (Feature 25)
          AiFeedbackWidget(targetId: inc.id, featureName: 'PriorityScoring'),

          const SizedBox(height: 16),

          // What-If Priority Simulation Component (Feature 14)
          WhatIfAnalysisTool(incident: inc),
        ],
      ),
    );
  }

  Widget _buildMobileView(List<IncidentModel> list, IncidentModel? selected) {
    return Column(
      children: [
        if (selected != null)
          Container(
            padding: const EdgeInsets.all(8),
            color: AppColors.primary.withOpacity(0.1),
            child: Row(
              children: [
                Expanded(child: Text('Selected: ${selected.id} - ${selected.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                TextButton(onPressed: () => _showDetailModal(selected), child: const Text('Open Details')),
              ],
            ),
          ),
        Expanded(child: _buildIncidentList(list, selected)),
      ],
    );
  }

  void _showDetailModal(IncidentModel inc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          child: _buildDetailPanel(inc),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({required this.label, required this.isSelected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      selectedColor: AppColors.primary.withOpacity(0.3),
      onSelected: (_) => onSelected(),
    );
  }
}
