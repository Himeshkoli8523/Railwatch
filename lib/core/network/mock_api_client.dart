import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

class MockApiClient {
  Map<String, dynamic>? _cache;

  Future<Map<String, dynamic>> _load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/mock_data.json');
    _cache = json.decode(raw) as Map<String, dynamic>;
    return _cache!;
  }

  Future<List<Map<String, dynamic>>> getVideos({
    required int page,
    required int size,
    String query = '',
    List<String> tags = const [],
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final data = await _load();
    final all = (data['videos'] as List<dynamic>).cast<Map<String, dynamic>>();
    final q = query.toLowerCase().trim();
    final filtered = all.where((item) {
      final text =
          q.isEmpty ||
          (item['camera_id'] as String).toLowerCase().contains(q) ||
          (item['wagon_id'] as String).toLowerCase().contains(q) ||
          (item['train_id'] as String).toLowerCase().contains(q);
      final ai = (item['ai_tags'] as List<dynamic>).cast<String>();
      final tagMatch = tags.isEmpty || tags.every(ai.contains);
      return text && tagMatch;
    }).toList();
    final start = (page - 1) * size;
    if (start >= filtered.length) return const [];
    final end = (start + size).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  Future<Map<String, dynamic>?> getVideoById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final data = await _load();
    final all = (data['videos'] as List<dynamic>).cast<Map<String, dynamic>>();
    for (final item in all) {
      if (item['id'] == id) return item;
    }
    return null;
  }

  Stream<Map<String, dynamic>> streamAlerts() async* {
    final data = await _load();
    final all = (data['alerts'] as List<dynamic>).cast<Map<String, dynamic>>();
    var index = 0;
    while (true) {
      await Future<void>.delayed(const Duration(seconds: 3));
      yield all[index % all.length];
      index++;
    }
  }

  Future<bool> acknowledgeAlert(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return true;
  }

  Future<bool> signup({
    required String fullName,
    required String phoneNo,
    required String password,
    required String zone,
    required String division,
    required String location,
    String? email,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    return fullName.trim().isNotEmpty &&
        phoneNo.trim().isNotEmpty &&
        password.trim().isNotEmpty &&
        zone.trim().isNotEmpty &&
        division.trim().isNotEmpty &&
        location.trim().isNotEmpty;
  }

  Future<bool> login(String phoneNo, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    return phoneNo.trim().isNotEmpty && password.trim().isNotEmpty;
  }

  Future<({String message, String resetToken})> forgotPassword(
    String phoneNo,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return (
      message: phoneNo.trim().isEmpty
          ? 'Phone number required'
          : 'Reset token generated',
      resetToken: 'RST-${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<bool> changePasswordWithToken({
    required String newPassword,
    String? phoneNo,
    String? resetToken,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return newPassword.trim().isNotEmpty &&
        ((phoneNo?.trim().isNotEmpty ?? false) ||
            (resetToken?.trim().isNotEmpty ?? false));
  }

  Future<bool> changePasswordAuthenticated(String newPassword) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return newPassword.trim().isNotEmpty;
  }

  Future<bool> refreshToken() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return true;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final data = await _load();
    return data['user_profile'] as Map<String, dynamic>;
  }
}
