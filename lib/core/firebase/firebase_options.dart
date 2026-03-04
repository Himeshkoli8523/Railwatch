// File generated — hand-crafted from `firebase apps:sdkconfig ANDROID`.
// DO NOT commit to public repos — contains API keys.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ── Android ──────────────────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDFMqtvUDvS1kA91r-fM_6Hs7aLSKItnbw',
    appId: '1:131877908080:android:44289cfa988aa2bd264eb5',
    messagingSenderId: '131877908080',
    projectId: 'cctv-watch-app',
    storageBucket: 'cctv-watch-app.firebasestorage.app',
  );

  // ── iOS (placeholder — add real GoogleService-Info.plist values) ─────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDFMqtvUDvS1kA91r-fM_6Hs7aLSKItnbw',
    appId: '1:131877908080:ios:placeholder',
    messagingSenderId: '131877908080',
    projectId: 'cctv-watch-app',
    storageBucket: 'cctv-watch-app.firebasestorage.app',
    iosBundleId: 'com.example.cctv',
  );

  // ── macOS (placeholder) ──────────────────────────────────────────────────
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDFMqtvUDvS1kA91r-fM_6Hs7aLSKItnbw',
    appId: '1:131877908080:ios:placeholder',
    messagingSenderId: '131877908080',
    projectId: 'cctv-watch-app',
    storageBucket: 'cctv-watch-app.firebasestorage.app',
    iosBundleId: 'com.example.cctv',
  );

  // ── Web (placeholder) ────────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDFMqtvUDvS1kA91r-fM_6Hs7aLSKItnbw',
    appId: '1:131877908080:web:placeholder',
    messagingSenderId: '131877908080',
    projectId: 'cctv-watch-app',
    storageBucket: 'cctv-watch-app.firebasestorage.app',
  );

  // ── Windows (placeholder) ────────────────────────────────────────────────
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDFMqtvUDvS1kA91r-fM_6Hs7aLSKItnbw',
    appId: '1:131877908080:web:placeholder',
    messagingSenderId: '131877908080',
    projectId: 'cctv-watch-app',
    storageBucket: 'cctv-watch-app.firebasestorage.app',
  );
}
