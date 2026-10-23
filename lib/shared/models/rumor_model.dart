enum RumorStatus {
  investigating('Under Investigation', 'Claim undergoing field and official verification'),
  debunked('Debunked / False', 'Proved incorrect by district administration'),
  confirmed('Confirmed Fact', 'Verified by on-ground authorities');

  final String label;
  final String description;
  const RumorStatus(this.label, this.description);
}

class RumorModel {
  final String id;
  final String claimText;
  final String sourceChannel; // WhatsApp Forward, Twitter, Community Word
  final String reportedRegion;
  final int reportsCount;
  final RumorStatus status;
  final String officialFactCheck;
  final DateTime firstReported;
  final DateTime lastUpdated;

  RumorModel({
    required this.id,
    required this.claimText,
    required this.sourceChannel,
    required this.reportedRegion,
    required this.reportsCount,
    required this.status,
    required this.officialFactCheck,
    required this.firstReported,
    required this.lastUpdated,
  });
}
