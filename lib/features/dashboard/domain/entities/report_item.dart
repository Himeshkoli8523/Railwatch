import 'package:cctv/core/constants/app_enums.dart';

class ReportItem {
  const ReportItem({
    required this.id,
    required this.bucketName,
    required this.videoName,
    required this.createdAt,
    required this.severity,
    required this.status,
  });

  final String id;
  final String bucketName;
  final String videoName;
  final DateTime createdAt;
  final Severity severity;
  final ReportStatus status;
}

enum ReportStatus { ready, processing, failed }
