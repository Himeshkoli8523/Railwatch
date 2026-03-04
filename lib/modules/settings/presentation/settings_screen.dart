import 'package:cctv/modules/gallery/presentation/screen_gallery.dart';
import 'package:cctv/modules/notifications/presentation/notification_center_screen.dart';
import 'package:cctv/shared/state/global_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final videoQuality = ref.watch(videoQualityProvider);
    final cacheEnabled = ref.watch(cacheEnabledProvider);
    final queue = ref.watch(syncQueueProvider);
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
        const Divider(),
        Text(
          'Offline & sync queue',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        ...queue.map((task) => ListTile(title: Text(task), minTileHeight: 44)),
        Row(
          children: [
            OutlinedButton(
              onPressed: () => _openConflictModal(context),
              child: const Text('Resolve conflict'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                final isOffline = !ref.read(connectionProvider).isConnected;
                ref.read(connectionProvider.notifier).setOffline(!isOffline);
              },
              child: const Text('Toggle offline'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                final slow = ref.read(connectionProvider).slowBackend;
                ref.read(connectionProvider.notifier).setSlowBackend(!slow);
              },
              child: const Text('Toggle slow backend'),
            ),
          ],
        ),
        const Divider(),
        Text('Notifications', style: Theme.of(context).textTheme.titleMedium),
        Row(
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
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _showPushPermissionPrompt(context),
              child: const Text('Push permission prompt'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FilledButton.tonal(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScreenGallery()),
            );
          },
          child: const Text('Open state gallery'),
        ),
      ],
    );
  }

  Future<void> _openConflictModal(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sync conflict detected'),
        content: const Text(
          'Choose resolution strategy for this pending change.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Local'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Server'),
          ),
        ],
      ),
    );
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
