import 'package:cctv/app/app_providers.dart';
import 'package:cctv/core/auth/auth_policy.dart';
import 'package:cctv/core/constants/app_enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final role = auth.role ?? AppRole.operator;
    final permissions = effectivePermissions(
      role: role,
      explicitPermissions: auth.user?.permissions,
    ).toList();
    final canManageUsers = hasPermission(
      role: role,
      explicitPermissions: auth.user?.permissions,
      permission: AppPermissions.manageUsers,
    );
    final canUpdateAlerts = hasPermission(
      role: role,
      explicitPermissions: auth.user?.permissions,
      permission: AppPermissions.acknowledgeAlerts,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          minTileHeight: 44,
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(auth.user?.name ?? 'Demo User'),
          subtitle: Text('Role: ${role.name.toUpperCase()}'),
        ),
        const SizedBox(height: 8),
        Text('Permissions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: permissions
              .map((permission) => Chip(label: Text(permission)))
              .toList(),
        ),
        const SizedBox(height: 16),
        Tooltip(
          message: canManageUsers ? 'Allowed' : 'Only admin can manage users',
          child: FilledButton.icon(
            onPressed: canManageUsers ? () {} : null,
            icon: const Icon(Icons.admin_panel_settings),
            label: const Text('Manage users'),
          ),
        ),
        const SizedBox(height: 8),
        Tooltip(
          message: canUpdateAlerts
              ? 'Allowed for active operators'
              : 'Read-only mode for this role',
          child: FilledButton.icon(
            onPressed: canUpdateAlerts ? () {} : null,
            icon: const Icon(Icons.edit_note),
            label: const Text('Modify alert status'),
          ),
        ),
      ],
    );
  }
}
