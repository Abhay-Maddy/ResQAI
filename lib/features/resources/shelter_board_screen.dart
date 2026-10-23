import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/incident_repository.dart';
import '../../shared/widgets/truth_badge_widget.dart';

class ShelterBoardScreen extends ConsumerWidget {
  const ShelterBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shelters = ref.watch(sheltersProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.night_shelter, color: AppColors.primaryLight, size: 28),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Shelter & Relief Material Capacity Board', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Tracks configured emergency camps, remaining bed capacity, and drinking water/food stocks.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text('Add Designated Shelter', style: TextStyle(color: Colors.white, fontSize: 12)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('District Collector authorization verified. New shelter modal opened.')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Grid of Shelters (Feature 20)
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 3 : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 310,
                ),
                itemCount: shelters.length,
                itemBuilder: (context, idx) {
                  final sh = shelters[idx];
                  final isStale = sh.isCapacityStale;
                  final occupancyRate = sh.occupancyRate;

                  return Card(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: isStale ? AppColors.warningAmber : AppColors.darkBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(sh.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2),
                              ),
                              if (isStale)
                                const TruthBadgeWidget(type: TruthBadgeType.staleData)
                              else
                                const TruthBadgeWidget(type: TruthBadgeType.verifiedSafe),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(sh.address, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1),
                          const Divider(height: 16),

                          // Capacity Progress Bar
                          Row(
                            children: [
                              Text('Occupancy: ${sh.occupiedBeds} / ${sh.totalCapacity} beds', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text('${(occupancyRate * 100).toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.bold, color: occupancyRate > 0.8 ? AppColors.criticalRed : AppColors.primaryLight)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: occupancyRate,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation<Color>(occupancyRate > 0.8 ? AppColors.criticalRed : AppColors.primary),
                          ),
                          const SizedBox(height: 12),

                          // Food & Water Inventory
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(6)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Drinking Water', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      Text('${sh.waterLitersStock} L', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.infoBlue)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(6)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Meals / Rations', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      Text('${sh.foodMealsStock} units', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accent)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          Row(
                            children: [
                              Icon(sh.hasMedicalUnit ? Icons.medical_services : Icons.info_outline, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(sh.hasMedicalUnit ? 'Medical Post Active' : 'No On-Site Doctor', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              const Spacer(),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryDark,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                onPressed: () {
                                  ref.read(sheltersProvider.notifier).updateOccupancy(sh.id, sh.occupiedBeds + 10);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Recorded 10 incoming evacuees at ${sh.name}. Capacity updated.')),
                                  );
                                },
                                child: const Text('+10 Evacuees', style: TextStyle(fontSize: 11, color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
