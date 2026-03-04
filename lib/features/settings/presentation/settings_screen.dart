import 'package:cctv/app/app_providers.dart';
import 'package:cctv/features/auth/data/datasources/auth_data_source.dart';
import 'package:cctv/features/settings/presentation/notification_center_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final videoQuality = ref.watch(videoQualityProvider);
    final cacheEnabled = ref.watch(cacheEnabledProvider);
    final tokenRemaining = ref.watch(tokenCountdownProvider).valueOrNull ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('App settings', style: Theme.of(context).textTheme.titleMedium),
        ListTile(
          minTileHeight: 44,
          title: const Text('Theme'),
          subtitle: Text(themeMode.name),
          trailing: DropdownButton<ThemeMode>(
            value: themeMode,
            onChanged: (value) => ref.read(themeModeProvider.notifier).state =
                value ?? ThemeMode.system,
            items: const [
              DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
              DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
              DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
            ],
          ),
        ),
        ListTile(
          minTileHeight: 44,
          title: const Text('Video quality'),
          trailing: DropdownButton<String>(
            value: videoQuality,
            onChanged: (value) =>
                ref.read(videoQualityProvider.notifier).state = value ?? 'Auto',
            items: const [
              DropdownMenuItem(value: 'Auto', child: Text('Auto')),
              DropdownMenuItem(value: '720p', child: Text('720p')),
              DropdownMenuItem(value: '1080p', child: Text('1080p')),
            ],
          ),
        ),
        SwitchListTile(
          title: const Text('Cache enabled'),
          value: cacheEnabled,
          onChanged: (value) =>
              ref.read(cacheEnabledProvider.notifier).state = value,
        ),
        const Divider(),
        ListTile(
          minTileHeight: 44,
          title: const Text('Token status'),
          subtitle: Text('Expires in $tokenRemaining seconds'),
          trailing: FilledButton(
            onPressed: () => ref.read(authProvider.notifier).refreshToken(),
            child: const Text('Refresh token'),
          ),
        ),

        Text('Notifications', style: Theme.of(context).textTheme.titleMedium),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationCenterScreen(),
                  ),
                );
              },
              child: const Text('Open notification center'),
            ),
            OutlinedButton(
              onPressed: () => _showPushPermissionPrompt(context),
              child: const Text('Push permission prompt'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _signOut(context, ref),
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authProvider.notifier).signOut();
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } on AuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign out failed. Please try again.')),
      );
    }
  }

  Future<void> _showPushPermissionPrompt(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enable push notifications?'),
        content: const Text('Get critical alerts in real time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }
}
