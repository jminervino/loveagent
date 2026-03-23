import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/special_date.dart';
import 'urgency_badge.dart';

class DateCard extends StatelessWidget {
  const DateCard({
    super.key,
    required this.date,
    this.onTap,
    this.onDelete,
    this.showPartnerName = true,
  });

  final SpecialDate date;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showPartnerName;

  @override
  Widget build(BuildContext context) {
    final displayDate = date.nextOccurrence ?? date.date;
    final dayFormat = DateFormat('dd');
    final monthFormat = DateFormat('MMM', 'pt_BR');

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Date box
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayFormat.format(displayDate),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      monthFormat.format(displayDate).toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            date.label,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        UrgencyBadge(date: date),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (showPartnerName && date.partnerName != null) ...[
                          Icon(Icons.person, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            date.partnerName!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (date.recurrence == Recurrence.monthly)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.repeat, size: 14, color: AppColors.tertiary),
                              const SizedBox(width: 2),
                              Text('Mensal', style: TextStyle(fontSize: 10, color: AppColors.tertiary)),
                            ],
                          )
                        else if (date.isAnnual)
                          Icon(Icons.repeat, size: 14, color: AppColors.textSecondary),
                        if (date.isSystem) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.auto_fix_high, size: 14, color: AppColors.textSecondary),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Delete (only for non-system dates)
              if (!date.isSystem && onDelete != null)
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
