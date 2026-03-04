import 'package:cctv/features/videos/domain/entities/video_item.dart';

/// Cursor-based page result — scales to 10M+ videos.
/// [nextCursor] is null when there are no more items.
class VideoPage {
  const VideoPage({
    required this.items,
    this.nextCursor,
  });

  final List<VideoItem> items;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;
}
