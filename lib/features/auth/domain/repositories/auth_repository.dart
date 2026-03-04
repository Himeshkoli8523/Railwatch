import 'package:cctv/features/auth/domain/entities/user_profile.dart';

/// Domain contract for authentication.
///
/// The implementation ([AuthRepositoryImpl]) decides whether to use
/// Firebase, REST API, or any other backend via [AuthDataSource].
/// Screens and use-cases depend ONLY on this interface.
abstract class AuthRepository {
  // ── Email/Password Auth (primary – Firebase or API) ──────────────────────

  /// Sign in with email and password.
  Future<UserProfile> signInWithEmailPassword({
    required String email,
    required String password,
  });

  /// Register a new account.
  Future<UserProfile> createAccount({
    required String email,
    required String password,
    required String displayName,
  });

  /// Send a password-reset email link.
  Future<void> sendPasswordResetEmail({required String email});

  /// Sign out the currently authenticated user.
  Future<void> signOut();

  /// Emits user updates when authentication state changes.
  Stream<UserProfile?> watchAuthState();

  // ── Legacy phone/token-based methods (kept for API compatibility) ─────────

  Future<bool> signup({
    required String fullName,
    required String phoneNo,
    required String password,
    required String zone,
    required String division,
    required String location,
    String? email,
  });

  Future<bool> login({required String phoneNo, required String password});

  Future<({String message, String resetToken})> forgotPassword({
    required String phoneNo,
  });

  Future<bool> changePasswordWithToken({
    required String newPassword,
    String? phoneNo,
    String? resetToken,
  });

  Future<bool> changePasswordAuthenticated({required String newPassword});

  Future<bool> refreshToken();

  Future<UserProfile> getCurrentUser();
}
