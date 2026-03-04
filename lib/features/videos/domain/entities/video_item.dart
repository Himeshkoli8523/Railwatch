import 'package:cctv/core/constants/app_enums.dart';

class VideoItem {
  const VideoItem({
    required this.id,
    required this.cameraId,
    required this.wagonId,
    required this.trainId,
    required this.timestamp,
    required this.duration,
    required this.thumbnailUrl,
    required this.aiTags,
    required this.severity,
    required this.signedUrlStatus,
  });

  final String id;
  final String cameraId;
  final String wagonId;
  final String trainId;
  final DateTime timestamp;
  final String duration;
  final String thumbnailUrl;
  final List<String> aiTags;
  final Severity severity;
  final String signedUrlStatus;
}
