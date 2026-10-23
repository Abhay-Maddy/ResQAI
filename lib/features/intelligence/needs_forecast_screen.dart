import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';

class NeedsForecastScreen extends StatefulWidget {
  const NeedsForecastScreen({super.key});

  @override
  State<NeedsForecastScreen> createState() => _NeedsForecastScreenState();
}

class _NeedsForecastScreenState extends State<NeedsForecastScreen> {
  String _selectedDistrict = 'East Delhi (Population Exposure: 18,400)';

  final List<Map<String, dynamic>> _demandData = [
    {
      'item': 'Potable Drinking Water (Litres)',
      'forecast': 55200, // 3L per person per day
      'staged': 38000,
      'unit': 'Litres',
      'shortfall': 17200,
      'confidence': '±6.2%',
    },
    {
      'item': 'Dry Food Rations (Packets)',
      'forecast': 18400,
      'staged': 16500,
      'unit': 'Packets',
      'shortfall': 1900,
      'confidence': '±4.8%',
    },
    {
      'item': 'Waterproof Tarpaulins / Tents',
      'forecast': 3200,
      'staged': 3500,
      'unit': 'Sheets',
      'shortfall': 0, // Surplus
      'confidence': '±8.1%',
    },
    {
      'item': 'First Aid & ORS Medical Kits',
      'forecast': 2800,
      'staged': 1200,
      'unit': 'Kits',
      'shortfall': 1600,
      'confidence': '±9.4%',
    },
    {
      'item': 'NDRF Inflatable Motor Boats',
      'forecast': 14,
      'staged': 10,
      'unit': 'Boats',
      'shortfall': 4,
      'confidence': '±0%',
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
          horizontal: isMobile ? 16 : 32,
          vertical: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Description Card
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
                      color: AppColors.successGreen.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.inventory, color: AppColors.successGreen, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Probabilistic Disaster Relief Supply & Demand Forecasting',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Estimates local consumption needs using population census density, flood depth duration, and verified intake claims.',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // District Selector
            DropdownButtonFormField<String>(
              value: _selectedDistrict,
              decoration: InputDecoration(
                labelText: 'Target Affected District / Ward',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              items: [
                'East Delhi (Population Exposure: 18,400)',
                'North East Delhi - Seelampur Ward (Population: 26,000)',
                'Central Delhi - Yamuna Khadar (Population: 8,200)',
              ].map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedDistrict = v);
              },
            ),
            const SizedBox(height: 22),

            // Demand vs Staged Comparison Table
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Relief Inventory vs Forecasted Demand', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 16),
                  for (final item in _demandData) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item['item'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Row(
                                children: [
                                  Text(
                                    '${item['staged']} / ${item['forecast']} ${item['unit']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  const SizedBox(width: 8),
                                  if ((item['shortfall'] as int) > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.criticalRed.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '-${item['shortfall']} SHORTFALL',
                                        style: const TextStyle(color: AppColors.criticalRed, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.successGreen.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'ADEQUATE',
                                        style: TextStyle(color: AppColors.successGreen, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (item['staged'] as int) / (item['forecast'] as int),
                              minHeight: 8,
                              backgroundColor: Colors.grey.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation(
                                (item['shortfall'] as int) > 0 ? AppColors.criticalRed : AppColors.successGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
