enum AppRole { admin, operator, auditor }

enum Severity { critical, high, medium, low }

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.permissions,
  });

  final String id;
  final String name;
  final AppRole role;
  final List<String> permissions;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      role: _roleFromString(json['role'] as String),
      permissions: (json['permissions'] as List<dynamic>).cast<String>(),
    );
  }
}

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

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    return VideoItem(
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

class AlertItem {
  const AlertItem({
    required this.id,
    required this.cameraId,
    required this.snapshotUrl,
    required this.detectionType,
    required this.confidence,
    required this.timestamp,
    required this.dedupGroup,
    required this.severity,
  });

  final String id;
  final String cameraId;
  final String snapshotUrl;
  final String detectionType;
  final double confidence;
  final DateTime timestamp;
  final String dedupGroup;
  final Severity severity;

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    return AlertItem(
      id: json['id'] as String,
      cameraId: json['camera_id'] as String,
      snapshotUrl: json['snapshot_url'] as String,
      detectionType: json['detection_type'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      dedupGroup: json['dedup_group'] as String,
      severity: _severityFromString((json['severity'] ?? 'medium') as String),
    );
  }
}

AppRole _roleFromString(String value) {
  switch (value.toLowerCase()) {
    case 'admin':
      return AppRole.admin;
    case 'auditor':
      return AppRole.auditor;
    default:
      return AppRole.operator;
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
