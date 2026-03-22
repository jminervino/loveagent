import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) throw Exception('Falha no login');

    return _fetchOrCreateUserProfile(user);
  }

  @override
  Future<AppUser> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) throw Exception('Falha no cadastro');

    // Create user profile in our users table
    await _client.from('users').insert({
      'id': user.id,
      'email': email,
      'name': name,
    });

    return UserModel(
      id: user.id,
      email: email,
      name: name,
      plan: 'free',
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    return _fetchOrCreateUserProfile(user);
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user == null) return null;
      return _fetchOrCreateUserProfile(user);
    });
  }

  @override
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<AppUser> _fetchOrCreateUserProfile(User user) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response != null) {
      return UserModel.fromMap(response);
    }

    // First login — create profile
    final newUser = {
      'id': user.id,
      'email': user.email ?? '',
      'name': user.userMetadata?['name'],
    };
    await _client.from('users').insert(newUser);
    return UserModel.fromMap(newUser);
  }
}
