import 'package:equatable/equatable.dart';

class SpecialDate extends Equatable {
  const SpecialDate({
    required this.id,
    required this.partnerId,
    required this.label,
    required this.date,
    this.isAnnual = true,
    this.isSystem = false,
    this.partnerName,
    this.nextOccurrence,
    this.daysUntil,
  });

  final String id;
  final String partnerId;
  final String label;
  final DateTime date;
  final bool isAnnual;
  final bool isSystem;

  // Computed fields (from get_upcoming_dates or local calc)
  final String? partnerName;
  final DateTime? nextOccurrence;
  final int? daysUntil;

  String get urgencyLabel {
    if (daysUntil == null) return '';
    if (daysUntil == 0) return 'Hoje!';
    if (daysUntil == 1) return 'Amanhã';
    if (daysUntil! <= 7) return 'Em $daysUntil dias';
    if (daysUntil! <= 30) return 'Em $daysUntil dias';
    return 'Em $daysUntil dias';
  }

  UrgencyLevel get urgency {
    if (daysUntil == null) return UrgencyLevel.none;
    if (daysUntil! <= 1) return UrgencyLevel.critical;
    if (daysUntil! <= 7) return UrgencyLevel.high;
    if (daysUntil! <= 15) return UrgencyLevel.medium;
    if (daysUntil! <= 30) return UrgencyLevel.low;
    return UrgencyLevel.none;
  }

  @override
  List<Object?> get props => [id, partnerId, label, date];
}

enum UrgencyLevel { critical, high, medium, low, none }
