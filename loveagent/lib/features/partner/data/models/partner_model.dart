import '../../domain/entities/partner.dart';

class PartnerModel extends Partner {
  const PartnerModel({
    required super.id,
    required super.userId,
    required super.name,
    super.birthDate,
    super.relationshipStart,
    super.status,
    super.likes,
    super.dislikes,
    super.budgetLevel,
    super.notes,
    super.photoUrl,
    super.isActive,
    super.createdAt,
  });

  factory PartnerModel.fromMap(Map<String, dynamic> map) {
    return PartnerModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      birthDate: map['birth_date'] != null
          ? DateTime.parse(map['birth_date'] as String)
          : null,
      relationshipStart: map['relationship_start'] != null
          ? DateTime.parse(map['relationship_start'] as String)
          : null,
      status: map['status'] as String? ?? 'namorada',
      likes: (map['likes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      dislikes: (map['dislikes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      budgetLevel: map['budget_level'] as String? ?? 'moderado',
      notes: map['notes'] as String?,
      photoUrl: map['photo_url'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'name': name,
      'birth_date': birthDate?.toIso8601String().split('T').first,
      'relationship_start':
          relationshipStart?.toIso8601String().split('T').first,
      'status': status,
      'likes': likes,
      'dislikes': dislikes,
      'budget_level': budgetLevel,
      'notes': notes,
      'photo_url': photoUrl,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'birth_date': birthDate?.toIso8601String().split('T').first,
      'relationship_start':
          relationshipStart?.toIso8601String().split('T').first,
      'status': status,
      'likes': likes,
      'dislikes': dislikes,
      'budget_level': budgetLevel,
      'notes': notes,
      'photo_url': photoUrl,
    };
  }
}
