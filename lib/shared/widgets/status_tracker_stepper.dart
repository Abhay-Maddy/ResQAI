import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

class StatusTrackerStepper extends StatelessWidget {
  final IncidentStatus currentStatus;

  const StatusTrackerStepper({
    super.key,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final stages = [
      {'status': IncidentStatus.received, 'title': 'Received', 'desc': 'Logged into triage queue'},
      {'status': IncidentStatus.underReview, 'title': 'Under Review', 'desc': 'AI similarity & risk check'},
      {'status': IncidentStatus.verified, 'title': 'Verified', 'desc': 'Confirmed by responder'},
      {'status': IncidentStatus.helpAssigned, 'title': 'Help Assigned', 'desc': 'Rescue unit dispatched'},
    ];

    int currentIndex = stages.indexWhere((s) => s['status'] == currentStatus);
    if (currentIndex == -1 && currentStatus == IncidentStatus.resolved) {
      currentIndex = 3;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return isMobile
            ? Column(
                children: List.generate(stages.length, (index) {
                  final stage = stages[index];
                  final isPassed = index <= currentIndex;
                  final isCurrent = index == currentIndex;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: isPassed ? AppColors.primary : AppColors.darkBorder,
                          child: isPassed
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : Text('${index + 1}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stage['title'] as String,
                              style: TextStyle(
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                color: isPassed ? AppColors.primaryLight : Colors.grey,
                              ),
                            ),
                            Text(
                              stage['desc'] as String,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              )
            : Row(
                children: List.generate(stages.length, (index) {
                  final stage = stages[index];
                  final isPassed = index <= currentIndex;
                  final isCurrent = index == currentIndex;

                  return Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: isPassed ? AppColors.primary : AppColors.darkBorder,
                          child: isPassed
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : Text('${index + 1}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                stage['title'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                  color: isPassed ? AppColors.primaryLight : Colors.grey,
                                ),
                              ),
                              Text(
                                stage['desc'] as String,
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (index < stages.length - 1)
                          Container(
                            width: 24,
                            height: 2,
                            color: isPassed && index < currentIndex ? AppColors.primary : AppColors.darkBorder,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                      ],
                    ),
                  );
                }),
              );
      },
    );
  }
}
