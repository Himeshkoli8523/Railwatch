import 'package:cctv/app/app_providers.dart';
import 'package:cctv/core/auth/auth_policy.dart';
import 'package:cctv/core/constants/app_enums.dart';
import 'package:cctv/core/widgets/common_widgets.dart';
import 'package:cctv/features/videos/presentation/videos_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Entry point widget — a thin ConsumerWidget that simply renders the body.
class VideosScreen extends ConsumerWidget {
  const VideosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const _VideosScreenBody();
}

// ---------------------------------------------------------------------------
// Body — owns scroll/search controllers and grid-toggle state only.
// All data logic lives in VideosNotifier (videos_provider.dart).
// ---------------------------------------------------------------------------

class _VideosScreenBody extends ConsumerStatefulWidget {
  const _VideosScreenBody();

  @override
  ConsumerState<_VideosScreenBody> createState() => _VideosScreenBodyState();
}

class _VideosScreenBodyState extends ConsumerState<_VideosScreenBody> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selected = {};
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(videosStateProvider.notifier).loadNext();
      }
    });
    _searchController.addListener(() {
      ref.read(videosStateProvider.notifier).setQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final role = auth.role ?? AppRole.operator;
    final canBulk = hasPermission(
      role: role,
      explicitPermissions: auth.user?.permissions,
      permission: AppPermissions.manageVideos,
    );

    return Column(
      children: [
        // ── Search bar + view toggle + bulk action ──
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search by camera/train/wagon',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.view_list),
                    label: Text('List'),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(Icons.grid_view),
                    label: Text('Grid'),
                  ),
                ],
                selected: {_isGridView},
                onSelectionChanged: (value) =>
                    setState(() => _isGridView = value.first),
              ),
              const SizedBox(width: 8),
              if (_selected.isNotEmpty)
                PopupMenuButton<String>(
                  enabled: canBulk,
                  tooltip: canBulk
                      ? 'Bulk actions'
                      : 'No permission for bulk actions',
                  onSelected: (_) => setState(_selected.clear),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'ack',
                      child: Text('Acknowledge selected'),
                    ),
                    PopupMenuItem(
                      value: 'export',
                      child: Text('Export selected'),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // ── Horizontal filter chips ──
        SizedBox(
          height: 40,
          child: Consumer(
            builder: (context, ref, _) {
              final filterTags = ref.watch(videosStateProvider).filterTags;
              return ListView(
                scrollDirection: Axis.horizontal,
                children: ['DoorOpen', 'Smoke', 'BearingHeat'].map((tag) {
                  final selected = filterTags.contains(tag);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      selected: selected,
                      label: Text(tag),
                      onSelected: (_) => ref
                          .read(videosStateProvider.notifier)
                          .toggleFilterTag(tag),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),

        // ── Main content area ──
        Expanded(
          child: Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(videosStateProvider);

              // Loading skeleton
              if (state.items.isEmpty && state.loading) {
                return ListView.builder(
                  itemCount: 8,
                  itemBuilder: (_, __) => const ListTile(
                    leading: SkeletonBox(height: 52, width: 84),
                    title: SkeletonBox(width: 160),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: SkeletonBox(width: 220),
                    ),
                  ),
                );
              }

              // Empty state
              if (state.items.isEmpty) {
                return const EmptyState(
                  message: 'No videos found for selected filters.',
                );
              }

              // Grid view
              if (_isGridView) {
                return GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 250,
                    childAspectRatio: 0.80,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: state.items.length + (state.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= state.items.length) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final item = state.items[index];
                    final selected = _selected.contains(item.id);
                    return Card(
                      child: InkWell(
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/player',
                          arguments: {
                            'videoId': item.id,
                            'streamUrl': item.signedUrlStatus,
                            'title':
                                '${item.cameraId} · ${item.timestamp.toIso8601String()}',
                          },
                        ),
                        onLongPress: () => setState(() {
                          selected
                              ? _selected.remove(item.id)
                              : _selected.add(item.id);
                        }),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.thumbnailUrl,
                                  height: 96,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) =>
                                      progress == null
                                      ? child
                                      : const SkeletonBox(height: 96),
                                  errorBuilder: (_, __, ___) => const SizedBox(
                                    height: 96,
                                    child: Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.cameraId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${item.trainId} • ${item.wagonId}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: SeverityBadge(severity: item.severity),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }

              // List view
              return ListView.builder(
                controller: _scrollController,
                itemCount: state.items.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.items.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final item = state.items[index];
                  final selected = _selected.contains(item.id);
                  return ListTile(
                    minTileHeight: 64,
                    selected: selected,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/player',
                      arguments: {
                        'videoId': item.id,
                        'streamUrl': item.signedUrlStatus,
                        'title':
                            '${item.cameraId} · ${item.timestamp.toIso8601String()}',
                      },
                    ),
                    onLongPress: () => setState(() {
                      selected
                          ? _selected.remove(item.id)
                          : _selected.add(item.id);
                    }),
                    leading: SizedBox(
                      width: 84,
                      child: Image.network(
                        item.thumbnailUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) =>
                            progress == null
                            ? child
                            : const SkeletonBox(height: 52, width: 84),
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.cameraId} • ${item.wagonId} • ${item.trainId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SeverityBadge(severity: item.severity),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.timestamp.toIso8601String()} • ${item.duration}',
                        ),
                        Wrap(
                          spacing: 4,
                          children: item.aiTags
                              .map(
                                (tag) => Chip(
                                  label: Text(tag),
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'flag', child: Text('Flag')),
                        PopupMenuItem(
                          value: 'download',
                          child: Text('Download'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
