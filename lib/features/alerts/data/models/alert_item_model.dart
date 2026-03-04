import 'package:cctv/core/constants/app_enums.dart';
import 'package:cctv/features/alerts/domain/entities/alert_item.dart';

class AlertItemModel extends AlertItem {
  const AlertItemModel({
    required super.id,
    required super.cameraId,
    required super.snapshotUrl,
    required super.detectionType,
    required super.confidence,
    required super.timestamp,
    required super.dedupGroup,
    required super.severity,
  });

  factory AlertItemModel.fromJson(Map<String, dynamic> json) {
    return AlertItemModel(
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
