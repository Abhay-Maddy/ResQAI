import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';

class ScenarioSimulationScreen extends StatefulWidget {
  const ScenarioSimulationScreen({super.key});

  @override
  State<ScenarioSimulationScreen> createState() => _ScenarioSimulationScreenState();
}

class _ScenarioSimulationScreenState extends State<ScenarioSimulationScreen> {
  bool _bridgeCollapseSimulation = false;
  bool _additionalShelterOpened = true;
  double _additionalRainfallSurge = 50.0; // mm

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    // Simulation calculated results
    final estimatedResponseTimeMin = _bridgeCollapseSimulation ? 38 : 14;
    final shelterCapacityDeficit = _additionalShelterOpened ? 0 : 850;
    final projectedInundatedAreaSqKm = 4.2 + (_additionalRainfallSurge * 0.08);

    return AppShell(
      currentRoute: AppRoutes.intelligenceSimulation,
      title: 'ResponseTwin Disaster Scenario Simulation',
      breadcrumbs: const ['AI Intelligence', 'Simulation Sandbox'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Watermark Banner (Honesty & Demonstration Principle)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.science, color: Colors.amber, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SIMULATION SANDBOX • NOT REAL-WORLD LIVE DISASTER EVENT',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber),
                        ),
                        Text(
                          'ResponseTwin computational sandbox for DDMA officials to evaluate "what-if" operational stress tests.',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Simulation Controls
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
                  const Text('Scenario Parameters & Constraint Knobs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Simulate Old Yamuna Railway Bridge Inundation (Bridge Closed)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: const Text('Forces all relief traffic across Signature Bridge (adds route detours)'),
                    value: _bridgeCollapseSimulation,
                    activeColor: AppColors.criticalRed,
                    onChanged: (v) => setState(() => _bridgeCollapseSimulation = v),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Simulate Opening Mayur Vihar Stadium Relief Shelter (+1,200 beds)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: const Text('Evaluates bed occupancy distribution relief in East Delhi'),
                    value: _additionalShelterOpened,
                    activeColor: AppColors.successGreen,
                    onChanged: (v) => setState(() => _additionalShelterOpened = v),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Simulate Cloudburst Rainfall Surge in 6h Horizon', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('+${_additionalRainfallSurge.toStringAsFixed(0)} mm', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                          ],
                        ),
                        Slider(
                          value: _additionalRainfallSurge,
                          min: 0,
                          max: 150,
                          divisions: 15,
                          activeColor: AppColors.primaryBlue,
                          onChanged: (v) => setState(() => _additionalRainfallSurge = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Projected Simulation Outcomes
            const Text('Projected Operational Outcomes Under Current Simulation:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _buildOutcomeCard(
                    title: 'MEAN RESPONSE TIME',
                    value: '$estimatedResponseTimeMin mins',
                    status: _bridgeCollapseSimulation ? 'HIGH DELAY DETOUR' : 'ACCEPTABLE SLA',
                    color: _bridgeCollapseSimulation ? AppColors.criticalRed : AppColors.successGreen,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildOutcomeCard(
                    title: 'SHELTER DEFICIT',
                    value: '$shelterCapacityDeficit beds',
                    status: _additionalShelterOpened ? 'SUFFICIENT CAPACITY' : 'OVERCROWDED',
                    color: _additionalShelterOpened ? AppColors.successGreen : AppColors.criticalRed,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildOutcomeCard(
                    title: 'PROJECTED FLOOD AREA',
                    value: '${projectedInundatedAreaSqKm.toStringAsFixed(1)} km²',
                    status: 'INUNDATION EXTENT',
                    color: AppColors.primaryBlue,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutcomeCard({
    required String title,
    required String value,
    required String status,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
