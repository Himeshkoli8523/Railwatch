import 'dart:async';

import 'package:cctv/app/app_providers.dart';
import 'package:cctv/core/constants/app_constants.dart';
import 'package:cctv/features/videos/domain/entities/camera.dart';
import 'package:cctv/features/videos/domain/entities/video_item.dart';
import 'package:cctv/features/videos/domain/entities/zone.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Zones ────────────────────────────────────────────────────────────────────

final zonesProvider = AsyncNotifierProvider<ZonesNotifier, List<Zone>>(
  ZonesNotifier.new,
);

class ZonesNotifier extends AsyncNotifier<List<Zone>> {
  @override
  Future<List<Zone>> build() => ref.watch(videosRepositoryProvider).getZones();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(videosRepositoryProvider).getZones(),
    );
  }
}

// ── Cameras ──────────────────────────────────────────────────────────────────

final camerasProvider =
    AsyncNotifierProvider.family<CamerasNotifier, List<Camera>, String>(
  CamerasNotifier.new,
);

class CamerasNotifier extends FamilyAsyncNotifier<List<Camera>, String> {
  @override
  Future<List<Camera>> build(String zoneId) =>
      ref.watch(videosRepositoryProvider).getCamerasForZone(zoneId);

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(videosRepositoryProvider).getCamerasForZone(arg),
    );
  }
}

// ── Video list (cursor-based) ─────────────────────────────────────────────

/// Args passed into the video list notifier.
class VideoListArgs {
  const VideoListArgs({
    required this.zoneId,
    required this.cameraId,
  });

  final String zoneId;
  final String cameraId;

  @override
  bool operator ==(Object other) =>
      other is VideoListArgs &&
      other.zoneId == zoneId &&
      other.cameraId == cameraId;

  @override
  int get hashCode => Object.hash(zoneId, cameraId);
}

class VideoListState {
  const VideoListState({
    this.items = const [],
    this.nextCursor,
    this.loading = false,
    this.query = '',
    this.filterTags = const {},
    this.error,
  });

  final List<VideoItem> items;
  final String? nextCursor;
  final bool loading;
  final String query;
  final Set<String> filterTags;
  final Object? error;

  bool get hasMore => nextCursor != null;

  VideoListState copyWith({
    List<VideoItem>? items,
    String? Function()? nextCursor,
    bool? loading,
    String? query,
    Set<String>? filterTags,
    Object? error,
  }) {
    return VideoListState(
      items: items ?? this.items,
      nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
      loading: loading ?? this.loading,
      query: query ?? this.query,
      filterTags: filterTags ?? this.filterTags,
      error: error,
    );
  }
}

final videoListProvider = StateNotifierProvider.family<
    VideoListNotifier, VideoListState, VideoListArgs>(
  (ref, args) => VideoListNotifier(ref, args),
);

class VideoListNotifier extends StateNotifier<VideoListState> {
  VideoListNotifier(this.ref, this.args) : super(const VideoListState()) {
    loadNext();
  }

  final Ref ref;
  final VideoListArgs args;
  Timer? _debounce;

  Future<void> refresh() async {
    state = state.copyWith(
      items: [],
      nextCursor: () => null,
      loading: false,
    );
    await loadNext();
  }

  Future<void> loadNext() async {
    if (state.loading || (!state.hasMore && state.items.isNotEmpty)) return;
    state = state.copyWith(loading: true);

    try {
      final page = await ref.read(videosRepositoryProvider).getVideos(
            zoneId: args.zoneId,
            cameraId: args.cameraId,
            cursor: state.nextCursor,
            query: state.query,
            tags: state.filterTags.toList(),
          );
      state = state.copyWith(
        items: [...state.items, ...page.items],
        nextCursor: () => page.nextCursor,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  void setQuery(String query) {
    if (state.query == query) return;
    state = state.copyWith(
      query: query,
      items: [],
      nextCursor: () => null,
    );
    _debounce?.cancel();
    _debounce = Timer(AppConstants.searchDebounce, refresh);
  }

  void toggleFilterTag(String tag) {
    final tags = Set<String>.from(state.filterTags);
    if (tags.contains(tag)) {
      tags.remove(tag);
    } else {
      tags.add(tag);
    }
    state = state.copyWith(
      filterTags: tags,
      items: [],
      nextCursor: () => null,
    );
    refresh();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

// ── Global videos provider (all zones/cameras combined) ────────────────────
// Used by VideosScreen for browsing across the entire fleet.
// Uses a sentinel zoneId/cameraId of '*' that the mock repo treats as
// "return videos from any source".

final _globalVideoArgs = const VideoListArgs(zoneId: '*', cameraId: '*');

final videosStateProvider = StateNotifierProvider<VideoListNotifier, VideoListState>(
  (ref) => VideoListNotifier(ref, _globalVideoArgs),
);
