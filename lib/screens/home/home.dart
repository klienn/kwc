import 'package:flutter/material.dart';
import 'package:kwc_app/bloc.navigation_bloc/navigation_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:kwc_app/models/user.dart';

const Map<String, String> meterToRoomCode = {
  'meterA': 'Room A',
  'meterB': 'Room B',
  'meterC': 'Room C',
  'meterD': 'Room D',
};

class Home extends StatelessWidget implements NavigationStates {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<Users?>(context);

    // Check if user is logged in
    if (user == null) {
      return Scaffold(
        backgroundColor: Color(0xffa7beae),
        appBar: AppBar(
          title: Image.asset("images/Logo B.png"),
          backgroundColor: Color(0xffF98866),
          elevation: 0.0,
        ),
        body: Center(
          child: Text(
            "User not logged in.",
            style: TextStyle(fontSize: 18, color: Colors.black),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xffa7beae),
      appBar: AppBar(
        title: Image.asset("images/Logo B.png"),
        backgroundColor: Color(0xffF98866),
        elevation: 0.0,
      ),
      body: Center(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid) // Use the authenticated user's UID
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }

            if (snapshot.hasError) {
              return Text("Error fetching data");
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Text("User data not found");
            }

            var userData = snapshot.data!.data() as Map<String, dynamic>;
            var balance = userData['balance'] ?? 0;
            var room = meterToRoomCode[userData['meterName']];

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome to Kilowatt Connect',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Text(
                  'Your Balance: ₱${balance.toString()}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 5),
                Text(
                  'Room: $room',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
