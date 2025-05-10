import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kwc_app/screens/authenticate/emailpage.dart';
import 'package:kwc_app/screens/authenticate/register.dart';
import 'package:kwc_app/screens/wrapper.dart'; // ✅ use Wrapper
import 'package:kwc_app/services/auth.dart';

class SignIn extends StatefulWidget {
  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final AuthService _auth = AuthService();

  void _checkUserLoggedIn() async {
    var user = await _auth.user.first;
    if (user != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Wrapper()),
        (route) => false,
      );
    }
  }

  void _signInWithGoogle() async {
    try {
      User? user = await _auth.signInWithGoogle();
      if (user != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Wrapper()),
          (route) => false,
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
    _checkUserLoggedIn();
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
              padding: const EdgeInsets.only(top: 30.0),
              child: Image.asset(
                'images/Logo D.png',
                height: MediaQuery.of(context).size.height * 0.3,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Welcome to KiloWatt Connect",
              textAlign: TextAlign.center,
              style: GoogleFonts.montserratAlternates(
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 60),
            // Sign In with Email
            Padding(
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
                  backgroundColor: Color(0xffF98866),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: GoogleFonts.publicSans(
                      fontSize: 20, fontWeight: FontWeight.w900),
                ),
                child: Text('Sign In with Email'),
              ),
            ),
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
                      MaterialPageRoute(builder: (context) => RegisterPage()),
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
