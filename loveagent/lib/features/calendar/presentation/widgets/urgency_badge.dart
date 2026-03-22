import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/special_date.dart';

class UrgencyBadge extends StatelessWidget {
  const UrgencyBadge({super.key, required this.date});

  final SpecialDate date;

  @override
  Widget build(BuildContext context) {
    final urgency = date.urgency;
    if (urgency == UrgencyLevel.none) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color(urgency),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        date.urgencyLabel,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _color(UrgencyLevel level) {
    switch (level) {
      case UrgencyLevel.critical:
        return AppColors.error;
      case UrgencyLevel.high:
        return AppColors.accent;
      case UrgencyLevel.medium:
        return Colors.amber.shade700;
      case UrgencyLevel.low:
        return AppColors.success;
      case UrgencyLevel.none:
        return Colors.transparent;
    }
  }
}
