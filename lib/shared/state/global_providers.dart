import 'dart:async';

import 'package:cctv/shared/data/mock_api.dart';
import 'package:cctv/shared/models/app_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mockApiProvider = Provider<MockApi>((ref) => MockApi());

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
  AuthController(this._api) : super(const AuthState());

  final MockApi _api;

  Future<bool> login(String identifier, String password, AppRole role) async {
    final ok = await _api.login(identifier: identifier, password: password);
    if (!ok) return false;
    final user = await _api.getUserProfile();
    state = state.copyWith(
      isAuthenticated: true,
      role: role,
      user: user,
      tokenExpiresAt: DateTime.now().add(const Duration(minutes: 15)),
    );
    return true;
  }

  void logout() => state = const AuthState();

  Future<void> refreshToken() async {
    final refreshed = await _api.refreshToken();
    if (refreshed) {
      state = state.copyWith(
        tokenExpiresAt: DateTime.now().add(const Duration(minutes: 15)),
      );
    }
  }

  void expireTokenNow() {
    state = state.copyWith(tokenExpiresAt: DateTime.now());
  }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(mockApiProvider));
});

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

  void setReconnecting(bool value) {
    state = state.copyWith(isReconnecting: value);
  }

  void setSlowBackend(bool value) {
    state = state.copyWith(slowBackend: value);
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
  final api = ref.watch(mockApiProvider);
  return api.getAlertsStream();
});

final tokenCountdownProvider = StreamProvider<int>((ref) async* {
  while (true) {
    final expiry = ref.read(authProvider).tokenExpiresAt;
    final remaining = expiry == null
        ? 0
        : expiry.difference(DateTime.now()).inSeconds;
    yield remaining;
    await Future<void>.delayed(const Duration(seconds: 1));
  }
});
