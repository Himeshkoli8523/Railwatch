import 'package:cctv/app/app_providers.dart';
import 'package:cctv/core/auth/auth_policy.dart';
import 'package:cctv/core/constants/app_enums.dart';
import 'package:cctv/core/widgets/common_widgets.dart';
import 'package:cctv/features/videos/domain/entities/video_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VideoDetailScreen extends ConsumerWidget {
  const VideoDetailScreen({super.key, required this.videoId});

  final String videoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final role = auth.role ?? AppRole.operator;
    final canDownload = hasPermission(
      role: role,
      explicitPermissions: auth.user?.permissions,
      permission: AppPermissions.downloadVideos,
    );
    final future = ref.watch(videosRepositoryProvider).getVideoById(videoId);

    return Scaffold(
      appBar: AppBar(title: const Text('Video Detail')),
      body: FutureBuilder<VideoItem?>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  SkeletonBox(height: 200, width: double.infinity),
                  SizedBox(height: 12),
                  SkeletonBox(height: 18, width: 220),
                ],
              ),
            );
          }
          final item = snapshot.data;
          if (item == null) return const EmptyState(message: 'Video not found');

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.play_circle_outline, size: 54),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    item.signedUrlStatus == 'valid'
                        ? Icons.lock
                        : Icons.lock_open,
                    size: 18,
                    color: item.signedUrlStatus == 'valid'
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Secure playback: ${item.signedUrlStatus.toUpperCase()}',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text('Metadata', style: Theme.of(context).textTheme.titleMedium),
              ListTile(
                title: Text('Camera ${item.cameraId}'),
                subtitle: Text('Train ${item.trainId} • Wagon ${item.wagonId}'),
              ),
              Wrap(
                spacing: 6,
                children: item.aiTags
                    .map((tag) => Chip(label: Text(tag)))
                    .toList(),
              ),
              const SizedBox(height: 8),
              const Text('Timeline markers'),
              ...[
                '00:12 Detection',
                '00:29 Operator note',
                '01:02 Alert spike',
              ].map(
                (marker) => ListTile(
                  minTileHeight: 44,
                  leading: const Icon(Icons.flag_outlined),
                  title: Text(marker),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Comments / logs'),
              ...[
                'Auditor: reviewed',
                'Operator: escalated to admin',
              ].map((entry) => ListTile(minTileHeight: 44, title: Text(entry))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(onPressed: () {}, child: const Text('Flag')),
                  Tooltip(
                    message: canDownload
                        ? 'Download clip'
                        : 'Disabled for Auditor role',
                    child: FilledButton(
                      onPressed: canDownload ? () {} : null,
                      child: const Text('Download Clip'),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Export Snapshot'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
