import 'package:cctv/features/alerts/domain/entities/alert_item.dart';

abstract class AlertsRepository {
  Stream<AlertItem> streamAlerts();
  Future<bool> acknowledgeAlert(String id);
}
