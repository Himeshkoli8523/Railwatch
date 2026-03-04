import 'dart:async';
import 'dart:convert';

import 'package:cctv/core/constants/app_constants.dart';
import 'package:cctv/core/constants/app_enums.dart';
import 'package:cctv/core/network/api_client.dart';
import 'package:cctv/core/network/mock_api_client.dart';
import 'package:cctv/features/alerts/data/repositories/alerts_repository_impl.dart';
import 'package:cctv/features/alerts/domain/entities/alert_item.dart';
import 'package:cctv/features/alerts/domain/repositories/alerts_repository.dart';
import 'package:cctv/features/auth/data/datasources/auth_data_source.dart';
import 'package:cctv/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:cctv/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:cctv/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:cctv/features/auth/domain/entities/user_profile.dart';
import 'package:cctv/features/auth/domain/repositories/auth_repository.dart';
import 'package:cctv/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:cctv/features/dashboard/domain/entities/bucket_item.dart';
import 'package:cctv/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:cctv/features/dashboard/domain/entities/report_item.dart';
import 'package:cctv/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:cctv/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:cctv/features/profile/domain/repositories/profile_repository.dart';
import 'package:cctv/features/videos/data/repositories/videos_repository_impl.dart';
import 'package:cctv/features/videos/domain/repositories/videos_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Auth Backend ─────────────────────────────────────────────────────────────
//
//  Default backend is MOCK so local/dev sign-in works without a live auth setup.
//
//  To explicitly select backend at run time:
//    flutter run --dart-define=AUTH_BACKEND=mock
//    flutter run --dart-define=AUTH_BACKEND=firebase
//
//  Optional:
//    flutter run --dart-define=AUTH_BACKEND=auto
//  (uses Firebase when available, otherwise falls back to mock)
//
//  That's it. No other file needs to change.
//

const _authBackend = String.fromEnvironment(
  'AUTH_BACKEND',
  defaultValue: 'mock',
);

final authDataSourceProvider = Provider<AuthDataSource>((_) {
  switch (_authBackend.toLowerCase()) {
    case 'firebase':
      return Firebase.apps.isEmpty
          ? MockAuthDataSource()
          : FirebaseAuthDataSource();
    case 'auto':
      return Firebase.apps.isEmpty
          ? MockAuthDataSource()
          : FirebaseAuthDataSource();
    case 'mock':
    default:
      return MockAuthDataSource();
  }
});

const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

final apiClientProvider = Provider<ApiClient>((_) {
  return ApiClient(baseUrl: _apiBaseUrl);
});

// ── Repositories ─────────────────────────────────────────────────────────────

final mockApiClientProvider = Provider<MockApiClient>((ref) => MockApiClient());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authDataSourceProvider));
});

final videosRepositoryProvider = Provider<VideosRepository>((ref) {
  return VideosRepositoryImpl(ref.watch(apiClientProvider));
});

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return AlertsRepositoryImpl(ref.watch(mockApiClientProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(mockApiClientProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(apiClientProvider));
});

// ── Auth State ────────────────────────────────────────────────────────────────

class AuthState {
  const AuthState({
    this.isAuthenticated = false,
    this.role,
    this.user,
    this.tokenExpiresAt,
  });

  final bool isAuthenticated;
  final AppRole? role;
  final UserProfile? user;
  final DateTime? tokenExpiresAt;

