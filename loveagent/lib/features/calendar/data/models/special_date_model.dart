import '../../domain/entities/special_date.dart';

class SpecialDateModel extends SpecialDate {
  const SpecialDateModel({
    required super.id,
    required super.partnerId,
    required super.label,
    required super.date,
    super.isAnnual,
    super.isSystem,
    super.partnerName,
    super.nextOccurrence,
    super.daysUntil,
  });

  factory SpecialDateModel.fromMap(Map<String, dynamic> map) {
    return SpecialDateModel(
      id: map['id'] as String,
      partnerId: map['partner_id'] as String,
      label: map['label'] as String,
      date: DateTime.parse(map['date'] as String),
      isAnnual: map['is_annual'] as bool? ?? true,
      isSystem: map['is_system'] as bool? ?? false,
    );
  }

  /// From the get_upcoming_dates() RPC function result
  factory SpecialDateModel.fromUpcomingMap(Map<String, dynamic> map) {
    return SpecialDateModel(
      id: map['date_id'] as String,
      partnerId: map['partner_id'] as String,
      label: map['label'] as String,
      date: DateTime.parse(map['next_occurrence'] as String),
      partnerName: map['partner_name'] as String?,
      nextOccurrence: DateTime.parse(map['next_occurrence'] as String),
      daysUntil: map['days_until'] as int?,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'partner_id': partnerId,
      'label': label,
      'date': date.toIso8601String().split('T').first,
      'is_annual': isAnnual,
      'is_system': false, // user-created dates are never system
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'label': label,
      'date': date.toIso8601String().split('T').first,
      'is_annual': isAnnual,
    };
  }
}
