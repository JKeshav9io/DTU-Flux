import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'data_populator.dart';
import 'firebase_options.dart';
import 'notification_services.dart';
import 'splash_screen.dart';
import 'theme.dart'; 

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print(message.notification?.title);
  print(message.notification?.body);
  print("Handling a background message: ${message.messageId}");
  print(message.data);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase Initialization
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Firestore Persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    //cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Supabase Initialization
  await Supabase.initialize(
    url: "https://hzsljsjkbfzofsacrvvj.supabase.co",
    anonKey:
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh6c2xqc2prYmZ6b2ZzYWNydnZqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc3NjI1ODAsImV4cCI6MjA2MzMzODU4MH0.P5g_CGhlxPtoJrcpR6SjkQ_GL_3VkVjGIQjxYqj37r4",
  );

  // Hive Initialization
  await Hive.initFlutter();
  await Hive.openBox('cache');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    final notificationServices = NotificationServices();
    notificationServices.requestNotificationPermissions();
    notificationServices.getToken();
    notificationServices.firebaseinit(context);
    notificationServices.setupInteractMessage();
    FirebaseMessaging.instance.subscribeToTopic('2024_MCE_B05');
    return MaterialApp(
      navigatorKey: notificationServices.navigatorKey,
      title: 'DTU Connect',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.light,           // light theme
      darkTheme: AppThemes.dark,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
