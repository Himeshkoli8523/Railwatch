import 'package:cctv/core/widgets/common_widgets.dart';
import 'package:cctv/features/videos/domain/entities/camera.dart';
import 'package:cctv/features/videos/domain/entities/zone.dart';
import 'package:cctv/features/videos/presentation/videos_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VideoListScreen extends ConsumerStatefulWidget {
  const VideoListScreen({
    super.key,
    required this.zone,
    required this.camera,
  });

  final Zone zone;
  final Camera camera;

  @override
  ConsumerState<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends ConsumerState<VideoListScreen> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();
  bool _isGrid = false;

  late final VideoListArgs _args;

  @override
  void initState() {
    super.initState();
    _args = VideoListArgs(
      zoneId: widget.zone.id,
      cameraId: widget.camera.id,
    );
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 300) {
      ref.read(videoListProvider(_args).notifier).loadNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(videoListProvider(_args));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.camera.name),
            Text(
              '${widget.zone.name} · ${widget.zone.division}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isGrid ? Icons.view_list : Icons.grid_view),
            tooltip: _isGrid ? 'List view' : 'Grid view',
            onPressed: () => setState(() => _isGrid = !_isGrid),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search & filters ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              controller: _search,
              onChanged: (v) =>
                  ref.read(videoListProvider(_args).notifier).setQuery(v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search videos…',
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: Consumer(
              builder: (context, ref, _) {
                final tags = ref.watch(videoListProvider(_args)).filterTags;
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  children: ['DoorOpen', 'Smoke', 'BearingHeat', 'Motion'].map((tag) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(tag),
                        selected: tags.contains(tag),
                        onSelected: (_) => ref
                            .read(videoListProvider(_args).notifier)
                            .toggleFilterTag(tag),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          // ── Video count badge ──
          if (state.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  Text(
                    '${state.items.length}+ videos loaded',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const Spacer(),
                  if (state.hasMore)
                    const Text(
                      'Scroll to load more',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
            ),
          // ── Main list/grid ──
          Expanded(
            child: _buildContent(state),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(VideoListState state) {
    if (state.items.isEmpty && state.loading) {
      return ListView.builder(
        itemCount: 8,
        itemBuilder: (_, __) => const ListTile(
          leading: SkeletonBox(width: 84, height: 52),
          title: SkeletonBox(width: 160, height: 14),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 6),
            child: SkeletonBox(width: 220, height: 11),
          ),
        ),
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            const Text('Failed to load videos'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(videoListProvider(_args).notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.items.isEmpty) {
      return const EmptyState(message: 'No videos found for this camera.');
    }

    if (_isGrid) {
      return GridView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 240,
          childAspectRatio: 0.85,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final item = state.items[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.pushNamed(
                context,
                '/player',
                arguments: {
                  'videoId': item.id,
                  'streamUrl': item.signedUrlStatus,
                  'title': '${item.cameraId} · ${item.timestamp}',
                },
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Image.network(
                      item.thumbnailUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.cameraId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.duration,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                            SeverityBadge(severity: item.severity),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return ListView.builder(
      controller: _scroll,
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final item = state.items[index];
        return ListTile(
          minTileHeight: 64,
          onTap: () => Navigator.pushNamed(
            context,
            '/player',
            arguments: {
              'videoId': item.id,
              'streamUrl': item.signedUrlStatus,
              'title': '${item.cameraId} · ${item.timestamp}',
            },
          ),
          leading: SizedBox(
            width: 84,
            child: Image.network(
              item.thumbnailUrl,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : const SkeletonBox(width: 84, height: 52),
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image),
            ),
          ),
          title: Text(
            '${item.cameraId} · ${item.wagonId} · ${item.trainId}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.timestamp.toLocal().toString().substring(0, 16)} · ${item.duration}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Wrap(
                spacing: 4,
                children: item.aiTags
                    .map((t) => Chip(
                          label: Text(t),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
          ),
          trailing: SeverityBadge(severity: item.severity),
        );
      },
    );
  }
}
