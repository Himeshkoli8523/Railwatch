import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({
    super.key,
    required this.streamUrl,
    required this.title,
    this.videoId,
  });

  final String streamUrl;
  final String title;
  final String? videoId;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _isInitializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      // In production: use a real RTSP/HLS URL.
      // We use a public HLS sample stream since mock URLs are not real.
      final uri = _resolvePlayableUrl(widget.streamUrl);

      _controller = VideoPlayerController.networkUrl(uri);
      await _controller!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
        additionalOptions: (context) => [
          OptionItem(
            onTap: (BuildContext ctx) {},
            iconData: Icons.download_outlined,
            title: 'Download',
          ),
          OptionItem(
            onTap: (BuildContext ctx) {},
            iconData: Icons.flag_outlined,
            title: 'Flag',
          ),
        ],
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        errorBuilder: (context, errorMessage) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 48),
              const SizedBox(height: 12),
              Text(
                'Playback error:\n$errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );

      if (mounted) setState(() => _isInitializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _error = e.toString();
        });
      }
    }
  }

  /// In a real app this maps the API stream URL to a playable URI.
  /// For mock purposes we fall back to a public HLS test stream.
  Uri _resolvePlayableUrl(String url) {
    // If it starts with a valid HTTP/S URL, use it directly.
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Uri.parse(url);
    }
    // Fallback demo stream for mock data (Apple HLS sample).
    return Uri.parse(
      'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8',
    );
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.videoId != null)
              Text(
                widget.videoId!,
                style:
                    const TextStyle(fontSize: 11, color: Colors.white54),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            onPressed: () {},
            tooltip: 'Download',
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: Colors.white),
            onPressed: () {},
            tooltip: 'Flag video',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Video player ──
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _buildPlayer(),
          ),

          // ── Metadata ──
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Video Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _MetaRow(icon: Icons.videocam_outlined, label: 'Camera', value: widget.title.split('·').first.trim()),
                  _MetaRow(icon: Icons.schedule_outlined, label: 'Timestamp', value: widget.title.split('·').last.trim()),
                  if (widget.videoId != null)
                    _MetaRow(icon: Icons.tag_outlined, label: 'Video ID', value: widget.videoId!),
                  const SizedBox(height: 20),
                  const Text('Actions'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Download'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.flag_outlined),
                        label: const Text('Flag'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('View Report'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    if (_isInitializing) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_error != null) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Stream unavailable',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isInitializing = true;
                  });
                  _initPlayer();
                },
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Chewie(controller: _chewieController!);
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
