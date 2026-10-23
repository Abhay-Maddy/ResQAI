import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/incident_repository.dart';
import '../../shared/models/incident_model.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';

class CitizenReportDetailScreen extends ConsumerWidget {
  final String incidentId;

  const CitizenReportDetailScreen({super.key, required this.incidentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidents = ref.watch(incidentsProvider);
    final incident = incidents.firstWhere(
      (i) => i.id == incidentId,
      orElse: () => incidents.first,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return AppShell(
      currentRoute: '${AppRoutes.citizenReports}/$incidentId',
      title: 'Report #${incident.id}',
      breadcrumbs: ['Citizen', 'Reports', incident.id],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 32,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. TOP HEADER BANNER
                _buildHeaderBanner(context, incident, isDark, isMobile),
                const SizedBox(height: 20),

                // 2. 10-STAGE VERIFICATION TIMELINE
                _buildVerificationTimeline(context, incident, isDark),
                const SizedBox(height: 20),

                // 3. CASE REVIEW & SANCTION NOTES
                _buildReviewerNotesCard(context, incident, isDark),
                const SizedBox(height: 20),

                // 4. CLAIM DETAILS & ECONOMIC LOSS
                _buildClaimDetailsCard(context, incident, isDark, isMobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(BuildContext context, IncidentModel incident, bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.verified_outlined, color: AppColors.primaryBlue, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Case ID: ${incident.id}',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.deepNavy,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.successGreen.withOpacity(0.4)),
                      ),
                      child: Text(
                        incident.status.label.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.successGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  incident.title,
                  style: TextStyle(
                    fontSize: isMobile ? 15 : 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Location: ${incident.address} • Filed: ${incident.reportedAt.toLocal().toString().substring(0, 16)}',
                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationTimeline(BuildContext context, IncidentModel incident, bool isDark) {
    final stages = [
      {'title': 'Submitted', 'desc': 'Logged into intake queue', 'done': true},
      {'title': 'Under Review', 'desc': 'District Disaster Board review', 'done': incident.status != IncidentStatus.received},
      {'title': 'Verification Assigned', 'desc': 'Field Patwari allocated', 'done': incident.reviewerName != null},
      {'title': 'Verified', 'desc': 'Loss confirmed by inspector', 'done': incident.status == IncidentStatus.verified || incident.status == IncidentStatus.helpAssigned || incident.status == IncidentStatus.resolved},
      {'title': 'Assistance Sanctioned', 'desc': 'SDRF Grant Sanctioned', 'done': incident.status == IncidentStatus.verified || incident.status == IncidentStatus.helpAssigned || incident.status == IncidentStatus.resolved},
      {'title': 'Relief Delivered', 'desc': 'Direct Benefit Transfer / Kits', 'done': incident.status == IncidentStatus.resolved},
    ];

    return Container(
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
            'Official 6-Stage Relief Verification Progress',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 18),
          for (int i = 0; i < stages.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: stages[i]['done'] as bool ? AppColors.successGreen : Colors.grey.withOpacity(0.3),
                      ),
                      child: Icon(
                        stages[i]['done'] as bool ? Icons.check : Icons.circle,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    if (i < stages.length - 1)
                      Container(
                        width: 2,
                        height: 32,
                        color: stages[i]['done'] as bool ? AppColors.successGreen : Colors.grey.withOpacity(0.3),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stages[i]['title'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: stages[i]['done'] as bool ? (isDark ? Colors.white : AppColors.deepNavy) : Colors.grey,
                          ),
                        ),
                        Text(
                          stages[i]['desc'] as String,
                          style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewerNotesCard(BuildContext context, IncidentModel incident, bool isDark) {
    return Container(
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
            'Authorized Officer Decision & Audit Record',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      incident.reviewerName ?? 'Dr. Rajeshwar Singh (ADM Relief)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      incident.reviewerRole ?? 'District Magistrate Relief Board',
                      style: const TextStyle(fontSize: 11, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Reason: ${incident.decisionReason ?? 'SDRF Gratuitous Cash Grant Sanctioned under Disaster Guidelines.'}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Notes: ${incident.reviewerNotes ?? 'Field Patwari verified structural wall collapse and livestock casualty. Eligible for Gratuitous DBT relief grant.'}',
                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimDetailsCard(BuildContext context, IncidentModel incident, bool isDark, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Claimed Property & Economic Loss Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 14),
          Text(incident.descriptionOriginal, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _buildInfoBadge('Estimated Loss', '₹${incident.estimatedLossInr?.toStringAsFixed(0) ?? '0'}', AppColors.primaryBlue, isDark),
              _buildInfoBadge('Household Count', '${incident.householdMembersCount} Persons', Colors.purple, isDark),
              _buildInfoBadge('Priority Score', '${incident.priorityScore.toStringAsFixed(0)}/100', AppColors.emergencyRed, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
