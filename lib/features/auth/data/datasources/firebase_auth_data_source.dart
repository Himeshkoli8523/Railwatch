import 'package:cctv/features/auth/data/datasources/auth_data_source.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase implementation of [AuthDataSource].
///
/// To switch to REST API auth, create an [ApiAuthDataSource] that implements
/// [AuthDataSource] and swap this class in the Riverpod provider — nothing
/// else changes (domain, screens, controller all stay identical).
class FirebaseAuthDataSource implements AuthDataSource {
  FirebaseAuthDataSource({FirebaseAuth? firebaseAuth})
    : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  final Map<String, Map<String, dynamic>> _claimsCache = {};

  @override
  Future<AuthUserDto> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _toDto(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e.code), code: e.code);
    }
  }

  @override
  Future<AuthUserDto> createUserWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user!.updateDisplayName(displayName);
      await credential.user!.reload();
      return _toDto(_auth.currentUser!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e.code), code: e.code);
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e.code), code: e.code);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Stream<AuthUserDto?> get authStateChanges => _auth
      .authStateChanges()
      .asyncMap((u) async => u == null ? null : _toDto(u));

  @override
  AuthUserDto? get currentUser {
    final u = _auth.currentUser;
    if (u == null) return null;
    return AuthUserDto(
      uid: u.uid,
      email: u.email ?? '',
      displayName: u.displayName,
      claims: _claimsCache[u.uid] ?? const {},
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<AuthUserDto> _toDto(User user) async {
    Map<String, dynamic> claims = _claimsCache[user.uid] ?? const {};
    try {
      final token = await user.getIdTokenResult();
      claims = Map<String, dynamic>.from(token.claims ?? const {});
      _claimsCache[user.uid] = claims;
    } catch (_) {}

    return AuthUserDto(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      claims: claims,
    );
  }

  static String _friendlyMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
