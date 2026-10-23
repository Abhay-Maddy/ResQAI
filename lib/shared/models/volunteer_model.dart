class VolunteerModel {
  final String id;
  final String name;
  final String phoneMasked;
  final List<String> skills; // Medical, Boating/Rescue, Translation, Chainsaw/Debris, Cooking/Logistics
  final double latitude;
  final double longitude;
  final String district;
  final bool isAvailable;
  final bool isVerified;
  final String? matchedIncidentId;

  VolunteerModel({
    required this.id,
    required this.name,
    required this.phoneMasked,
    required this.skills,
    required this.latitude,
    required this.longitude,
    required this.district,
    this.isAvailable = true,
    this.isVerified = true,
    this.matchedIncidentId,
  });
}
