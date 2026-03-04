import 'package:cctv/core/network/api_client.dart';
import 'package:cctv/features/videos/data/models/video_item_model.dart';
import 'package:cctv/features/videos/domain/entities/camera.dart';
import 'package:cctv/features/videos/domain/entities/video_item.dart';
import 'package:cctv/features/videos/domain/entities/video_page.dart';
import 'package:cctv/features/videos/domain/entities/zone.dart';
import 'package:cctv/features/videos/domain/repositories/videos_repository.dart';

class VideosRepositoryImpl implements VideosRepository {
  VideosRepositoryImpl(this._api);

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> _fetchVideos({
    String trainNumber = '',
    String cameraId = '',
  }) async {
    final query = <String, String>{};
    if (trainNumber.trim().isNotEmpty) {
      query['train_number'] = trainNumber.trim();
    }
    if (cameraId.trim().isNotEmpty) {
      query['camera_id'] = cameraId.trim();
    }

    final raw = await _api.getJson('/api/videos', query: query);
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  @override
  Future<List<Zone>> getZones() async {
    final raw = await _fetchVideos();

    final zones = <String, Zone>{};
    final camerasPerZone = <String, Set<String>>{};

    for (final item in raw) {
      final zoneId = (item['zone_id'] as String?)?.trim();
      final zoneName = (item['zone_name'] as String?)?.trim();
      final division = (item['division'] as String?)?.trim();
      final cameraId = (item['camera_id'] as String?)?.trim();

      if (zoneId == null || zoneId.isEmpty) continue;
      if (cameraId == null || cameraId.isEmpty) continue;

      camerasPerZone.putIfAbsent(zoneId, () => <String>{}).add(cameraId);

      zones[zoneId] = Zone(
        id: zoneId,
        name: (zoneName == null || zoneName.isEmpty) ? zoneId : zoneName,
        division: (division == null || division.isEmpty)
            ? 'General Division'
            : division,
        camerasCount: camerasPerZone[zoneId]!.length,
        onlineCameras: camerasPerZone[zoneId]!.length,
      );
    }

    final sorted = zones.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }

  @override
  Future<List<Camera>> getCamerasForZone(String zoneId) async {
    final raw = await _fetchVideos();
    final filtered = raw.where((item) => item['zone_id'] == zoneId).toList();

    final countByCamera = <String, int>{};
    for (final item in filtered) {
      final id = (item['camera_id'] as String?)?.trim();
      if (id == null || id.isEmpty) continue;
      countByCamera[id] = (countByCamera[id] ?? 0) + 1;
    }

    final cameras =
        countByCamera.entries
            .map(
              (entry) => Camera(
                id: entry.key,
                zoneId: zoneId,
                name: entry.key,
                status: CameraStatus.online,
                streamUrl: getStreamUrl(entry.key, 'live'),
                videoCount: entry.value,
              ),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    return cameras;
  }

  @override
  Future<VideoPage> getVideos({
    required String zoneId,
    required String cameraId,
    String? cursor,
    int size = 30,
    String query = '',
    List<String> tags = const [],
  }) async {
    final raw = await _fetchVideos(
      trainNumber: query,
      cameraId: cameraId == '*' ? '' : cameraId,
    );

    var filtered = raw;
    if (zoneId != '*') {
      filtered = filtered.where((item) => item['zone_id'] == zoneId).toList();
    }

    if (tags.isNotEmpty) {
      filtered = filtered.where((item) {
        final aiTags =
            (item['ai_tags'] as List<dynamic>?)?.whereType<String>().toList() ??
            const <String>[];
        return tags.every(aiTags.contains);
      }).toList();
    }

    final offset = cursor == null ? 0 : int.tryParse(cursor) ?? 0;
    if (offset >= filtered.length) {
      return const VideoPage(items: [], nextCursor: null);
    }

    final end = (offset + size).clamp(0, filtered.length);
    final chunk = filtered.sublist(offset, end);
    final items = chunk.map(VideoItemModel.fromJson).toList(growable: false);
    final nextCursor = end < filtered.length ? end.toString() : null;

    return VideoPage(items: items, nextCursor: nextCursor);
  }

  @override
  Future<VideoItem?> getVideoById(String id) async {
    try {
      final raw = await _api.getJson('/api/videos/$id');
      if (raw is! Map) return null;
      return VideoItemModel.fromJson(Map<String, dynamic>.from(raw));
    } catch (_) {
      return null;
    }
  }

  @override
  String getStreamUrl(String cameraId, String videoPath) {
    return '${_api.baseUrl}/stream/$cameraId/$videoPath';
  }
}
