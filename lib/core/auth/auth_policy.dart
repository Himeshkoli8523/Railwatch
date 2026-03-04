import 'package:cctv/core/constants/app_enums.dart';

abstract final class AppPermissions {
  static const viewVideos = 'view_videos';
  static const downloadVideos = 'download_videos';
  static const viewAlerts = 'view_alerts';
  static const acknowledgeAlerts = 'acknowledge_alerts';
  static const manageVideos = 'manage_videos';
  static const manageUsers = 'manage_users';
}

Set<String> defaultPermissionsForRole(AppRole role) {
  switch (role) {
    case AppRole.admin:
      return {
        AppPermissions.viewVideos,
        AppPermissions.downloadVideos,
        AppPermissions.viewAlerts,
        AppPermissions.acknowledgeAlerts,
        AppPermissions.manageVideos,
        AppPermissions.manageUsers,
      };
    case AppRole.operator:
      return {
        AppPermissions.viewVideos,
        AppPermissions.downloadVideos,
        AppPermissions.viewAlerts,
        AppPermissions.acknowledgeAlerts,
      };
    case AppRole.auditor:
      return {AppPermissions.viewVideos, AppPermissions.viewAlerts};
  }
}

Set<String> effectivePermissions({
  required AppRole role,
  Iterable<String>? explicitPermissions,
}) {
  final userPermissions = explicitPermissions?.where(
    (p) => p.trim().isNotEmpty,
  );
  if (userPermissions == null || userPermissions.isEmpty) {
    return defaultPermissionsForRole(role);
  }
  return userPermissions.toSet();
}

bool hasPermission({
  required AppRole role,
  Iterable<String>? explicitPermissions,
  required String permission,
}) {
  return effectivePermissions(
    role: role,
    explicitPermissions: explicitPermissions,
  ).contains(permission);
}

AppRole roleFromClaims(Map<String, dynamic> claims) {
  final roleRaw = claims['role'];
  if (roleRaw is! String) return AppRole.operator;
  switch (roleRaw.trim().toLowerCase()) {
    case 'admin':
      return AppRole.admin;
    case 'auditor':
      return AppRole.auditor;
    default:
      return AppRole.operator;
  }
}

List<String> permissionsFromClaims({
  required Map<String, dynamic> claims,
  required AppRole fallbackRole,
}) {
  final raw = claims['permissions'];
  if (raw is List) {
    final parsed = raw
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (parsed.isNotEmpty) return parsed;
  }
  return defaultPermissionsForRole(fallbackRole).toList(growable: false);
}
