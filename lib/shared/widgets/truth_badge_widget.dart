import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum TruthBadgeType {
  officialAlert('OFFICIAL ALERT', AppColors.criticalRed, Icons.verified_user),
  citizenReport('COMMUNITY REPORT', AppColors.infoBlue, Icons.person_pin),
  aiAssisted('AI ASSISTED', AppColors.unverifiedPurple, Icons.psychology),
  verifiedSafe('VERIFIED SAFE', AppColors.verifiedGreen, Icons.check_circle),
  notVerifiedSafe('NOT VERIFIED SAFE ROUTE', AppColors.criticalRed, Icons.warning_amber),
  piiMasked('DPDP PII MASKED', AppColors.warningAmber, Icons.lock_outline),
  staleData('STALE DATA (>4h)', AppColors.warningAmber, Icons.access_time);

  final String label;
  final Color color;
  final IconData icon;
  const TruthBadgeType(this.label, this.color, this.icon);
}

class TruthBadgeWidget extends StatelessWidget {
  final TruthBadgeType type;
  final String? customText;

  const TruthBadgeWidget({
    super.key,
    required this.type,
    this.customText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: type.color.withOpacity(0.15),
        border: Border.all(color: type.color, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 13, color: type.color),
          const SizedBox(width: 4),
          Text(
            customText ?? type.label,
            style: TextStyle(
              color: type.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
