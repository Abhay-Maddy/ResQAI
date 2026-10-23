import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';

class RiskForecastScreen extends StatefulWidget {
  const RiskForecastScreen({super.key});

  @override
  State<RiskForecastScreen> createState() => _RiskForecastScreenState();
}

class _RiskForecastScreenState extends State<RiskForecastScreen> {
  String _selectedHorizon = '24h'; // '6h', '24h', '48h'
  String _selectedSector = 'Yamuna Basin (East Delhi)';

  final List<Map<String, dynamic>> _sectorForecasts = [
    {
      'sector': 'Yamuna Basin (East Delhi)',
      'riskScore': 88.5,
      'category': 'Riverine Inundation',
      'confidence': 91.2,
      'waterLevelForecast': '206.45m (Danger Level: 205.33m)',
      'contributingFeatures': [
        {'name': 'Hathnikund Barrage Discharge', 'impact': '+42%'},
        {'name': '24h Catchment Rainfall (88mm)', 'impact': '+28%'},
        {'name': 'Lowland Siltation Index', 'impact': '+18%'},
      ],
      'action': 'Issue Pre-emptive Evacuation for Ward 4 Jhuggi clusters; deploy 4 motor-boats.',
    },
    {
      'sector': 'Mayur Vihar Phase 1 Drainage Corridor',
      'riskScore': 74.0,
      'category': 'Urban Flash Waterlogging',
      'confidence': 86.4,
      'waterLevelForecast': '1.8m Street Stagnation',
      'contributingFeatures': [
        {'name': 'Peak Runoff Rate', 'impact': '+48%'},
        {'name': 'Storm Drain Inflow Capacity', 'impact': '+32%'},
      ],
      'action': 'Stage high-capacity diesel dewatering pumps at Chilla regulator.',
    },
    {
      'sector': 'Civil Lines Embankment Ridge',
      'riskScore': 38.0,
      'category': 'Moderate Seepage',
      'confidence': 94.0,
      'waterLevelForecast': 'Below Ring Road Revetment',
      'contributingFeatures': [
        {'name': 'Ring Road Bund Height', 'impact': '-35%'},
        {'name': 'Drainage Gate 12 Closure', 'impact': '+15%'},
      ],
      'action': 'Maintain 24/7 staff vigil on Ring Road sluice gates.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    final currentData = _sectorForecasts.firstWhere(
      (s) => s['sector'] == _selectedSector,
      orElse: () => _sectorForecasts.first,
    );

    return AppShell(
      currentRoute: AppRoutes.intelligenceRiskForecast,
      title: 'Geospatial Disaster Risk Forecasting',
      breadcrumbs: const ['AI Intelligence', 'Risk Forecast'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 32,
          vertical: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Model Header Card
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
                      color: AppColors.primaryBlue.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.thunderstorm, color: AppColors.primaryBlue, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hydro-Meteorological Risk Prediction Model',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Model Version: RF-Ensemble v2.4 • Trained on 1998-2025 CWC Gauges • Temporal Validation Score: 0.912 ROC-AUC',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Sector & Forecast Horizon Selector
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSector,
                    decoration: InputDecoration(
                      labelText: 'Target River Basin / Sector',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    items: _sectorForecasts.map((s) {
                      return DropdownMenuItem<String>(
                        value: s['sector'] as String,
                        child: Text(s['sector'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedSector = v);
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Row(
                  children: ['6h', '24h', '48h'].map((h) {
                    final isSel = _selectedHorizon == h;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ChoiceChip(
                        label: Text('$h Horizon'),
                        selected: isSel,
                        selectedColor: AppColors.primaryBlue,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (v) {
                          if (v) setState(() => _selectedHorizon = h);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Main Prediction Metric Cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'PREDICTED RISK INDEX',
                    value: '${currentData['riskScore']}/100',
                    subtitle: 'HIGH INUNDATION PROBABILITY',
                    color: AppColors.criticalRed,
                    icon: Icons.speed,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildMetricCard(
                    title: 'MODEL CONFIDENCE',
                    value: '${currentData['confidence']}%',
                    subtitle: '±2.4% UNCERTAINTY BAND',
                    color: AppColors.primaryBlue,
                    icon: Icons.check_circle_outline,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildMetricCard(
                    title: 'PROJECTED PEAK GAUGE',
                    value: (currentData['waterLevelForecast'] as String).split(' ').first,
                    subtitle: 'DANGER MARK: 205.33m',
                    color: AppColors.warningOrange,
                    icon: Icons.water,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Contributing Features & Explainability Table
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
                  const Text(
                    'Explainable Feature Attribution (SHAP Importance)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Identifies variables having highest relative contribution to the elevated flood risk score',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  for (final feat in currentData['contributingFeatures'] as List) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_right, color: AppColors.primaryBlue),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              feat['name'] as String,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.criticalRed.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              feat['impact'] as String,
                              style: const TextStyle(color: AppColors.criticalRed, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Suggested Preparedness Action
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield, color: AppColors.primaryBlue, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Actionable Operational Advisory',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryBlue),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentData['action'] as String,
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppColors.primaryText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey)),
        ],
      ),
    );
  }
}
