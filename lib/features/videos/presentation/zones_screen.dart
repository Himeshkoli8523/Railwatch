import 'package:cctv/core/widgets/common_widgets.dart';
import 'package:cctv/features/videos/domain/entities/zone.dart';
import 'package:cctv/features/videos/presentation/videos_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ZonesScreen extends ConsumerWidget {
  const ZonesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(zonesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.folder_outlined, size: 22),
            SizedBox(width: 8),
            Text('Select Zone'),
          ],
        ),
      ),
      body: zonesAsync.when(
        loading: () => const _ZonesSkeleton(),
        error: (e, _) =>
            _ZonesError(onRetry: () => ref.invalidate(zonesProvider)),
        data: (zones) => zones.isEmpty
            ? const EmptyState(message: 'No zones available.')
            : RefreshIndicator(
                onRefresh: () => ref.read(zonesProvider.notifier).refresh(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth > 700
                        ? 3
                        : constraints.maxWidth < 360
                        ? 1
                        : 2;
                    final ratio = constraints.maxWidth > 700
                        ? 1.1
                        : constraints.maxWidth < 360
                        ? 1.35
                        : 0.98;
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: ratio,
                      ),
                      itemCount: zones.length,
                      itemBuilder: (context, i) => _ZoneCard(zone: zones[i]),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({required this.zone});
  final Zone zone;

  @override
  Widget build(BuildContext context) {
    final onlineRatio = zone.camerasCount > 0
        ? zone.onlineCameras / zone.camerasCount
        : 0.0;
    final healthColor = onlineRatio >= 0.9
        ? Colors.green
        : onlineRatio >= 0.6
        ? Colors.orange
        : Colors.red;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/cameras', arguments: zone),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.folder_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: healthColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                zone.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                zone.division,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              // Camera health bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: onlineRatio,
                  minHeight: 5,
                  backgroundColor: healthColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(healthColor),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${zone.onlineCameras}/${zone.camerasCount} cameras online',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZonesSkeleton extends StatelessWidget {
  const _ZonesSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.98,
      ),
      itemCount: 4,
      itemBuilder: (_, __) => const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 40, height: 40),
              SizedBox(height: 10),
              SkeletonBox(width: 80, height: 14),
              SizedBox(height: 6),
              SkeletonBox(width: 100, height: 10),
              SizedBox(height: 10),
              SkeletonBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZonesError extends StatelessWidget {
  const _ZonesError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('Failed to load zones'),
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
