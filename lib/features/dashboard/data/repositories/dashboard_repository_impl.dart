import 'package:cctv/core/constants/app_enums.dart';
import 'package:cctv/features/dashboard/domain/entities/bucket_item.dart';
import 'package:cctv/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:cctv/features/dashboard/domain/entities/report_item.dart';
import 'package:cctv/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  @override
  Future<DashboardSummary> getSummary({required String range}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return const DashboardSummary(
      activeAlerts: '21',
      camerasOnline: '148/152',
      defectsToday: '9',
      ingestionRate: '182 MB/s',
    );
  }

  @override
  Future<List<BucketItem>> getBuckets() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();
    return [
      BucketItem(
        name: 'train-zone-A',
        videoCount: 312,
        sizeGb: 48.6,
        lastUpdated: now.subtract(const Duration(minutes: 5)),
        status: BucketStatus.active,
      ),
      BucketItem(
        name: 'train-zone-B',
        videoCount: 204,
        sizeGb: 31.2,
        lastUpdated: now.subtract(const Duration(minutes: 12)),
        status: BucketStatus.syncing,
      ),
      BucketItem(
        name: 'train-zone-C',
        videoCount: 97,
        sizeGb: 14.8,
        lastUpdated: now.subtract(const Duration(hours: 1)),
        status: BucketStatus.error,
      ),
      BucketItem(
        name: 'archive-q1',
        videoCount: 1542,
        sizeGb: 210.4,
        lastUpdated: now.subtract(const Duration(days: 5)),
        status: BucketStatus.active,
      ),
    ];
  }

  @override
  Future<List<ReportItem>> getReports({required String bucketName}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    return [
      ReportItem(
        id: 'R-001',
        bucketName: 'train-zone-A',
        videoName: 'cam01_20240301_143000.mp4',
        createdAt: now.subtract(const Duration(minutes: 8)),
        severity: Severity.critical,
        status: ReportStatus.ready,
      ),
      ReportItem(
        id: 'R-002',
        bucketName: 'train-zone-B',
        videoName: 'cam03_20240301_091500.mp4',
        createdAt: now.subtract(const Duration(minutes: 25)),
        severity: Severity.medium,
        status: ReportStatus.processing,
      ),
      ReportItem(
        id: 'R-003',
        bucketName: 'train-zone-A',
        videoName: 'cam02_20240301_060000.mp4',
        createdAt: now.subtract(const Duration(hours: 2)),
        severity: Severity.low,
        status: ReportStatus.ready,
      ),
      ReportItem(
        id: 'R-004',
        bucketName: 'train-zone-C',
        videoName: 'cam04_20240228_223000.mp4',
        createdAt: now.subtract(const Duration(hours: 5)),
        severity: Severity.high,
        status: ReportStatus.failed,
      ),
    ];
  }
}
