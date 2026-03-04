import 'package:cctv/core/constants/app_enums.dart';
import 'package:cctv/features/videos/domain/entities/video_item.dart';

class VideoItemModel extends VideoItem {
  const VideoItemModel({
    required super.id,
    required super.cameraId,
    required super.wagonId,
    required super.trainId,
    required super.timestamp,
    required super.duration,
    required super.thumbnailUrl,
    required super.aiTags,
    required super.severity,
    required super.signedUrlStatus,
  });

  factory VideoItemModel.fromJson(Map<String, dynamic> json) {
    return VideoItemModel(
      id: json['id'] as String,
      cameraId: json['camera_id'] as String,
      wagonId: json['wagon_id'] as String,
      trainId: json['train_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      duration: json['duration'] as String,
      thumbnailUrl: json['thumbnail_url'] as String,
      aiTags: (json['ai_tags'] as List<dynamic>).cast<String>(),
      severity: _severityFromString(json['severity'] as String),
      signedUrlStatus: json['s3_signed_url_status'] as String,
    );
  }
}

Severity _severityFromString(String value) {
  switch (value.toLowerCase()) {
    case 'critical':
      return Severity.critical;
    case 'high':
      return Severity.high;
    case 'low':
      return Severity.low;
    default:
      return Severity.medium;
  }
}
