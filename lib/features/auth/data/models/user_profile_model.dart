import 'package:cctv/core/constants/app_enums.dart';
import 'package:cctv/features/auth/domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.name,
    required super.role,
    required super.permissions,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      role: _roleFromString(json['role'] as String),
      permissions: (json['permissions'] as List<dynamic>).cast<String>(),
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
