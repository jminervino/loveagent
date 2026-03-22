import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    this.name,
    this.plan = 'free',
    this.createdAt,
  });

  final String id;
  final String email;
  final String? name;
  final String plan;
  final DateTime? createdAt;

  bool get isPremium => plan == 'premium';

  @override
  List<Object?> get props => [id, email, name, plan];
}
