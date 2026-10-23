import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';

class AnomaliesScreen extends StatefulWidget {
  const AnomaliesScreen({super.key});

  @override
  State<AnomaliesScreen> createState() => _AnomaliesScreenState();
}

class _AnomaliesScreenState extends State<AnomaliesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return AppShell(
      currentRoute: AppRoutes.intelligenceAnomalies,
      title: 'Anomaly Detection & Silent Zones',
      breadcrumbs: const ['AI Intelligence', 'Anomalies'],
      child: Column(
        children: [
          Container(
            color: isDark ? AppColors.darkSurface : Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryBlue,
              unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.mutedText,
              indicatorColor: AppColors.primaryBlue,
              tabs: const [
                Tab(icon: Icon(Icons.signal_cellular_off), text: 'Silent Telecom Zones (Underserved)'),
                Tab(icon: Icon(Icons.fact_check), text: 'Financial Ledger Anomaly Screening'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSilentZonesTab(isDark, isMobile),
                _buildFinancialAnomaliesTab(isDark, isMobile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSilentZonesTab(bool isDark, bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.criticalRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.criticalRed.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning, color: AppColors.criticalRed, size: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Telecom Blackout Alert: 2 Wards Operating with Zero Report Intake',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.criticalRed),
                      ),
                      Text(
                        'A lack of citizen reports DOES NOT indicate safety. High rainfall radar indicates potential uncontacted stranded clusters.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Silent zone card
          _buildSilentZoneCard(
            zoneName: 'Yamuna Floodplain Ward 4B (Jhuggi Embankment)',
            lastPing: '4 hours 12 mins ago (Cell Tower #DL-882 offline)',
            estimatedStranded: 1400,
            radarPrecipitation: '92mm/24h (High Hazard)',
            suggestedAction: 'Dispatch physical Ham Radio volunteer reconnaissance team with loudhailer boat.',
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildSilentZoneCard(
            zoneName: 'Chilla Lowland Agricultural Settlements',
            lastPing: '2 hours 40 mins ago',
            estimatedStranded: 850,
            radarPrecipitation: '74mm/24h',
            suggestedAction: 'Deploy drone overflight camera survey to inspect cattle shed roofs.',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSilentZoneCard({
    required String zoneName,
    required String lastPing,
    required int estimatedStranded,
    required String radarPrecipitation,
    required String suggestedAction,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(zoneName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.criticalRed.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                child: const Text('BLACKOUT ZONE', style: TextStyle(color: AppColors.criticalRed, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Last Telecom Handshake: $lastPing', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Estimated Population Exposure: $estimatedStranded Persons', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Text('Radar Rainfall: $radarPrecipitation', style: const TextStyle(fontSize: 12, color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.flight_takeoff, size: 16, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                Expanded(child: Text(suggestedAction, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialAnomaliesTab(bool isDark, bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Auditable Anti-Fraud & Duplicate Expense Screening',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Flagged transactions are automated investigation signals requiring review by District Audit Officers.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TX-ANOMALY-8891: High-Frequency Fuel Vouchers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                      child: const Text('INVESTIGATION SIGNAL', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Entity: Relief Logistics Unit 4 • ₹45,000 claimed across 3 identical petrol receipts within 90 minutes from the same pump ID.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(onPressed: () {}, child: const Text('Request Fuel Logbook Evidence')),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                      onPressed: () {},
                      child: const Text('Assign Officer for Physical Verification'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
