import 'package:flutter/material.dart';
import 'package:kwc_app/screens/authenticate/authenticate.dart';
import 'package:kwc_app/screens/home/admin_home.dart';
import 'package:kwc_app/sidebar/sidebar_layout.dart';
import 'package:provider/provider.dart';
import 'package:kwc_app/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<Users?>(context);

    if (user == null) {
      return Authenticate();
    } else {
      return FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return Text("Error fetching user data");
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          print("user role");
          print(userData['role']);
          if (userData['role'] == 'admin') {
            return AdminHome(); // Navigate to Admin Home
          } else {
            return SidebarLayout(); // Navigate to User Home
          }
        },
      );
    }
  }
}
