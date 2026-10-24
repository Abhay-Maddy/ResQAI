import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';
import '../../shared/widgets/truth_badge_widget.dart';

class NeedsForecastScreen extends StatefulWidget {
  const NeedsForecastScreen({super.key});

  @override
  State<NeedsForecastScreen> createState() => _NeedsForecastScreenState();
}

class _NeedsForecastScreenState extends State<NeedsForecastScreen> {
  String _selectedDistrict = 'East Delhi (Population Exposure: 18,400)';

  final List<Map<String, dynamic>> _demandData = [
    {
      'item': 'Potable Drinking Water',
      'icon': Icons.water_drop_outlined,
      'forecast': 55200,
      'staged': 38000,
      'unit': 'Litres',
      'shortfall': 17200,
      'confidence': '±6.2%',
      'freshness': 'Updated 8m ago • CWC Khadar Depot',
      'action': 'Deploy 18,000L water bowsers from Shahdara depot buffer',
    },
    {
      'item': 'Dry Food Rations',
      'icon': Icons.restaurant_outlined,
      'forecast': 18400,
      'staged': 16500,
      'unit': 'Packets',
      'shortfall': 1900,
      'confidence': '±4.8%',
      'freshness': 'Updated 14m ago • Mayur Vihar Camp 2',
      'action': 'Requisition 2,000 dry ration packets via Akshaya Patra NGO',
    },
    {
      'item': 'Waterproof Tarpaulins / Tents',
      'icon': Icons.roofing_outlined,
      'forecast': 3200,
      'staged': 3500,
      'unit': 'Sheets',
      'shortfall': 0, // Surplus +300
      'confidence': '±8.1%',
      'freshness': 'Updated 22m ago • District Warehouse',
      'action': 'Adequate buffer. 300 surplus available for reallocation',
    },
    {
      'item': 'First Aid & ORS Medical Kits',
      'icon': Icons.medical_services_outlined,
      'forecast': 2800,
      'staged': 1200,
      'unit': 'Kits',
      'shortfall': 1600,
      'confidence': '±9.4%',
      'freshness': 'Updated 5m ago • GTB Hospital Triage Base',
      'action': 'Urgent: Dispatch 1,600 anti-diarrheal & chlorine tablet kits',
    },
    {
      'item': 'NDRF Inflatable Motor Boats',
      'icon': Icons.directions_boat_outlined,
      'forecast': 14,
      'staged': 10,
      'unit': 'Boats',
      'shortfall': 4,
      'confidence': '±0%',
      'freshness': 'Updated 2m ago • 8th Battalion NDRF Post',
      'action': 'Request 4 Zodiac tactical inflatable boats from Ghaziabad reserve',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return AppShell(
      currentRoute: AppRoutes.intelligenceNeedsForecast,
      title: 'Predictive Relief Demand Engine',
      breadcrumbs: const ['AI Intelligence', 'Relief Demand'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 28,
          vertical: isMobile ? 16 : 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. STATUTORY ML MODEL & PROBABILISTIC DISCLOSURE BANNER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceCard : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.darkBorder : Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.psychology, color: AppColors.primaryBlue, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Probabilistic Disaster Relief Supply & Demand Forecasting',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            Text(
                              'Gemini Multimodal / ResQ-Net Predictive Engine • 72-Hour Planning Horizon',
                              style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      if (!isMobile) const TruthBadgeWidget(type: TruthBadgeType.aiAssisted),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Transparency & Integrity Disclosure: Forecasted values are algorithmic estimates derived from satellite inundation depth, census density, and field intake records. Staged quantities represent physical stock verified by warehouse receipts. Dispatches require incident commander authorization.',
                    style: TextStyle(fontSize: 11, height: 1.4, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. DISTRICT SELECTOR & RUNTIME CONTROLS
            Card(
              color: isDark ? AppColors.darkSurface : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.location_city, color: AppColors.primaryBlue, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDistrict,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Demarcated Target Disaster Sector',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: [
                          'East Delhi (Population Exposure: 18,400)',
                          'North East Delhi - Seelampur Ward (Population: 26,000)',
                          'Central Delhi - Yamuna Khadar (Population: 8,200)',
                        ]
                            .map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(
                                    d,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedDistrict = v);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 3. RESPONSIVE DEMAND VS STAGED CARDS
            Text(
              'Itemized Relief Supply vs Algorithmic Demand Breakdown (${_demandData.length} Critical Categories)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),

            for (final item in _demandData) ...[
              _buildResponsiveResourceCard(item, isMobile, isDark),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveResourceCard(Map<String, dynamic> item, bool isMobile, bool isDark) {
    final int forecast = item['forecast'] as int;
    final int staged = item['staged'] as int;
    final int shortfall = item['shortfall'] as int;
    final bool hasShortfall = shortfall > 0;
    final double ratio = forecast > 0 ? (staged / forecast).clamp(0.0, 1.0) : 1.0;
    final int percent = (ratio * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasShortfall ? AppColors.criticalRed.withOpacity(0.35) : AppColors.successGreen.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Resource Header + Status Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasShortfall ? AppColors.criticalRed.withOpacity(0.12) : AppColors.successGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item['icon'] as IconData,
                    color: hasShortfall ? AppColors.criticalRed : AppColors.successGreen, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['item'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Confidence: ${item['confidence']}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Unit: ${item['unit']}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Badge
              if (hasShortfall)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.criticalRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.criticalRed.withOpacity(0.3)),
                  ),
                  child: Text(
                    '-$shortfall ${item['unit']}',
                    style: const TextStyle(
                      color: AppColors.criticalRed,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'ADEQUATE (SURPLUS)',
                    style: TextStyle(
                      color: AppColors.successGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Staged Inventory vs Forecasted Demand Matrix
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Verified Staged Stock', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      '$staged ${item['unit']}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primaryBlue),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Fulfillment', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: hasShortfall ? AppColors.criticalRed : AppColors.successGreen,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Forecasted Demand', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      '$forecast ${item['unit']}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Row 3: Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(
                hasShortfall ? AppColors.criticalRed : AppColors.successGreen,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Row 4: Recommended Action & Data Freshness
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.bolt, size: 14, color: AppColors.warningOrange),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item['action'] as String,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item['freshness'] as String,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