  AuthState copyWith({
    bool? isAuthenticated,
    AppRole? role,
    UserProfile? user,
    DateTime? tokenExpiresAt,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
      user: user ?? this.user,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._authRepository) : super(const AuthState()) {
    _authSubscription = _authRepository.watchAuthState().listen(
      _onAuthStateChanged,
      onError: (_, __) {},
    );
    unawaited(restoreSession());
  }

  final AuthRepository _authRepository;
  StreamSubscription<UserProfile?>? _authSubscription;
  bool _isSigningIn = false;

  static const _cachedUserKey = 'auth.cached_user.v1';

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  void _onAuthStateChanged(UserProfile? user) {
    if (user == null) {
      if (_isSigningIn) return;
      unawaited(_clearCachedSession());
      state = const AuthState();
      return;
    }
    _setAuthenticatedUser(user);
    unawaited(_cacheUserSession(user));
  }

  void _setAuthenticatedUser(UserProfile user) {
    state = state.copyWith(
      isAuthenticated: true,
      role: user.role,
      user: user,
      tokenExpiresAt: DateTime.now().add(AppConstants.tokenLifetime),
    );
  }

  Future<void> restoreSession() async {
    try {
      final user = await _authRepository.getCurrentUser();
      _setAuthenticatedUser(user);
      await _cacheUserSession(user);
      return;
    } catch (_) {
      final cached = await _readCachedSession();
      if (cached != null) {
        _setAuthenticatedUser(cached);
      } else if (!state.isAuthenticated) {
        state = const AuthState();
      }
    }
  }

  Future<void> _cacheUserSession(UserProfile user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = {
        'id': user.id,
        'name': user.name,
        'role': user.role.name,
        'permissions': user.permissions,
      };
      await prefs.setString(_cachedUserKey, jsonEncode(payload));
    } catch (_) {}
  }

