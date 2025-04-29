import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kwc_app/models/user.dart';
import 'package:kwc_app/screens/wrapper.dart';
import 'package:kwc_app/services/auth.dart';
import 'package:provider/provider.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyD7aoCF1RaeP-7DjR63AcGXt036g-XQ-Eo",
      appId: "1:801379391722:android:7209458576887988b39f93",
      messagingSenderId: "801379391722",
      projectId: "kwc-register-7c3e1",
    ),
  );

  await _setupFirebaseMessaging();

  runApp(const MyApp());
}

/// 🔔 Setup Firebase Messaging for foreground and background
Future<void> _setupFirebaseMessaging() async {
  // Local notifications init
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Ask user for notification permission
  await FirebaseMessaging.instance.requestPermission();

  // Background messages
  FirebaseMessaging.onBackgroundMessage(_handleFirebaseMessage);

  // Foreground messages
  FirebaseMessaging.onMessage.listen(_handleFirebaseMessage);
}

/// 🔔 Universal notification handler
Future<void> _handleFirebaseMessage(RemoteMessage message) async {
  print('📨 Firebase message received: ${message.notification?.title}');

  final notification = message.notification;
  if (notification == null) return;

  await flutterLocalNotificationsPlugin.show(
    notification.hashCode,
    notification.title,
    notification.body,
    NotificationDetails(
        android: AndroidNotificationDetails(
      'low_balance_channel',
      'Low Balance Alerts',
      channelDescription: 'Notify user when balance is below ₱100',
      importance: Importance.max,
      priority: Priority.high,
    )),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamProvider<Users?>.value(
      value: AuthService().user,
      initialData: null,
      catchError: (_, error) {
        print("Stream error: $error");
        return null;
      },
      child: MaterialApp(
        home: Wrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
