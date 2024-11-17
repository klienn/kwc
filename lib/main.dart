import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kwc_app/models/user.dart';
import 'package:kwc_app/screens/wrapper.dart';
import 'package:kwc_app/services/auth.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: "AIzaSyD7aoCF1RaeP-7DjR63AcGXt036g-XQ-Eo",
          appId: "1:801379391722:android:7209458576887988b39f93",
          messagingSenderId: "801379391722",
          projectId: "kwc-register-7c3e1"));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return StreamProvider<Users?>.value(
      value: AuthService().user,
      initialData: null,
      catchError: (_, error) {
        print("Stream error: $error");
        return null; // Handle stream error
      },
      child: MaterialApp(home: Wrapper()),
    );
  }
}
