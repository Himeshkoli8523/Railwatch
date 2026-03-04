import 'package:cctv/core/constants/app_enums.dart';

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
}
