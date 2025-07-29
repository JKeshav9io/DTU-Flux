import 'dart:async';
import 'dart:convert';
import 'package:dtu_connect/alerts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/googleapis_auth.dart';

class NotificationServices {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  // Use a navigator key for global context
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void requestNotificationPermissions() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true, // Remove unused permissions
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  void initLocalNotification(BuildContext context, RemoteMessage message) async { // Remove BuildContext parameter
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          final data = jsonDecode(response.payload!) as Map<String, dynamic>;
          RemoteMessage mockMessage = RemoteMessage(data: data);
          handleMessage(mockMessage);  // Use mock message
        }
      },
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  Future<String> getToken() async {
    String? token = await messaging.getToken();
    return token ?? "";
  }

  void isTokenRefresh() => messaging.onTokenRefresh.listen((token) {
    print("Token refreshed: $token");
  });

  Future<void> showNotification(RemoteMessage message) async {
    final payload = jsonEncode(message.data); // Encode data for payload

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    _flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformDetails,
      payload: payload, // Pass payload here
    );
  }

  void firebaseinit(BuildContext context ) { // Remove BuildContext parameter
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(message.notification?.body.toString());
      print(message.notification?.title.toString());
      print(message.data.toString());
      print(message.data["type"]);
      //print('Foreground message: ${message.notification?.title}');
      initLocalNotification(context, message);
      showNotification(message); // Works for both platforms
    });
  }
  void handleMessage(RemoteMessage message) {
    if (message.data["screen"] == 'alerts') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => AlertsScreen()),
      );
    }
  }


  Future<void> setupInteractMessage() async {
    // When app is terminated and opened via notification
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      handleMessage(initialMessage);
    }

    // When app is in background and opened via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleMessage(message);
    });
  }

  Future<void> sendNotificationToTopic({
    required String title,
    required String body,
    required String screenToNavigate,
  }) async {
    final token = await GetServerKey().getServerKeyToken();

    const topic = '2024_MCE_B05';
    const projectId = 'dtu-connect-2';

    final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

    final message = {
      "message": {
        "topic": topic,
        "notification": {
          "title": title,
          "body": body,
        },
        "data": {
          "screen": screenToNavigate,
        }
      }
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('✅ Notification sent to topic "$topic"');
    } else {
      print('❌ Failed to send notification: ${response.body}');
    }
  }

}

class GetServerKey {
  static String? _cachedToken;
  static DateTime? _expiryTime;

  Future<String> getServerKeyToken() async {
    if (_cachedToken != null && _expiryTime != null && DateTime.now().isBefore(_expiryTime!)) {
      return _cachedToken!;
    }

    // Load JSON credentials
    final jsonString = await rootBundle.loadString('Assets/secrets/service_account.json');
    final jsonMap = json.decode(jsonString);

    // Scopes
    final scopes = [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/firebase.database',
      'https://www.googleapis.com/auth/firebase.messaging',
    ];

    // Get client and access token
    final credentials = ServiceAccountCredentials.fromJson(jsonMap);
    final client = await clientViaServiceAccount(credentials, scopes);
    final accessToken = client.credentials.accessToken;

    _cachedToken = accessToken.data;
    _expiryTime = accessToken.expiry;

    return _cachedToken!;
  }
}