  Future<UserProfile?> _readCachedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cachedUserKey);
      if (raw == null || raw.isEmpty) return null;
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;

      final roleName = json['role'] as String?;
      final role = AppRole.values.firstWhere(
        (value) => value.name == roleName,
        orElse: () => AppRole.operator,
      );

      final permissions = (json['permissions'] is List)
          ? (json['permissions'] as List)
                .whereType<String>()
                .where((item) => item.trim().isNotEmpty)
                .toList()
          : const <String>[];

      final id = (json['id'] as String?)?.trim();
      final name = (json['name'] as String?)?.trim();
      if (id == null || id.isEmpty || name == null || name.isEmpty) {
        return null;
      }

      return UserProfile(
        id: id,
        name: name,
        role: role,
        permissions: permissions,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearCachedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedUserKey);
    } catch (_) {}
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  void _validateEmail(String email) {
    if (email.isEmpty) {
      throw const AuthException('Email is required.', code: 'email-required');
    }
    if (!_emailPattern.hasMatch(email)) {
      throw const AuthException(
        'Please enter a valid email address.',
        code: 'invalid-email-format',
      );
    }
  }

  void _validateSignInPassword(String password) {
    if (password.isEmpty) {
      throw const AuthException(
        'Password is required.',
        code: 'password-required',
      );
    }
  }

  void _validateCreatePassword(String password) {
    if (password.length < 8) {
      throw const AuthException(
        'Password must be at least 8 characters.',
        code: 'weak-password',
      );
    }
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasNumber = RegExp(r'\d').hasMatch(password);
    if (!hasLetter || !hasNumber) {
      throw const AuthException(
        'Password must include both letters and numbers.',
        code: 'weak-password',
      );
    }
  }

  // ── Email / Password (primary) ────────────────────────────────────────────

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    _validateEmail(normalizedEmail);
    _validateSignInPassword(password);

    _isSigningIn = true;
    try {
      final user = await _authRepository.signInWithEmailPassword(
        email: normalizedEmail,
        password: password,
      );
      _setAuthenticatedUser(user);
      await _cacheUserSession(user);
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        'Unable to sign in right now. Please try again.',
        code: 'sign-in-failed',
      );
    } finally {
      _isSigningIn = false;
    }
  }

  Future<void> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    _validateEmail(normalizedEmail);
    _validateCreatePassword(password);
    if (displayName.trim().isEmpty) {
      throw const AuthException(
        'Display name is required.',
        code: 'display-name-required',
      );
    }

    try {
      final user = await _authRepository.createAccount(
        email: normalizedEmail,
        password: password,
        displayName: displayName.trim(),
      );
      _setAuthenticatedUser(user);
      await _cacheUserSession(user);
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        'Unable to create account right now. Please try again.',
        code: 'create-account-failed',
      );
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    final normalizedEmail = _normalizeEmail(email);
    _validateEmail(normalizedEmail);
    return _authRepository.sendPasswordResetEmail(email: normalizedEmail);
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
    } finally {
      await _clearCachedSession();
      state = const AuthState();
    }
  }

  // ── Legacy (kept for backward compat with phone-based flows) ─────────────

  Future<bool> signup({
    required String fullName,
    required String phoneNo,
    required String password,
    required String zone,
    required String division,
    required String location,
    String? email,
  }) {
    return _authRepository.signup(
      fullName: fullName,
      phoneNo: phoneNo,
      password: password,
      zone: zone,
      division: division,
      location: location,
      email: email,
    );
  }

  Future<bool> login(String phoneNo, String password) async {
    final ok = await _authRepository.login(
      phoneNo: phoneNo,
      password: password,
    );
    return ok;
  }

  Future<({String message, String resetToken})> forgotPassword(String phoneNo) {
    return _authRepository.forgotPassword(phoneNo: phoneNo);
  }

  Future<bool> changePasswordWithToken({
    required String newPassword,
    String? phoneNo,
    String? resetToken,
  }) {
    return _authRepository.changePasswordWithToken(
      newPassword: newPassword,
      phoneNo: phoneNo,
      resetToken: resetToken,
    );
  }

  Future<bool> changePasswordAuthenticated(String newPassword) {
    return _authRepository.changePasswordAuthenticated(
      newPassword: newPassword,
    );
  }

  Future<void> refreshToken() async {
    final ok = await _authRepository.refreshToken();
    if (!ok) return;
    state = state.copyWith(
      tokenExpiresAt: DateTime.now().add(AppConstants.tokenLifetime),
    );
  }

  void logout() {
    unawaited(_clearCachedSession());
    state = const AuthState();
  }

  void expireTokenNow() {
    state = state.copyWith(tokenExpiresAt: DateTime.now());
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

// ── Connection ────────────────────────────────────────────────────────────────

class ConnectionStateModel {
  const ConnectionStateModel({
    this.isConnected = true,
    this.lastSync,
    this.isReconnecting = false,
    this.slowBackend = false,
  });

  final bool isConnected;
  final DateTime? lastSync;
  final bool isReconnecting;
  final bool slowBackend;

  ConnectionStateModel copyWith({
    bool? isConnected,
    DateTime? lastSync,
    bool? isReconnecting,
    bool? slowBackend,
  }) {
    return ConnectionStateModel(
      isConnected: isConnected ?? this.isConnected,
      lastSync: lastSync ?? this.lastSync,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      slowBackend: slowBackend ?? this.slowBackend,
    );
  }
}

class ConnectionController extends StateNotifier<ConnectionStateModel> {
  ConnectionController()
    : super(ConnectionStateModel(lastSync: DateTime.now()));

  void setOffline(bool offline) {
    state = state.copyWith(isConnected: !offline, lastSync: DateTime.now());
  }

  void setReconnecting(bool reconnecting) {
    state = state.copyWith(isReconnecting: reconnecting);
  }

  void setSlowBackend(bool slow) {
    state = state.copyWith(slowBackend: slow);
  }
}

final connectionProvider =
    StateNotifierProvider<ConnectionController, ConnectionStateModel>(
      (ref) => ConnectionController(),
    );

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
final videoQualityProvider = StateProvider<String>((ref) => 'Auto');
final cacheEnabledProvider = StateProvider<bool>((ref) => true);
final syncQueueProvider = StateProvider<List<String>>(
  (ref) => ['Pending alert ack #A-002', 'Upload clip #V-104'],
);
final notificationsProvider = StateProvider<List<String>>(
  (ref) => ['New critical alert received', 'Token will expire in 2 minutes'],
);

final alertsFeedProvider = StreamProvider<AlertItem>((ref) {
  return ref.watch(alertsRepositoryProvider).streamAlerts();
});

final dashboardSummaryProvider =
    FutureProvider.family<DashboardSummary, String>((ref, range) {
      return ref.watch(dashboardRepositoryProvider).getSummary(range: range);
    });

final bucketsProvider = FutureProvider<List<BucketItem>>((ref) {
  return ref.watch(dashboardRepositoryProvider).getBuckets();
});

final reportsProvider = FutureProvider.family<List<ReportItem>, String>((
  ref,
  bucketName,
) {
  return ref
      .watch(dashboardRepositoryProvider)
      .getReports(bucketName: bucketName);
});

final tokenCountdownProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) {
    final expiry = ref.read(authProvider).tokenExpiresAt;
    return expiry == null ? 0 : expiry.difference(DateTime.now()).inSeconds;
  });
});
