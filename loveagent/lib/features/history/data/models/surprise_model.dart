import '../../domain/entities/surprise.dart';

class SurpriseModel extends Surprise {
  const SurpriseModel({
    required super.id,
    required super.partnerId,
    required super.type,
    required super.date,
    super.note,
    super.suggestedByAgent,
    super.confirmedByUser,
    super.partnerName,
  });

  factory SurpriseModel.fromMap(Map<String, dynamic> map) {
    return SurpriseModel(
      id: map['id'] as String,
      partnerId: map['partner_id'] as String,
      type: map['type'] as String,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      suggestedByAgent: map['suggested_by_agent'] as bool? ?? false,
      confirmedByUser: map['confirmed_by_user'] as bool? ?? false,
      partnerName: map['partner_name'] as String?,
    );
  }

  factory SurpriseModel.fromMapWithPartner(Map<String, dynamic> map) {
    final partner = map['partners'] as Map<String, dynamic>?;
    return SurpriseModel(
      id: map['id'] as String,
      partnerId: map['partner_id'] as String,
      type: map['type'] as String,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      suggestedByAgent: map['suggested_by_agent'] as bool? ?? false,
      confirmedByUser: map['confirmed_by_user'] as bool? ?? false,
      partnerName: partner?['name'] as String?,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'partner_id': partnerId,
      'type': type,
      'date': date.toIso8601String().split('T').first,
      'note': note,
      'suggested_by_agent': suggestedByAgent,
      'confirmed_by_user': confirmedByUser,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'type': type,
      'date': date.toIso8601String().split('T').first,
      'note': note,
      'confirmed_by_user': confirmedByUser,
    };
  }
}
