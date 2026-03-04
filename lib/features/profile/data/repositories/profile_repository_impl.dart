import 'package:cctv/core/network/mock_api_client.dart';
import 'package:cctv/features/auth/data/models/user_profile_model.dart';
import 'package:cctv/features/auth/domain/entities/user_profile.dart';
import 'package:cctv/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._api);

  final MockApiClient _api;

  @override
  Future<UserProfile> getProfile() async {
    final json = await _api.getProfile();
    return UserProfileModel.fromJson(json);
  }
}
