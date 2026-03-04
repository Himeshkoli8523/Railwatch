import 'package:cctv/app/flavor.dart';
import 'package:cctv/app/app_providers.dart';
import 'package:cctv/core/widgets/common_widgets.dart';
import 'package:cctv/features/dashboard/presentation/dashboard_screen.dart';
import 'package:cctv/features/profile/presentation/profile_screen.dart';
import 'package:cctv/features/settings/presentation/settings_screen.dart';
import 'package:cctv/features/videos/domain/entities/camera.dart';
import 'package:cctv/features/videos/domain/entities/zone.dart';
import 'package:cctv/features/videos/presentation/cameras_screen.dart';
import 'package:cctv/features/videos/presentation/video_list_screen.dart';
import 'package:cctv/features/videos/presentation/video_player_screen.dart';
import 'package:cctv/features/videos/presentation/zones_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.flavor});

  final AppFlavor flavor;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;
  bool _shownTokenModal = false;

  @override
  Widget build(BuildContext context) {
    final connection = ref.watch(connectionProvider);
    final auth = ref.watch(authProvider);
    ref.listen<AsyncValue<int>>(tokenCountdownProvider, (previous, next) {
      final value = next.valueOrNull;
      if (value != null && value > 0 && value < 60 && !_shownTokenModal) {
        _shownTokenModal = true;
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Session Expiring'),
            content: Text('Token expires in $value seconds.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(authProvider.notifier).refreshToken();
                  _shownTokenModal = false;
                },
                child: const Text('Refresh'),
              ),
            ],
          ),
        );
      }
    });

    final pages = [
      const DashboardScreen(),
      const _VideosTabNavigator(),
      const ProfileScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Semantics(
          label: 'Global search',
          child: SizedBox(
            height: 40,
            child: TextField(
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              child: Text(
                (auth.user?.name.isNotEmpty ?? false)
                    ? auth.user!.name.substring(0, 1).toUpperCase()
                    : 'U',
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!connection.isConnected)
            OfflineBanner(
              lastSync: connection.lastSync,
              onSyncQueueTap: () => setState(() => _index = 3),
            ),
          if (connection.slowBackend)
            Material(
              color: Colors.orange.shade100,
              child: ListTile(
                minTileHeight: 44,
                title: const Text('Slow backend response detected.'),
                trailing: TextButton(
                  onPressed: () {},
                  child: const Text('Load cached data'),
                ),
              ),
            ),
          Expanded(
            child: IndexedStack(index: _index, children: pages),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            label: 'Videos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ── Videos tab with its own Navigator stack ───────────────────────────────
// This keeps the BottomNavigationBar visible while the user navigates
// Zone → Camera → Video List inside the Videos tab.

class _VideosTabNavigator extends StatelessWidget {
  const _VideosTabNavigator();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: const ValueKey('videos-tab-navigator'),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/cameras':
            final zone = settings.arguments as Zone;
            return MaterialPageRoute(builder: (_) => CamerasScreen(zone: zone));
          case '/video-list':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => VideoListScreen(
                zone: args['zone'] as Zone,
                camera: args['camera'] as Camera,
              ),
            );
          case '/player':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(
                streamUrl: args['streamUrl'] as String,
                title: args['title'] as String,
                videoId: args['videoId'] as String?,
              ),
            );
          default:
            return MaterialPageRoute(builder: (_) => const ZonesScreen());
        }
      },
    );
  }
}
