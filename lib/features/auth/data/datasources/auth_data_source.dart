/// Abstract interface for all authentication operations.
///
/// Both [FirebaseAuthDataSource] and future [ApiAuthDataSource] implement this.
/// To switch backends: change ONE provider line in app_providers.dart.
abstract class AuthDataSource {
  /// Sign in with email and password.
  /// Throws [AuthException] on failure.
  Future<AuthUserDto> signInWithEmailPassword({
    required String email,
    required String password,
  });

  /// Create an account with email, password, and a display name.
  /// Throws [AuthException] on failure.
  Future<AuthUserDto> createUserWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  });

  /// Send a Firebase password-reset email.
  Future<void> sendPasswordResetEmail({required String email});

  /// Sign out the currently authenticated user.
  Future<void> signOut();

  /// Stream that emits a new [AuthUserDto] whenever auth state changes
  /// (login, logout, token refresh). Emits null when signed out.
  Stream<AuthUserDto?> get authStateChanges;

  /// Returns the current user or null if signed out.
  AuthUserDto? get currentUser;
}

/// Lightweight DTO carrying only the fields we need from the auth layer.
/// Keeps Firebase / API types out of the domain layer.
class AuthUserDto {
  const AuthUserDto({
    required this.uid,
    required this.email,
    this.displayName,
    this.claims = const {},
  });

  final String uid;
  final String email;
  final String? displayName;
  final Map<String, dynamic> claims;
}

/// Typed exception thrown by all [AuthDataSource] implementations.
class AuthException implements Exception {
  const AuthException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AuthException(${code ?? '?'}): $message';
}
