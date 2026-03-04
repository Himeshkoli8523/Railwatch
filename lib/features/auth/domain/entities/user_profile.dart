import 'package:cctv/core/constants/app_enums.dart';

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
}
