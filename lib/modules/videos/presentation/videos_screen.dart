import 'dart:async';

import 'package:cctv/shared/models/app_models.dart';
import 'package:cctv/shared/state/global_providers.dart';
import 'package:cctv/shared/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VideosScreen extends ConsumerStatefulWidget {
  const VideosScreen({super.key});

  @override
  ConsumerState<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends ConsumerState<VideosScreen> {
  final List<VideoItem> _items = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selected = {};
  final Set<String> _filterTags = {};
  Timer? _debounce;
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadNext();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadNext();
      }
    });
    _searchController.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        _refresh();
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _page = 1;
      _hasMore = true;
    });
    await _loadNext();
  }

  Future<void> _loadNext() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    final api = ref.read(mockApiProvider);
    final next = await api.getVideos(
      page: _page,
      size: 20,
      query: _searchController.text,
      tags: _filterTags.toList(),
    );
    setState(() {
      _items.addAll(next);
      _loading = false;
      _hasMore = next.isNotEmpty;
      if (next.isNotEmpty) _page++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final role = auth.role ?? AppRole.operator;
    final canBulkDelete = role == AppRole.admin;

    return Column(
      children: [
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
              if (_selected.isNotEmpty)
                PopupMenuButton<String>(
                  tooltip: canBulkDelete
                      ? 'Bulk actions'
                      : 'No permission for bulk actions',
                  enabled: canBulkDelete,
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
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ['DoorOpen', 'Smoke', 'BearingHeat'].map((tag) {
              final selected = _filterTags.contains(tag);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  selected: selected,
                  label: Text(tag),
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _filterTags.add(tag);
                      } else {
                        _filterTags.remove(tag);
                      }
                    });
                    _refresh();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: _items.isEmpty && _loading
              ? ListView.builder(
                  itemCount: 8,
                  itemBuilder: (_, __) => const ListTile(
                    leading: SkeletonBox(height: 52, width: 84),
                    title: SkeletonBox(width: 160),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: SkeletonBox(width: 220),
                    ),
                  ),
                )
              : _items.isEmpty
              ? const EmptyState(
                  message: 'No videos found for selected filters.',
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: _items.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final item = _items[index];
                    final selected = _selected.contains(item.id);
                    return Semantics(
                      label: 'Video item ${item.id}',
                      child: ListTile(
                        minTileHeight: 64,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/video',
                          arguments: item.id,
                        ),
                        onLongPress: () => setState(() {
                          selected
                              ? _selected.remove(item.id)
                              : _selected.add(item.id);
                        }),
                        selected: selected,
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
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
