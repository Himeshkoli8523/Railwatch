import 'package:cctv/core/widgets/common_widgets.dart';
import 'package:cctv/features/videos/domain/entities/camera.dart';
import 'package:cctv/features/videos/domain/entities/zone.dart';
import 'package:cctv/features/videos/presentation/videos_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CamerasScreen extends ConsumerWidget {
  const CamerasScreen({super.key, required this.zone});
  final Zone zone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final camerasAsync = ref.watch(camerasProvider(zone.id));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(zone.name),
            Text(
              zone.division,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
      body: camerasAsync.when(
        loading: () => const _CamerasSkeleton(),
        error: (e, _) => _CamerasError(
          onRetry: () => ref.invalidate(camerasProvider(zone.id)),
        ),
        data: (cameras) => cameras.isEmpty
            ? const EmptyState(message: 'No cameras found in this zone.')
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(camerasProvider(zone.id).notifier).refresh(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth > 600 ? 3 : 2;
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.92,
                      ),
                      itemCount: cameras.length,
                      itemBuilder: (context, i) =>
                          _CameraCard(camera: cameras[i], zone: zone),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _CameraCard extends StatelessWidget {
  const _CameraCard({required this.camera, required this.zone});
  final Camera camera;
  final Zone zone;

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel, statusIcon) = switch (camera.status) {
      CameraStatus.online => (Colors.green, 'Online', Icons.videocam_rounded),
      CameraStatus.offline => (
        Colors.grey,
        'Offline',
        Icons.videocam_off_rounded,
      ),
      CameraStatus.error => (Colors.red, 'Error', Icons.error_outline_rounded),
    };

    final isClickable = camera.status != CameraStatus.error;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isClickable
            ? () => Navigator.pushNamed(
                context,
                '/video-list',
                arguments: {'zone': zone, 'camera': camera},
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Camera feed placeholder
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      statusIcon,
                      size: 36,
                      color: statusColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                camera.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            statusLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${camera.videoCount} videos',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CamerasSkeleton extends StatelessWidget {
  const _CamerasSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const Card(
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Column(
            children: [
              Expanded(child: SkeletonBox()),
              SizedBox(height: 10),
              SkeletonBox(width: 90, height: 13),
              SizedBox(height: 6),
              SkeletonBox(width: 60, height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _CamerasError extends StatelessWidget {
  const _CamerasError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('Failed to load cameras'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
