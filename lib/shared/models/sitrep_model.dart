class SitRepModel {
  final String id;
  final String title;
  final DateTime generatedAt;
  final String operationalSummary;
  final int totalIncidentsReported;
  final int verifiedIncidents;
  final int resolvedIncidents;
  final int activeFieldTeams;
  final int peopleSheltered;
  final List<String> criticalUncertainties;
  final Map<String, int> priorityDistribution;

  SitRepModel({
    required this.id,
    required this.title,
    required this.generatedAt,
    required this.operationalSummary,
    required this.totalIncidentsReported,
    required this.verifiedIncidents,
    required this.resolvedIncidents,
    required this.activeFieldTeams,
    required this.peopleSheltered,
    required this.criticalUncertainties,
    required this.priorityDistribution,
  });
}
