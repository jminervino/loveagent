import '../../domain/entities/special_date.dart';

class SpecialDateModel extends SpecialDate {
  const SpecialDateModel({
    required super.id,
    required super.partnerId,
    required super.label,
    required super.date,
    super.isAnnual,
    super.isSystem,
    super.recurrence,
    super.partnerName,
    super.nextOccurrence,
    super.daysUntil,
  });

  static Recurrence _parseRecurrence(String? value) {
    switch (value) {
      case 'monthly':
        return Recurrence.monthly;
      case 'once':
        return Recurrence.once;
      case 'annual':
      default:
        return Recurrence.annual;
    }
  }

  static String _recurrenceToString(Recurrence r) {
    switch (r) {
      case Recurrence.monthly:
        return 'monthly';
      case Recurrence.once:
        return 'once';
      case Recurrence.annual:
        return 'annual';
    }
  }

  factory SpecialDateModel.fromMap(Map<String, dynamic> map) {
    final recurrence = _parseRecurrence(map['recurrence'] as String?);
    return SpecialDateModel(
      id: map['id'] as String,
      partnerId: map['partner_id'] as String,
      label: map['label'] as String,
      date: DateTime.parse(map['date'] as String),
      isAnnual: map['is_annual'] as bool? ?? true,
      isSystem: map['is_system'] as bool? ?? false,
      recurrence: recurrence,
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
      'is_annual': recurrence == Recurrence.annual,
      'is_system': false,
      'recurrence': _recurrenceToString(recurrence),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'label': label,
      'date': date.toIso8601String().split('T').first,
      'is_annual': recurrence == Recurrence.annual,
      'recurrence': _recurrenceToString(recurrence),
    };
  }
}
