import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'routes/app_routes.dart';
import 'screens/admin_screen.dart';

// Background message handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background messages
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Handling a background message: ${message.messageId}');
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configure foreground notification presentation options
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Request permission for notifications (Android 13+ needs explicit permission)
  if (await FirebaseMessaging.instance.isSupported()) {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize notification service with navigator key
  await NotificationService().init(navigatorKey: navigatorKey);

  // Additional check for initial message (debugging)
  try {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
          '🚀 MAIN: App opened from terminated state with notification!');
      debugPrint('🚀 MAIN: Initial message ID: ${initialMessage.messageId}');
      debugPrint('🚀 MAIN: Initial message data: ${initialMessage.data}');
    } else {
      debugPrint('🚀 MAIN: No initial message found');
    }
  } catch (e) {
    debugPrint('🚀 MAIN: Error checking initial message: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Campus Bites - Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      routes: AppRoutes.getRoutes(),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final routes = AppRoutes.getRoutes();
        final builder = routes[settings.name];
        if (builder != null) {
          return MaterialPageRoute(
            settings: settings,
            builder: builder,
          );
        }

        // Handle unknown routes
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
      },
      home: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          // Check authentication status
          if (userProvider.isLoading ||
              (userProvider.isAuthenticated && userProvider.user == null)) {
            // Still loading user data or user is authenticated but user data not loaded yet
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Determine route based on auth status and verification
          if (!userProvider.isAuthenticated) {
            return LoginScreen(
              onLoginSuccess: (context, userRole, isEmailVerified) {
                if (userRole != 'admin') {
                  // Show access denied for non-admins
                  Navigator.pushReplacementNamed(context, '/access-denied');
                } else if (!isEmailVerified) {
                  Navigator.pushReplacementNamed(
                      context, '/email-verification');
                } else {
                  Navigator.pushReplacementNamed(context, '/admin-home');
                }
              },
            );
          }

          // Only allow admins in this app
          if (userProvider.user?.role != 'admin') {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Access Denied',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('This app is only for administrators.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        userProvider.signOut();
                      },
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            );
          }

          return const AdminVendorManagementScreen();
        },
      ),
    );
  }
}
