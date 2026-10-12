import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

/// Build with `--dart-define=DEMO=true` to run against the local Firebase
/// Emulator Suite seeded by `tool/demo` instead of the production project.
const bool kDemoMode = bool.fromEnvironment('DEMO');

/// Overrides the emulator host, e.g. a LAN IP when running on a real device.
const String _demoHostOverride = String.fromEnvironment('DEMO_HOST');

/// Accounts created by `tool/demo/seed.mjs`.
class DemoAccounts {
  static const password = 'campusbites-demo';
  static const student = 'nour.hassan@students.eui.edu.eg';
  static const vendor = 'university.cafe@students.eui.edu.eg';
  static const admin = 'admin@eui.edu.eg';
}

String get _demoHost {
  if (_demoHostOverride.isNotEmpty) return _demoHostOverride;
  // The Android emulator reaches the host machine through 10.0.2.2.
  return defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2'
      : 'localhost';
}

// "demo-" project ids never touch real Firebase resources. The key only has to
// be well-formed; the emulators ignore it.
FirebaseOptions get _demoOptions => FirebaseOptions(
      apiKey: 'AIzaSyD-demo-campusbites-emulator-only0',
      appId: defaultTargetPlatform == TargetPlatform.android
          ? '1:000000000000:android:0000000000000000'
          : '1:000000000000:ios:0000000000000000',
      messagingSenderId: '000000000000',
      projectId: 'demo-campusbites',
      storageBucket: 'demo-campusbites.appspot.com',
    );

/// Initialises Firebase for all three apps: production by default, the local
/// emulators in demo builds.
Future<void> initCampusFirebase() async {
  if (!kDemoMode) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    return;
  }

  await Firebase.initializeApp(options: _demoOptions);
  final host = _demoHost;
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  await FirebaseStorage.instance.useStorageEmulator(host, 9199);
  FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
}
