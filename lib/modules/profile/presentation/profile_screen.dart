import 'package:cctv/shared/models/app_models.dart';
import 'package:cctv/shared/state/global_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final role = auth.role ?? AppRole.operator;
    final permissions = auth.user?.permissions ?? ['view_video', 'view_alert'];

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
          message: role == AppRole.admin
              ? 'Allowed'
              : 'Only admin can manage users',
          child: FilledButton.icon(
            onPressed: role == AppRole.admin ? () {} : null,
            icon: const Icon(Icons.admin_panel_settings),
            label: const Text('Manage users'),
          ),
        ),
        const SizedBox(height: 8),
        Tooltip(
          message: role == AppRole.auditor
              ? 'Read-only mode for auditors'
              : 'Allowed for active operators',
          child: FilledButton.icon(
            onPressed: role == AppRole.auditor ? null : () {},
            icon: const Icon(Icons.edit_note),
            label: const Text('Modify alert status'),
          ),
        ),
      ],
    );
  }
}
