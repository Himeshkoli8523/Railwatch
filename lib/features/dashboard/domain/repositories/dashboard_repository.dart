import 'package:cctv/features/dashboard/domain/entities/bucket_item.dart';
import 'package:cctv/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:cctv/features/dashboard/domain/entities/report_item.dart';

abstract class DashboardRepository {
  Future<DashboardSummary> getSummary({required String range});
  Future<List<BucketItem>> getBuckets();
  Future<List<ReportItem>> getReports({required String bucketName});
}
