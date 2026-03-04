import 'package:cctv/features/videos/domain/entities/camera.dart';
import 'package:cctv/features/videos/domain/entities/video_item.dart';
import 'package:cctv/features/videos/domain/entities/video_page.dart';
import 'package:cctv/features/videos/domain/entities/zone.dart';

abstract class VideosRepository {
  /// Returns all available zones (folders).
  Future<List<Zone>> getZones();

  /// Returns cameras available in a specific zone.
  Future<List<Camera>> getCamerasForZone(String zoneId);

  /// Cursor-based pagination — [cursor] null means "start from beginning".
  /// Returns a [VideoPage] with items + optional [nextCursor].
  Future<VideoPage> getVideos({
    required String zoneId,
    required String cameraId,
    String? cursor,
    int size = 30,
    String query = '',
    List<String> tags = const [],
  });

  /// Fetch single video by ID.
  Future<VideoItem?> getVideoById(String id);

  /// Build the RTSP/HLS stream URL for a given camera and video path.
  String getStreamUrl(String cameraId, String videoPath);
}
