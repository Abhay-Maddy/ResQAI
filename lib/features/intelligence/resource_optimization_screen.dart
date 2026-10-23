import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';

class ResourceOptimizationScreen extends StatefulWidget {
  const ResourceOptimizationScreen({super.key});

  @override
  State<ResourceOptimizationScreen> createState() => _ResourceOptimizationScreenState();
}

class _ResourceOptimizationScreenState extends State<ResourceOptimizationScreen> {
  final List<Map<String, dynamic>> _recommendations = [
    {
      'id': 'OPT-REC-01',
      'incident': 'RQ-SOS-8821: 4 Elderly Trapped on Roof, Water 4ft',
      'location': 'Yamuna Khadar Sector 4',
      'recommendedUnit': 'NDRF 8th Battalion Boat Team #2',
      'reason': 'Proximity (1.4 km) + Equipped with 2 Gemini inflatable boats + Paramedic onboard for elderly triage.',
      'score': '96.4/100',
      'isOverridden': false,
    },
    {
      'id': 'OPT-REC-02',
      'incident': 'RQ-SOS-9914: Submerged Anganwadi Center with Infants',
      'location': 'Mayur Vihar Phase 1 Camp',
      'recommendedUnit': 'SDRF Quick Response Ambulance Unit #5',
      'reason': 'Fastest dry-route access via flyover (8 mins) + Infant rehydration formula staged onboard.',
      'score': '92.1/100',
      'isOverridden': false,
    },
    {
      'id': 'OPT-REC-03',
      'incident': 'RQ-DMG-102: Community Water Shortage (1,200 Persons)',
      'location': 'Chilla Village Relief Camp',
      'recommendedUnit': 'Delhi Jal Board 10KL Bowsers (Fleet 3)',
      'reason': 'Optimal batch payload + Chilla Road verified passable for heavy 6-wheel vehicles.',
      'score': '89.0/100',
      'isOverridden': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return AppShell(
      currentRoute: AppRoutes.intelligenceResourceOptimization,
      title: 'Explainable Resource Optimization',
      breadcrumbs: const ['AI Intelligence', 'Resource Optimization'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 32,
          vertical: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.alt_route, color: Colors.purple, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Multi-Objective Resource-Incident Matching Engine',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Solves constrained vehicle routing & skill matching. Coordinator override preserves human accountability.',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Recommendations List
            for (final rec in _recommendations) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: (rec['isOverridden'] as bool) ? Colors.orange : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                rec['id'] as String,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primaryBlue),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'MATCH CONFIDENCE: ${rec['score']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.successGreen),
                            ),
                          ],
                        ),
                        if (rec['isOverridden'] as bool)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                            child: const Text('MANUAL OVERRIDE APPLIED', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      rec['incident'] as String,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.deepNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Target Location: ${rec['location']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.recommend, color: AppColors.primaryBlue, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Recommended Unit: ${rec['recommendedUnit']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Reasoning: ${rec['reason']}',
                            style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              rec['isOverridden'] = !(rec['isOverridden'] as bool);
                            });
                          },
                          child: Text((rec['isOverridden'] as bool) ? 'Revert to AI Allocation' : 'Manual Coordinator Override'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                          icon: const Icon(Icons.send, size: 16),
                          label: const Text('Confirm & Dispatch Unit'),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Dispatched ${rec['recommendedUnit']} to incident site.')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
