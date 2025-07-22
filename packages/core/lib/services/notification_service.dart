import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;
  Map<String, dynamic>? _pendingNotificationData;

  // Controller for handling notification taps
  final StreamController<Map<String, dynamic>> _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Getter for notification stream
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationStreamController.stream;

  // Singleton constructor
  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> init({required GlobalKey<NavigatorState> navigatorKey}) async {
    if (_initialized) return;

    _navigatorKey = navigatorKey;
    debugPrint('Initializing NotificationService with navigator key...');

    try {
      // Check if messaging is supported before proceeding
      if (!(await _messaging.isSupported())) {
        debugPrint('Firebase Messaging is not supported on this device');
        _initialized = true; // Mark as initialized to avoid further attempts
        return;
      }

      // Request permissions on iOS (this is already handled in main.dart now but keeping as a fallback)
      if (Platform.isIOS) {
        try {
          await _messaging.requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );
        } catch (e) {
          debugPrint('Error requesting iOS notification permissions: $e');
          // Continue even if permission request fails
        }
      }
    } catch (e) {
      debugPrint('Error in notification service initialization: $e');
    }

    _initialized = true;
    debugPrint('NotificationService initialized');

    // Check for initial message (app opened from terminated state)
    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App opened from terminated state with notification: ${initialMessage.data}');
        // Store the notification data instead of immediately navigating
        _pendingNotificationData = initialMessage.data;
      }
    } catch (e) {
      debugPrint('Error getting initial message: $e');
    }

    // Setup message handlers
    _setupMessageHandlers();
  }

  Future<void> _setupMessageHandlers() async {
    try {
      debugPrint('🔧 Setting up FCM message handlers...');
      
      // Handle messages when app is in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📱 Foreground message received: ${message.messageId}');
        _showLocalNotification(message);
      });

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🔥🔥🔥 FCM NOTIFICATION TAPPED FROM BACKGROUND! 🔥🔥🔥');
        debugPrint('🔥 Message ID: ${message.messageId}');
        debugPrint('🔥 Message data: ${message.data}');
        debugPrint('🔥 Message title: ${message.notification?.title}');
        debugPrint('🔥 Message body: ${message.notification?.body}');
        debugPrint('🔥 From field: ${message.from}');
        debugPrint('🔥 Sent time: ${message.sentTime}');
        debugPrint('🔥 Category: ${message.category}');
        debugPrint('🔥 Message type: ${message.messageType}');
        _handleMessage(message);
      });
      
      debugPrint('🎯 onMessageOpenedApp listener registered successfully');

      debugPrint('✅ FCM message handlers set up successfully');

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get and save FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await _saveFcmToken(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_saveFcmToken);
    } catch (e) {
      debugPrint('Error setting up message handlers: $e');
    }
  }

  // Handle pending notification after app is fully initialized
  Future<void> handlePendingNotification(BuildContext context) async {
    if (_pendingNotificationData != null) {
      final data = _pendingNotificationData!;
      _pendingNotificationData = null; // Clear after processing
      
      debugPrint('Processing pending notification: $data');
      await _processNotificationWithAuthCheck(data);
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    try {
      const androidInitialization = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInitialization = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initializationSettings = InitializationSettings(
        android: androidInitialization,
        iOS: iosInitialization,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );
      debugPrint('Local notifications initialized');
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
    }
  }

  Future<void> _navigateToOrderStatus(String orderId, String userId) async {
    if (_navigatorKey?.currentState == null) {
      debugPrint('Navigator key is null or invalid');
      return;
    }

    // Add a small delay for terminated state to ensure app is properly initialized
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      _navigatorKey!.currentState!.pushNamed(
        '/order-status',
        arguments: {
          'orderId': orderId,
          'userId': userId,
        },
      );
      debugPrint('Navigated to order status screen with orderId: $orderId, userId: $userId');
    } catch (e) {
      debugPrint('Error navigating to order status: $e');
    }
  }

  // Show a local notification when a message is received in foreground
  Future<void> _showLocalNotification(RemoteMessage message) async {
    debugPrint('Received message in foreground: ${message.messageId}');
    debugPrint('Message data: ${message.data}');
    debugPrint(
        'Message notification: ${message.notification?.title} - ${message.notification?.body}');

    final notification = message.notification;
    final android = message.notification?.android;

    try {
      // Always show a notification, even without notification data
      if (notification != null) {
        await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'order_status_channel',
              'Order Status Notifications',
              channelDescription:
                  'This channel is used for order status notifications.',
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );
        debugPrint('Local notification displayed successfully');
      } else if (message.data.isNotEmpty) {
        // Create a notification from data payload if no notification was provided
        await _localNotifications.show(
          message.data.hashCode,
          message.data['title'] ?? 'New Notification',
          message.data['body'] ?? 'You have a new notification',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'order_status_channel',
              'Order Status Notifications',
              channelDescription:
                  'This channel is used for order status notifications.',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );
        debugPrint('Generated notification from data payload');
      } else {
        debugPrint('No notification or data available to display');
      }
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  // Handle a message when it's tapped
  void _handleMessage(RemoteMessage message) {
    debugPrint('🔥 FCM notification tapped! Message ID: ${message.messageId}');
    debugPrint('🔥 FCM notification data: ${message.data}');
    debugPrint('🔥 FCM notification title: ${message.notification?.title}');
    debugPrint('🔥 FCM notification body: ${message.notification?.body}');
    
    if (message.data.isNotEmpty) {
      debugPrint('🚀 Processing FCM notification tap with data: ${message.data}');
      
      // Add a delay to ensure the app is fully loaded for background/terminated scenarios
      Future.delayed(const Duration(milliseconds: 1000), () {
        debugPrint('🕐 Processing FCM notification after delay...');
        _processNotificationWithAuthCheck(message.data);
      });
    } else {
      debugPrint('❌ No data found in FCM notification');
    }
  }

  // Handle notification tap from local notification
  void _handleNotificationTap(NotificationResponse response) {
    debugPrint('📱 Local notification tapped! ID: ${response.id}');
    debugPrint('📱 Local notification payload: ${response.payload}');
    
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        // Parse the JSON payload back to Map
        final payloadMap = jsonDecode(response.payload!) as Map<String, dynamic>;
        debugPrint('🚀 Parsed notification payload: $payloadMap');
        
        // Wait for authentication to be available before handling navigation
        _processNotificationWithAuthCheck(payloadMap);
      } catch (e) {
        debugPrint('❌ Error parsing notification payload: $e');
        debugPrint('❌ Raw payload: ${response.payload}');
      }
    } else {
      debugPrint('❌ No payload found in notification tap');
    }
  }

  // Process notification data with auth check
  Future<void> _processNotificationWithAuthCheck(
      Map<String, dynamic> data) async {
    // Check for authenticated user
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      debugPrint(
          'User not authenticated yet, storing notification for later processing');
      // Store the notification data to process after auth
      _storeNotificationForLaterProcessing(data);
      return;
    }

    // Check if this is an order status notification
    if (data.containsKey('orderId') &&
        data.containsKey('route') &&
        data['route'] == 'order_status') {
      
      final String orderId = data['orderId'].toString();
      final String userId = data['userId']?.toString() ?? FirebaseAuth.instance.currentUser?.uid ?? '';
      
      // Navigate to the order status screen
      await _navigateToOrderStatus(orderId, userId);
      
      // Also add the notification data to the stream for any listeners
      _notificationStreamController.add(data);
      debugPrint('Notification data sent to stream and navigated to order status: $data');
    } else {
      // Add the data anyway in case other screens need to handle different notification types
      _notificationStreamController.add(data);
      debugPrint('Non-order notification data sent to stream: $data');
    }
  }

  // Store notification to process after authentication
  Future<void> _storeNotificationForLaterProcessing(
      Map<String, dynamic> data) async {
    try {
      // Store in shared preferences or another persistent storage
      // For now just set a listener on auth state changes
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user != null && data.isNotEmpty) {
          // User logged in, now process the stored notification
          debugPrint('User authenticated, now processing stored notification');
          _processNotificationWithAuthCheck(data);
        }
      });
    } catch (e) {
      debugPrint('Error storing notification for later: $e');
    }
  }

  // Save FCM token to Firestore
  Future<void> _saveFcmToken(String token) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      // Print full token for debugging
      debugPrint('FCM Token to save: $token');

      if (currentUser != null) {
        // Check if document exists first
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          // Document exists, we can update it
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({'fcmToken': token});

          // Verify token was saved correctly
          final updatedDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

          final savedToken = updatedDoc.data()?['fcmToken'];
          debugPrint('Saved FCM token verified: ${savedToken == token}');
        } else {
          // Document doesn't exist, we should create it
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .set({
            'fcmToken': token,
            'email': currentUser.email,
            'createdAt': FieldValue.serverTimestamp()
          });
        }

        debugPrint('FCM token saved to Firestore for user: ${currentUser.uid}');
      } else {
        // Even if no user is logged in, print the token for debugging
        debugPrint(
            'No user logged in, FCM token not saved. Token: ${token.substring(0, 10)}...');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  // Clear FCM token when user logs out
  Future<void> clearToken() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'fcmToken': ''});

        debugPrint('FCM token cleared for user: ${currentUser.uid}');
      }
    } catch (e) {
      debugPrint('Error clearing FCM token: $e');
      // Don't rethrow - we don't want logout to fail if token clearing fails
    }
  }

  // Dispose the stream controller
  void dispose() {
    _notificationStreamController.close();
  }
}

// Background message handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // We need to ensure Firebase is initialized for background messages
  // This would typically be done in main() but we'll do it here as well for safety
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Log the message but don't display a notification - the system will do that
  debugPrint('Handling a background message: ${message.messageId}');
}
