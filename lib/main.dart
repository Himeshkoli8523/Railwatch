import 'package:cctv/app/app.dart';
import 'package:cctv/app/flavor.dart';
import 'package:cctv/core/firebase/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  const flavorName = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  runApp(
    ProviderScope(child: CctvApp(flavor: AppFlavorX.fromName(flavorName))),
  );
}
