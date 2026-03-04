import 'dart:async';
import 'dart:convert';

import 'package:cctv/shared/models/app_models.dart';
import 'package:flutter/services.dart';

class MockApi {
  List<VideoItem> _videos = const [];
  List<AlertItem> _alerts = const [];
  UserProfile? _profile;

  Future<void> init() async {
    if (_videos.isNotEmpty) return;
    final jsonString = await rootBundle.loadString('assets/mock_data.json');
    final Map<String, dynamic> payload =
        json.decode(jsonString) as Map<String, dynamic>;
    _videos = (payload['videos'] as List<dynamic>)
        .map((item) => VideoItem.fromJson(item as Map<String, dynamic>))
        .toList();
    _alerts = (payload['alerts'] as List<dynamic>)
        .map((item) => AlertItem.fromJson(item as Map<String, dynamic>))
        .toList();
    _profile = UserProfile.fromJson(
      payload['user_profile'] as Map<String, dynamic>,
    );
  }

  Future<List<VideoItem>> getVideos({
    int page = 1,
    int size = 20,
    String query = '',
    List<String> tags = const [],
  }) async {
    await init();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final normalized = query.trim().toLowerCase();
    final filtered = _videos.where((video) {
      final textMatch =
          normalized.isEmpty ||
          video.cameraId.toLowerCase().contains(normalized) ||
          video.trainId.toLowerCase().contains(normalized) ||
          video.wagonId.toLowerCase().contains(normalized);
      final tagMatch = tags.isEmpty || tags.every(video.aiTags.contains);
      return textMatch && tagMatch;
    }).toList();
    final start = (page - 1) * size;
    if (start >= filtered.length) return const [];
    final end = (start + size).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  Future<VideoItem?> getVideoById(String id) async {
    await init();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _videos.where((video) => video.id == id).firstOrNull;
  }

  Stream<AlertItem> getAlertsStream() async* {
    await init();
    var idx = 0;
    while (true) {
      await Future<void>.delayed(const Duration(seconds: 3));
      yield _alerts[idx % _alerts.length];
      idx++;
    }
  }

  Future<bool> acknowledgeAlert(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return true;
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return identifier.isNotEmpty && password.isNotEmpty;
  }

  Future<bool> refreshToken() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return true;
  }

  Future<UserProfile> getUserProfile() async {
    await init();
    return _profile!;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
