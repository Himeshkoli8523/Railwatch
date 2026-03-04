import 'dart:async';
import 'package:cctv/features/auth/data/datasources/auth_data_source.dart';

/// Mock implementation of [AuthDataSource] for development and testing.
/// Accepts any non-empty credentials and simulates network latency.
class MockAuthDataSource implements AuthDataSource {
  MockAuthDataSource();

  final _controller = StreamController<AuthUserDto?>.broadcast();
  AuthUserDto? _currentUser;

  @override
  Future<AuthUserDto> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw const AuthException('Email and password are required.');
    }
    final user = AuthUserDto(
      uid: 'mock-uid-${email.hashCode.abs()}',
      email: email,
      displayName: email.split('@').first,
      claims: const {
        'role': 'operator',
        'permissions': [
          'view_videos',
          'download_videos',
          'view_alerts',
          'acknowledge_alerts',
        ],
      },
    );
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AuthUserDto> createUserWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (email.trim().isEmpty ||
        password.trim().isEmpty ||
        displayName.trim().isEmpty) {
      throw const AuthException('All fields are required.');
    }
    if (password.length < 6) {
      throw const AuthException(
        'Password must be at least 6 characters.',
        code: 'weak-password',
      );
    }
    final user = AuthUserDto(
      uid: 'mock-uid-${email.hashCode.abs()}',
      email: email,
      displayName: displayName,
      claims: const {
        'role': 'operator',
        'permissions': [
          'view_videos',
          'download_videos',
          'view_alerts',
          'acknowledge_alerts',
        ],
      },
    );
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (email.trim().isEmpty) {
      throw const AuthException('Email is required.');
    }
    // Mock: silently succeeds
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Stream<AuthUserDto?> get authStateChanges => _controller.stream;

  @override
  AuthUserDto? get currentUser => _currentUser;
}
