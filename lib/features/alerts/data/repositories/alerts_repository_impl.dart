import 'package:cctv/core/network/mock_api_client.dart';
import 'package:cctv/features/alerts/data/models/alert_item_model.dart';
import 'package:cctv/features/alerts/domain/entities/alert_item.dart';
import 'package:cctv/features/alerts/domain/repositories/alerts_repository.dart';

class AlertsRepositoryImpl implements AlertsRepository {
  AlertsRepositoryImpl(this._api);

  final MockApiClient _api;

  @override
  Future<bool> acknowledgeAlert(String id) {
    return _api.acknowledgeAlert(id);
  }

  @override
  Stream<AlertItem> streamAlerts() {
    return _api.streamAlerts().map(AlertItemModel.fromJson);
  }
}
