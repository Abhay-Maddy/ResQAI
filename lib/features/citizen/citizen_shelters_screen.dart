import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';
import '../../data/repositories/incident_repository.dart';

class CitizenSheltersScreen extends ConsumerStatefulWidget {
  const CitizenSheltersScreen({super.key});

  @override
  ConsumerState<CitizenSheltersScreen> createState() => _CitizenSheltersScreenState();
}

class _CitizenSheltersScreenState extends ConsumerState<CitizenSheltersScreen> {
  String _filter = 'ALL'; // 'ALL', 'AVAILABLE', 'MEDICAL'
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shelters = ref.watch(sheltersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    final query = _searchController.text.toLowerCase().trim();
    final filteredShelters = shelters.where((s) {
      if (query.isNotEmpty && !s.name.toLowerCase().contains(query) && !s.address.toLowerCase().contains(query)) {
        return false;
      }
      if (_filter == 'AVAILABLE' && s.occupiedBeds >= s.totalCapacity) {
        return false;
      }
      if (_filter == 'MEDICAL' && !s.hasMedicalUnit) {
        return false;
      }
      return true;
    }).toList();

    return AppShell(
      currentRoute: AppRoutes.citizenShelters,
      title: 'Verified Relief Shelters',
      breadcrumbs: const ['Citizen', 'Find Shelter'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header summary
            Container(
              padding: const EdgeInsets.all(18),
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
                    child: const Icon(Icons.night_shelter, color: AppColors.successGreen, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verified Emergency Shelters & Safe Havens',
                          style: TextStyle(
                            fontSize: isMobile ? 15 : 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.deepNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Government & NGO coordinated evacuation centers equipped with food, water, sanitation, and medical units.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search and filter chips
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by shelter name or sector...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.citizenMap),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('View on Map'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All Shelters (${shelters.length})', _filter == 'ALL', () => setState(() => _filter = 'ALL')),
                  const SizedBox(width: 8),
                  _buildFilterChip('Available Space Only', _filter == 'AVAILABLE', () => setState(() => _filter = 'AVAILABLE'), color: AppColors.successGreen),
                  const SizedBox(width: 8),
                  _buildFilterChip('With Medical Unit', _filter == 'MEDICAL', () => setState(() => _filter = 'MEDICAL'), color: AppColors.primaryBlue),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Shelters list
            if (filteredShelters.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.night_shelter_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No shelters matching your filter criteria.', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredShelters.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final s = filteredShelters[index];
                  final remaining = s.totalCapacity - s.occupiedBeds;
                  final occPercent = (s.occupiedBeds / (s.totalCapacity == 0 ? 1 : s.totalCapacity) * 100).clamp(0, 100);
                  final isFull = remaining <= 0;

                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (isFull ? AppColors.emergencyRed : AppColors.successGreen).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.night_shelter,
                                color: isFull ? AppColors.emergencyRed : AppColors.successGreen,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : AppColors.deepNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    s.address,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isFull ? AppColors.emergencyRed.withOpacity(0.15) : AppColors.successGreen.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isFull ? 'AT CAPACITY' : '$remaining BEDS OPEN',
                                style: TextStyle(
                                  color: isFull ? AppColors.emergencyRed : AppColors.successGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Capacity Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Occupancy: ${s.occupiedBeds} / ${s.totalCapacity} beds (${occPercent.toStringAsFixed(0)}%)',
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w600),
                            ),
                            if (s.isCapacityStale)
                              const Text('⚠️ Stale (>4h ago)', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: s.occupiedBeds / (s.totalCapacity == 0 ? 1 : s.totalCapacity),
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isFull ? AppColors.emergencyRed : (occPercent > 75 ? AppColors.warningOrange : AppColors.successGreen),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Stocks & Amenities
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildAmenityChip(Icons.water_drop, '${s.waterLitersStock}L Safe Water', AppColors.primaryBlue),
                            _buildAmenityChip(Icons.restaurant, '${s.foodMealsStock} Ready Meals', AppColors.warningOrange),
                            if (s.hasMedicalUnit)
                              _buildAmenityChip(Icons.medical_services, 'On-site Medical Post', AppColors.successGreen)
                            else
                              _buildAmenityChip(Icons.info_outline, 'No Resident Doctor', Colors.grey),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Navigation route to ${s.name} loaded on map.'),
                                    backgroundColor: AppColors.primaryBlue,
                                  ),
                                );
                                Navigator.pushNamed(context, AppRoutes.citizenMap);
                              },
                              icon: const Icon(Icons.directions, size: 16),
                              label: const Text('Get Directions'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryBlue,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text('Evacuate to ${s.name}'),
                                    content: Text(
                                      'Safe Zone Address: ${s.address}\n\n'
                                      'Available Beds: $remaining\n'
                                      'Emergency Contact: 1077 (District Control Room)\n\n'
                                      'Do you wish to confirm your family\'s check-in reservation?',
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Reservation registered! Present your ResQAI QR code at reception.'),
                                              backgroundColor: AppColors.successGreen,
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.successGreen, foregroundColor: Colors.white),
                                        child: const Text('Confirm Reservation'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.check_circle_outline, size: 16),
                              label: const Text('Reserve Space'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFull ? Colors.grey : AppColors.successGreen,
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, {Color? color}) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: (color ?? AppColors.primaryBlue).withOpacity(0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isSelected ? (color ?? AppColors.primaryBlue) : Colors.black87,
      ),
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildAmenityChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
