class ShelterModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int totalCapacity;
  final int occupiedBeds;
  final int waterLitersStock;
  final int foodMealsStock;
  final bool hasMedicalUnit;
  final DateTime lastUpdated;
  final bool isCapacityStale;

  ShelterModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.totalCapacity,
    required this.occupiedBeds,
    required this.waterLitersStock,
    required this.foodMealsStock,
    this.hasMedicalUnit = false,
    required this.lastUpdated,
    this.isCapacityStale = false,
  });

  int get remainingBeds => totalCapacity - occupiedBeds;
  double get occupancyRate => (occupiedBeds / totalCapacity).clamp(0.0, 1.0);
}
