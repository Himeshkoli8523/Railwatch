import 'package:cctv/shared/widgets/common_widgets.dart';
import 'package:flutter/material.dart';

class ScreenGallery extends StatelessWidget {
  const ScreenGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UI State Gallery')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('Loading state'),
          SizedBox(height: 8),
          SkeletonBox(height: 18, width: 180),
          SizedBox(height: 8),
          SkeletonBox(height: 100, width: double.infinity),
          SizedBox(height: 16),
          Text('Empty state'),
          SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: EmptyState(message: 'No records available for this period.'),
          ),
          SizedBox(height: 16),
          Text('Error state'),
          SizedBox(height: 8),
          Card(
            child: ListTile(
              title: Text('Network error'),
              subtitle: Text('Unable to fetch latest data.'),
              trailing: Text('Retry'),
            ),
          ),
          SizedBox(height: 16),
          Text('Offline role variation'),
          SizedBox(height: 8),
          OfflineBanner(lastSync: null, onSyncQueueTap: _noop),
        ],
      ),
    );
  }

  static void _noop() {}
}
