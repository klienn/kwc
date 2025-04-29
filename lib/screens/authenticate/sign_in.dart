import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kwc_app/screens/authenticate/emailpage.dart';
import 'package:kwc_app/services/auth.dart';
import 'package:kwc_app/screens/authenticate/register.dart';
import 'package:kwc_app/sidebar/sidebar_layout.dart'; // Import SidebarLayout

class SignIn extends StatefulWidget {
  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final AuthService _auth = AuthService();

  // Check if user is logged in
  void _checkUserLoggedIn() async {
    var user = await _auth.user.first; // Stream from AuthService
    print({'user logged-in:', user?.uid});
    if (user != null) {
      // If user is already logged in, navigate to SidebarLayout
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => SidebarLayout()), // Navigate to SidebarLayout
      );
    }
    // else {
    //   // If no user is logged in, attempt to automatically sign in using Google
    //   _signInWithGoogle();
    // }
  }

  // Automatically sign in with Google
  void _signInWithGoogle() async {
    try {
      User? user = await _auth.signInWithGoogle();
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  SidebarLayout()), // Navigate to SidebarLayout
        );
      } else {
        print('Google Sign-In failed');
      }
    } catch (e) {
      print('Error during Google Sign-In: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _checkUserLoggedIn(); // Check user session on start
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffa7beae),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 30.0), // Add top padding
              child: Image.asset(
                'images/Logo D.png',
                height: MediaQuery.of(context).size.height * 0.3,
                fit: BoxFit
                    .contain, // Ensures the image is contained within the given height
              ),
            ),
            SizedBox(height: 10),
            Container(
              child: Text(
                "Welcome to KiloWatt Connect",
                textAlign: TextAlign.center,
                style: GoogleFonts.montserratAlternates(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(height: 60),
            // Sign In Anonymously
            // Container(
            //   child: ElevatedButton(
            //     onPressed: () async {
            //       dynamic result = await _auth.signInAnon();
            //       if (result == null) {
            //         print('Error signing in');
            //       } else {
            //         print('Signed in');
            //         Navigator.pushReplacement(
            //           context,
            //           MaterialPageRoute(
            //               builder: (context) =>
            //                   SidebarLayout()), // Navigate to SidebarLayout
            //         );
            //       }
            //     },
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Color(0xffF98866), // Button background color
            //       foregroundColor: Colors.white, // Text color
            //       padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            //       textStyle: GoogleFonts.publicSans(
            //           fontSize: 20, fontWeight: FontWeight.w900),
            //     ),
            //     child: Text('Sign In Anon'),
            //   ),
            // ),
            SizedBox(height: 10),
            // Sign In with Email
            Container(
              padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Emailpage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xffF98866), // Button background color
                  foregroundColor: Colors.white, // Text color
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: GoogleFonts.publicSans(
                      fontSize: 20, fontWeight: FontWeight.w900),
                ),
                child: Text('Sign In with Email'),
              ),
            ),
            // Sign In with Google
            // Container(
            //   padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
            //   child: ElevatedButton(
            //     onPressed:
            //         _signInWithGoogle, // Automatically sign in with Google
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Color(0xffF98866), // Button background color
            //       foregroundColor: Colors.white, // Text color
            //       padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            //       textStyle: GoogleFonts.publicSans(
            //           fontSize: 20, fontWeight: FontWeight.w900),
            //     ),
            //     child: Text('Sign In with Google'),
            //   ),
            // ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Do not have an account?",
                  style: GoogleFonts.radley(
                      fontSize: 16, fontWeight: FontWeight.w100),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RegisterPage(), // Navigate to RegisterPage
                      ),
                    );
                  },
                  child: Text(
                    "Register",
                    style: GoogleFonts.radley(
                      fontSize: 16,
                      fontWeight: FontWeight.w100,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
