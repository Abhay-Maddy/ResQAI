enum AlertAgency {
  imd('IMD', 'India Meteorological Department'),
  ndma('NDMA', 'National Disaster Management Authority'),
  gdacs('GDACS', 'Global Disaster Alert and Coordination System');

  final String code;
  final String fullName;
  const AlertAgency(this.code, this.fullName);
}

enum AlertSeverity {
  red('Red / Evacuate Immediately'),
  orange('Orange / Be Prepared'),
  yellow('Yellow / Be Updated'),
  green('Green / Advisory');

  final String label;
  const AlertSeverity(this.label);
}

class AlertModel {
  final String id;
  final AlertAgency agency;
  final String headline;
  final String description;
  final AlertSeverity severity;
  final String affectedRegion;
  final DateTime issuedAt;
  final DateTime lastFetchedAt;
  final bool isOfficial;

  AlertModel({
    required this.id,
    required this.agency,
    required this.headline,
    required this.description,
    required this.severity,
    required this.affectedRegion,
    required this.issuedAt,
    required this.lastFetchedAt,
    this.isOfficial = true,
  });
}
