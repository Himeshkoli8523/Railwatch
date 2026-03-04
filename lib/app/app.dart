import 'package:cctv/app/flavor.dart';
import 'package:cctv/app/main_shell.dart';
import 'package:cctv/app/app_providers.dart';
import 'package:cctv/core/auth/auth_policy.dart';
import 'package:cctv/core/constants/app_enums.dart';
import 'package:cctv/core/l10n/app_localizations.dart';
import 'package:cctv/features/auth/presentation/forgot_password_screen.dart';
import 'package:cctv/features/auth/presentation/login_screen.dart';
import 'package:cctv/features/auth/presentation/signup_screen.dart';
import 'package:cctv/features/videos/domain/entities/camera.dart';
import 'package:cctv/features/videos/domain/entities/zone.dart';
import 'package:cctv/features/videos/presentation/cameras_screen.dart';
import 'package:cctv/features/videos/presentation/video_list_screen.dart';
import 'package:cctv/features/videos/presentation/video_player_screen.dart';
import 'package:cctv/features/videos/presentation/zones_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CctvApp extends ConsumerWidget {
  const CctvApp({super.key, required this.flavor});

  final AppFlavor flavor;

  bool _canViewVideos(AuthState auth) {
    if (!auth.isAuthenticated) return false;
    final role = auth.role ?? AppRole.operator;
    return hasPermission(
      role: role,
      explicitPermissions: auth.user?.permissions,
      permission: AppPermissions.viewVideos,
    );
  }

  MaterialPageRoute<void> _loginRoute() {
    return MaterialPageRoute(builder: (_) => const LoginScreen());
  }

  MaterialPageRoute<void> _homeRoute() {
    return MaterialPageRoute(builder: (_) => MainShell(flavor: flavor));
  }

  MaterialPageRoute<void> _accessDeniedRoute(String message) {
    return MaterialPageRoute(
      builder: (_) =>
          _RouteMessageScreen(title: 'Access denied', message: message),
    );
  }

  MaterialPageRoute<void> _invalidRouteArgs(String message) {
    return MaterialPageRoute(
      builder: (_) => _RouteMessageScreen(
        title: 'Invalid navigation request',
        message: message,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CCTV',
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
          contrastLevel: 1,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: auth.isAuthenticated
          ? MainShell(flavor: flavor)
          : const LoginScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            return auth.isAuthenticated ? _homeRoute() : _loginRoute();
          case '/login':
            return auth.isAuthenticated ? _homeRoute() : _loginRoute();
          case '/signup':
            if (auth.isAuthenticated) return _homeRoute();
            return MaterialPageRoute(builder: (_) => const SignupScreen());
          case '/forgot-password':
            if (auth.isAuthenticated) return _homeRoute();
            return MaterialPageRoute(
              builder: (_) => const ForgotPasswordScreen(),
            );
          case '/zones':
            if (!auth.isAuthenticated) return _loginRoute();
            if (!_canViewVideos(auth)) {
              return _accessDeniedRoute(
                'You do not have permission to view video zones.',
              );
            }
            return MaterialPageRoute(builder: (_) => const ZonesScreen());
          case '/cameras':
            if (!auth.isAuthenticated) return _loginRoute();
            if (!_canViewVideos(auth)) {
              return _accessDeniedRoute(
                'You do not have permission to view camera feeds.',
              );
            }
            final zone = settings.arguments;
            if (zone is! Zone) {
              return _invalidRouteArgs(
                'Expected a Zone argument for /cameras.',
              );
            }
            return MaterialPageRoute(builder: (_) => CamerasScreen(zone: zone));
          case '/video-list':
            if (!auth.isAuthenticated) return _loginRoute();
            if (!_canViewVideos(auth)) {
              return _accessDeniedRoute(
                'You do not have permission to view video lists.',
              );
            }
            final args = settings.arguments;
            if (args is! Map<String, dynamic>) {
              return _invalidRouteArgs(
                'Expected a map argument for /video-list.',
              );
            }
            final zone = args['zone'];
            final camera = args['camera'];
            if (zone is! Zone || camera is! Camera) {
              return _invalidRouteArgs(
                'Expected both Zone and Camera arguments for /video-list.',
              );
            }
            return MaterialPageRoute(
              builder: (_) => VideoListScreen(zone: zone, camera: camera),
            );
          case '/player':
            if (!auth.isAuthenticated) return _loginRoute();
            if (!_canViewVideos(auth)) {
              return _accessDeniedRoute(
                'You do not have permission to play videos.',
              );
            }
            final args = settings.arguments;
            if (args is! Map<String, dynamic>) {
              return _invalidRouteArgs('Expected a map argument for /player.');
            }
            final streamUrl = args['streamUrl'];
            final title = args['title'];
            if (streamUrl is! String || title is! String) {
              return _invalidRouteArgs(
                'Expected streamUrl and title string arguments for /player.',
              );
            }
            return MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(
                streamUrl: streamUrl,
                title: title,
                videoId: args['videoId'] as String?,
              ),
            );
          default:
            return _invalidRouteArgs(
              'Route not found: ${settings.name ?? '(null)'}',
            );
        }
      },
    );
  }
}

class _RouteMessageScreen extends StatelessWidget {
  const _RouteMessageScreen({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (_) => false,
                ),
                child: const Text('Back to login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
