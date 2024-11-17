import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kwc_app/bloc.navigation_bloc/navigation_bloc.dart';
import 'package:kwc_app/screens/wrapper.dart';
import 'package:kwc_app/services/auth.dart';

class Logout extends StatelessWidget implements NavigationStates {
  final AuthService auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffa7beae), // Set the background color
      appBar: AppBar(
        title: Text(
          "Logout",
          style: GoogleFonts.radley(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xffF98866),
        centerTitle: true,
        elevation: 0.0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Start alignment
          crossAxisAlignment: CrossAxisAlignment.center, // Center alignment
          children: [
            // Adjusting the logo image at the top center
            Padding(
              padding: const EdgeInsets.only(top: 40.0), // Add top padding
              child: Image.asset(
                'images/Logo D.png',
                height: 300,
                fit: BoxFit
                    .contain, // Ensures the image is contained within the given height
              ),
            ),
            SizedBox(height: 20), // Space between logo and GIF
            // Adjusting the GIF
            Image.asset(
              'images/bye.gif', // Path to your GIF
              height: 200, // Set height as needed
              width: 200, // Set width as needed
              fit: BoxFit.contain, // Ensures the GIF covers the area
            ),
            SizedBox(height: 20), // Space between GIF and button
            ElevatedButton(
              onPressed: () {
                _showLogoutDialog(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xffF98866), // Button background color
                foregroundColor: Colors.white, // Text color
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: TextStyle(fontSize: 20),
              ),
              child: Text("Log Out"),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Logout"),
          content: Text("Are you sure you want to logout?"),
          actions: <Widget>[
            TextButton(
              child: Text("Yes"),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog

                // Make sure the widget context is still valid before performing navigation
                if (context.mounted) {
                  // Use post-frame callback to ensure safe navigation
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    // Handle logout logic here, e.g., signing out
                    await auth.signOut();

                    // Use Navigator.pushReplacement to replace the current screen and clear the navigation stack
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => Wrapper()),
                      (route) => false, // Removes all previous routes
                    );
                  });
                }
              },
            ),
            TextButton(
              child: Text("No"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
}
