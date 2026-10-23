import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/incident_repository.dart';

class AiFeedbackWidget extends ConsumerStatefulWidget {
  final String targetId;
  final String featureName;

  const AiFeedbackWidget({
    super.key,
    required this.targetId,
    required this.featureName,
  });

  @override
  ConsumerState<AiFeedbackWidget> createState() => _AiFeedbackWidgetState();
}

class _AiFeedbackWidgetState extends ConsumerState<AiFeedbackWidget> {
  String? _selectedRating;

  void _submitFeedback(String rating) {
    setState(() => _selectedRating = rating);
    ref.read(aiFeedbackProvider.notifier).recordFeedback(
      widget.targetId,
      widget.featureName,
      rating,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('AI Feedback ($rating) recorded for ${widget.featureName} [v1.4-RulesEngine]. Saved to audit trail.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.rate_review, size: 14, color: AppColors.primaryLight),
          const SizedBox(width: 6),
          const Text('AI Accuracy Feedback:', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(width: 8),
          _RatingButton(
            label: 'Accurate',
            icon: Icons.thumb_up_alt_outlined,
            activeColor: AppColors.verifiedGreen,
            isSelected: _selectedRating == 'CORRECT',
            onTap: () => _submitFeedback('CORRECT'),
          ),
          const SizedBox(width: 4),
          _RatingButton(
            label: 'Inaccurate',
            icon: Icons.thumb_down_alt_outlined,
            activeColor: AppColors.criticalRed,
            isSelected: _selectedRating == 'INCORRECT',
            onTap: () => _submitFeedback('INCORRECT'),
          ),
          const SizedBox(width: 4),
          _RatingButton(
            label: 'Uncertain',
            icon: Icons.help_outline,
            activeColor: AppColors.warningAmber,
            isSelected: _selectedRating == 'UNCERTAIN',
            onTap: () => _submitFeedback('UNCERTAIN'),
          ),
        ],
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color activeColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label,
    required this.icon,
    required this.activeColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: isSelected ? Border.all(color: activeColor) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isSelected ? activeColor : Colors.grey),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? activeColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
