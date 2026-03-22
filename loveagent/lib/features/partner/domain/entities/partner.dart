import 'package:equatable/equatable.dart';

class Partner extends Equatable {
  const Partner({
    required this.id,
    required this.userId,
    required this.name,
    this.birthDate,
    this.relationshipStart,
    this.status = 'namorada',
    this.likes = const [],
    this.dislikes = const [],
    this.budgetLevel = 'moderado',
    this.notes,
    this.photoUrl,
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final DateTime? birthDate;
  final DateTime? relationshipStart;
  final String status; // namorada, noiva, esposa
  final List<String> likes;
  final List<String> dislikes;
  final String budgetLevel; // economico, moderado, generoso
  final String? notes;
  final String? photoUrl;
  final bool isActive;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, userId, name, status];
}
