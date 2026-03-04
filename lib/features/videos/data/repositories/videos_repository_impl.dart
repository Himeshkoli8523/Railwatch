import 'package:cctv/core/constants/app_enums.dart';
import 'package:cctv/features/videos/data/models/video_item_model.dart';
import 'package:cctv/features/videos/domain/entities/camera.dart';
import 'package:cctv/features/videos/domain/entities/video_item.dart';
import 'package:cctv/features/videos/domain/entities/video_page.dart';
import 'package:cctv/features/videos/domain/entities/zone.dart';
import 'package:cctv/features/videos/domain/repositories/videos_repository.dart';

/// Mock zones — in production replace with real API calls.
const _zones = [
  Zone(id: 'zone-A', name: 'Zone A', division: 'North Division', camerasCount: 12, onlineCameras: 10),
  Zone(id: 'zone-B', name: 'Zone B', division: 'South Division', camerasCount: 8,  onlineCameras: 8),
  Zone(id: 'zone-C', name: 'Zone C', division: 'East Division',  camerasCount: 15, onlineCameras: 13),
  Zone(id: 'zone-D', name: 'Zone D', division: 'West Division',  camerasCount: 6,  onlineCameras: 5),
];

/// Generate mock cameras for a zone.
List<Camera> _camerasForZone(String zoneId) {
  final statuses = [CameraStatus.online, CameraStatus.online, CameraStatus.offline, CameraStatus.error];
  return List.generate(6, (i) {
    final idx = i % statuses.length;
    return Camera(
      id: '$zoneId-cam${(i + 1).toString().padLeft(2, '0')}',
      zoneId: zoneId,
      name: 'Camera ${i + 1}',
      status: statuses[idx],
      streamUrl: 'rtsp://mock.cctv/$zoneId/cam${i + 1}/stream',
      videoCount: 500 + i * 37,
    );
  });
}

/// Simulate a huge video dataset using deterministic generation.
/// In production, the API returns real paginated results.
List<Map<String, dynamic>> _generateVideoPage(
  String zoneId,
  String cameraId,
  int offset,
  int size,
  String query,
  List<String> tags,
) {
  final severities = [Severity.low, Severity.medium, Severity.high, Severity.critical];
  final allTags = ['DoorOpen', 'Smoke', 'BearingHeat', 'Motion', 'PersonDetected'];

  return List.generate(size, (i) {
    final absIndex = offset + i;
    final ts = DateTime(2024, 1, 1).add(Duration(minutes: absIndex * 5));
    return {
      'id': '$cameraId-v$absIndex',
      'cameraId': cameraId,
      'wagonId': 'W${(absIndex % 20) + 1}',
      'trainId': 'T${(absIndex % 5) + 1}',
      'timestamp': ts.toIso8601String(),
      'duration': '${2 + (absIndex % 8)}:${((absIndex * 3) % 60).toString().padLeft(2, '0')}',
      'thumbnailUrl': 'https://picsum.photos/seed/$absIndex/320/180',
      'aiTags': [allTags[absIndex % allTags.length]],
      'severity': severities[absIndex % severities.length].name,
      'signedUrlStatus': 'signed',
      'streamUrl': 'rtsp://mock.cctv/$zoneId/$cameraId/v$absIndex.mp4',
    };
  });
}

class VideosRepositoryImpl implements VideosRepository {
  const VideosRepositoryImpl();

  @override
  Future<List<Zone>> getZones() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _zones;
  }

  @override
  Future<List<Camera>> getCamerasForZone(String zoneId) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return _camerasForZone(zoneId);
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
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // Decode cursor: it's simply the base-10 offset encoded as string.
    final offset = cursor == null ? 0 : int.tryParse(cursor) ?? 0;

    // Simulate 10M videos per camera; cap at 10,000,000.
    const totalVideos = 10000000;
    final remaining = totalVideos - offset;
    if (remaining <= 0) return const VideoPage(items: [], nextCursor: null);

    final count = remaining < size ? remaining : size;
    final raw = _generateVideoPage(zoneId, cameraId, offset, count, query, tags);

    final items = raw.map((j) => VideoItemModel.fromJson(j)).toList();
    final nextCursor = (offset + count) < totalVideos
        ? (offset + count).toString()
        : null;

    return VideoPage(items: items, nextCursor: nextCursor);
  }

  @override
  Future<VideoItem?> getVideoById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    // Return a stub item for detail view.
    return VideoItemModel.fromJson({
      'id': id,
      'cameraId': 'cam-01',
      'wagonId': 'W1',
      'trainId': 'T1',
      'timestamp': DateTime.now().toIso8601String(),
      'duration': '3:45',
      'thumbnailUrl': 'https://picsum.photos/seed/$id/320/180',
      'aiTags': ['DoorOpen'],
      'severity': 'medium',
      'signedUrlStatus': 'signed',
      'streamUrl': 'rtsp://mock.cctv/stream/$id.mp4',
    });
  }

  @override
  String getStreamUrl(String cameraId, String videoPath) {
    return 'rtsp://mock.cctv/$cameraId/$videoPath';
  }
}
