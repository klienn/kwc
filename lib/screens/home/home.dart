import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kwc_app/bloc.navigation_bloc/navigation_bloc.dart';
import 'package:kwc_app/models/user.dart';
import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const Map<String, String> meterToRoomCode = {
  'meterA': 'Room A',
  'meterB': 'Room B',
  'meterC': 'Room C',
  'meterD': 'Room D',
};

class Home extends StatefulWidget implements NavigationStates {
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    // _initNotification();
  }

  // Future<void> _initNotification() async {
  //   flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  //   const AndroidInitializationSettings initializationSettingsAndroid =
  //       AndroidInitializationSettings('@mipmap/ic_launcher');

  //   const InitializationSettings initializationSettings =
  //       InitializationSettings(
  //     android: initializationSettingsAndroid,
  //   );

  //   await flutterLocalNotificationsPlugin!.initialize(initializationSettings);
  // }

  // Future<void> _sendLowBalanceNotification() async {
  //   const AndroidNotificationDetails androidDetails =
  //       AndroidNotificationDetails(
  //     'low_balance_channel',
  //     'Low Balance Alerts',
  //     channelDescription: 'Notify user when balance is below ₱100',
  //     importance: Importance.max,
  //     priority: Priority.high,
  //   );

  //   const NotificationDetails notificationDetails =
  //       NotificationDetails(android: androidDetails);

  //   await flutterLocalNotificationsPlugin!.show(
  //     0,
  //     'Low Balance Alert',
  //     'Your balance is below ₱100. Please top up.',
  //     notificationDetails,
  //   );
  // }

  // Future<void> _checkAndNotifyLowBalance(num balance) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final alreadyNotified = prefs.getBool('low_balance_notified') ?? false;

  //   if (balance < 100 && !alreadyNotified) {
  //     await _sendLowBalanceNotification();
  //     await prefs.setBool('low_balance_notified', true);
  //   } else if (balance >= 100 && alreadyNotified) {
  //     // Reset flag when balance goes above 100
  //     await prefs.setBool('low_balance_notified', false);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<Users?>(context);

    if (user == null) {
      return _scaffoldWithMessage("User not logged in.");
    }

    return Scaffold(
      backgroundColor: const Color(0xffa7beae),
      appBar: AppBar(
        title: Image.asset("images/Logo B.png"),
        backgroundColor: const Color(0xffF98866),
        elevation: 0.0,
      ),
      body: Center(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (snapshot.hasError) {
              return _scaffoldWithMessage("Error fetching data");
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return _scaffoldWithMessage("User data not found");
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final balance = userData['balance'] ?? 0;
            final room = meterToRoomCode[userData['meterName']] ?? "Unknown";

            // _checkAndNotifyLowBalance(balance);

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome to Kilowatt Connect',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  'Your Balance: ₱${balance.toString()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 5),
                Text(
                  'Room: $room',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w500),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _scaffoldWithMessage(String msg) {
    return Scaffold(
      backgroundColor: const Color(0xffa7beae),
      appBar: AppBar(
        title: Image.asset("images/Logo B.png"),
        backgroundColor: const Color(0xffF98866),
        elevation: 0.0,
      ),
      body: Center(child: Text(msg, style: const TextStyle(fontSize: 18))),
    );
  }
}
