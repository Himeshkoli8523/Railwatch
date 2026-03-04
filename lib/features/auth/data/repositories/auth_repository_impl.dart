import 'package:cctv/core/auth/auth_policy.dart';
import 'package:cctv/features/auth/data/datasources/auth_data_source.dart';
import 'package:cctv/features/auth/data/models/user_profile_model.dart';
import 'package:cctv/features/auth/domain/entities/user_profile.dart';
import 'package:cctv/features/auth/domain/repositories/auth_repository.dart';

/// Repository implementation that delegates to [AuthDataSource].
///
/// ─────────────────────────────────────────────────────────────────────────
///  SWITCHING FROM FIREBASE → REST API:
///  In app_providers.dart, change:
///    authDataSourceProvider = Provider((_) => FirebaseAuthDataSource())
///  to:
///    authDataSourceProvider = Provider((ref) => ApiAuthDataSource(ref.watch(httpClientProvider)))
///
///  This file, all domain use-cases, and all UI screens stay UNCHANGED.
/// ─────────────────────────────────────────────────────────────────────────
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource);

  final AuthDataSource _dataSource;

  // ── Email / Password Auth ─────────────────────────────────────────────────

  @override
  Future<UserProfile> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final dto = await _dataSource.signInWithEmailPassword(
      email: email,
      password: password,
    );
    return _dtoToProfile(dto);
  }

  @override
  Future<UserProfile> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final dto = await _dataSource.createUserWithEmailPassword(
      email: email,
      password: password,
      displayName: displayName,
    );
    return _dtoToProfile(dto);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) =>
      _dataSource.sendPasswordResetEmail(email: email);

  @override
  Future<void> signOut() => _dataSource.signOut();

  @override
  Stream<UserProfile?> watchAuthState() {
    return _dataSource.authStateChanges.map(
      (dto) => dto == null ? null : _dtoToProfile(dto),
    );
  }

  // ── Legacy methods (phone/token-based, delegated to MockApiClient stub) ───

  @override
  Future<UserProfile> getCurrentUser() async {
    final u = _dataSource.currentUser;
    if (u != null) return _dtoToProfile(u);
    throw const AuthException('No authenticated user found.');
  }

  @override
  Future<bool> signup({
    required String fullName,
    required String phoneNo,
    required String password,
    required String zone,
    required String division,
    required String location,
    String? email,
  }) async => true; // Handled via createAccount for Firebase

  @override
  Future<bool> login({
    required String phoneNo,
    required String password,
  }) async => true;

  @override
  Future<({String message, String resetToken})> forgotPassword({
    required String phoneNo,
  }) async => (message: 'Use email-based reset instead.', resetToken: '');

  @override
  Future<bool> changePasswordWithToken({
    required String newPassword,
    String? phoneNo,
    String? resetToken,
  }) async => true;

  @override
  Future<bool> changePasswordAuthenticated({
    required String newPassword,
  }) async => true;

  @override
  Future<bool> refreshToken() async => true;

  // ── Helpers ───────────────────────────────────────────────────────────────

  static UserProfile _dtoToProfile(AuthUserDto dto) => UserProfileModel(
    id: dto.uid,
    name: dto.displayName ?? dto.email.split('@').first,
    role: roleFromClaims(dto.claims),
    permissions: permissionsFromClaims(
      claims: dto.claims,
      fallbackRole: roleFromClaims(dto.claims),
    ),
  );
}
