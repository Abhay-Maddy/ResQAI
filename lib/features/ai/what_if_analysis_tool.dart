import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/incident_model.dart';
import '../../data/repositories/incident_repository.dart';

class WhatIfAnalysisTool extends ConsumerStatefulWidget {
  final IncidentModel incident;

  const WhatIfAnalysisTool({super.key, required this.incident});

  @override
  ConsumerState<WhatIfAnalysisTool> createState() => _WhatIfAnalysisToolState();
}

class _WhatIfAnalysisToolState extends ConsumerState<WhatIfAnalysisTool> {
  late double _simulatedWaterLevel;
  late int _simulatedCasualties;
  late int _simulatedTrapped;
  late bool _simulatedVulnerablePresent;
  late bool _simulatedNightTime;

  @override
  void initState() {
    super.initState();
    _simulatedWaterLevel = 1.0;
    _simulatedCasualties = 0;
    _simulatedTrapped = 8;
    _simulatedVulnerablePresent = widget.incident.vulnerableGroups.isNotEmpty;
    _simulatedNightTime = true;
  }

  double _computeScore() {
    return IncidentModel.calculatePriority(
      category: widget.incident.category,
      casualties: _simulatedCasualties,
      trappedCount: _simulatedTrapped,
      hasVulnerable: _simulatedVulnerablePresent,
      waterLevelMeters: _simulatedWaterLevel,
      isNightTime: _simulatedNightTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentScore = widget.incident.priorityScore;
    final simulatedScore = _computeScore();
    final delta = simulatedScore - currentScore;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune, color: AppColors.primaryLight, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Explainable Priority: What-If Simulation',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: simulatedScore >= 80 ? AppColors.criticalRed.withOpacity(0.2) : AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: simulatedScore >= 80 ? AppColors.criticalRed : AppColors.primary),
                  ),
                  child: Text(
                    'Simulated: ${simulatedScore.toStringAsFixed(1)} (${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: simulatedScore >= 80 ? AppColors.criticalRed : AppColors.primaryLight,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Adjust hypothetical conditions to compare real-time priority escalation without modifying official records.',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
            const Divider(height: 24),

            // Slider 1: Flood Water Depth
            Row(
              children: [
                Expanded(
                  child: Text('Hypothetical Water Level: ${_simulatedWaterLevel.toStringAsFixed(1)}m (Threshold: 1.5m)', style: const TextStyle(fontSize: 13)),
                ),
                SizedBox(
                  width: 220,
                  child: Slider(
                    value: _simulatedWaterLevel,
                    min: 0.0,
                    max: 4.0,
                    divisions: 8,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _simulatedWaterLevel = val),
                  ),
                ),
              ],
            ),

            // Slider 2: Trapped Count
            Row(
              children: [
                Expanded(
                  child: Text('Simulated Trapped Civilians: $_simulatedTrapped people', style: const TextStyle(fontSize: 13)),
                ),
                SizedBox(
                  width: 220,
                  child: Slider(
                    value: _simulatedTrapped.toDouble(),
                    min: 0,
                    max: 50,
                    divisions: 10,
                    activeColor: AppColors.accent,
                    onChanged: (val) => setState(() => _simulatedTrapped = val.toInt()),
                  ),
                ),
              ],
            ),

            // Switches: Vulnerable & Night-time
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Vulnerable Groups Present (Children / Elderly / Hospital)', style: TextStyle(fontSize: 13)),
                    value: _simulatedVulnerablePresent,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _simulatedVulnerablePresent = val ?? false),
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Night-time Rescue Conditions (+5% Risk)', style: TextStyle(fontSize: 13)),
                    value: _simulatedNightTime,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _simulatedNightTime = val ?? false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset Baseline'),
                  onPressed: () {
                    setState(() {
                      _simulatedWaterLevel = 1.0;
                      _simulatedCasualties = 0;
                      _simulatedTrapped = 8;
                      _simulatedVulnerablePresent = widget.incident.vulnerableGroups.isNotEmpty;
                      _simulatedNightTime = true;
                    });
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  icon: const Icon(Icons.save_alt, size: 16, color: Colors.white),
                  label: const Text('Apply Recommendation', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    ref.read(incidentsProvider.notifier).updateWhatIfSimulation(
                      widget.incident.id,
                      {
                        'waterLevel': _simulatedWaterLevel,
                        'trapped': _simulatedTrapped,
                        'notes': 'Waterlevel ${_simulatedWaterLevel}m, $_simulatedTrapped trapped',
                      },
                      simulatedScore,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('What-if simulated priority ${simulatedScore.toStringAsFixed(1)} recorded for decision support.')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
