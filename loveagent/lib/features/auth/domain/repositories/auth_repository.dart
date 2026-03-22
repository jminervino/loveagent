import '../entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser> signInWithEmail(String email, String password);
  Future<AppUser> signUpWithEmail(String email, String password, String name);
  Future<void> signOut();
  Future<AppUser?> getCurrentUser();
  Stream<AppUser?> authStateChanges();
  Future<void> resetPassword(String email);
}
