import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kwc_app/services/auth.dart';
import 'package:kwc_app/sidebar/sidebar_layout.dart'; // Import SidebarLayout

class Emailpage extends StatefulWidget {
  @override
  _EmailpageState createState() => _EmailpageState();
}

class _EmailpageState extends State<Emailpage> {
  // Variables to control password visibility and remember me checkbox
  bool _isObscure = true;
  bool _rememberMe = false;

  // Controllers for capturing input
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _auth = AuthService(); // Create an instance of AuthService

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffa7beae),
      appBar: AppBar(
        backgroundColor: Color(0xffF98866),
        elevation: 0.0,
        centerTitle: true,
        title: Image.asset("images/Logo B.png"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  alignment: Alignment.center,
                  child: Image.asset(
                    "images/Logo D.png",
                    fit: BoxFit.cover,
                    height: 230,
                    width: 200,
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  'Username',
                  style: GoogleFonts.radley(
                      fontSize: 20, fontWeight: FontWeight.w400),
                ),
                SizedBox(height: 25),
                TextField(
                  controller: _emailController, // Email controller
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    hintText: 'Enter a username (email)',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  'Password',
                  style: GoogleFonts.radley(
                      fontSize: 20, fontWeight: FontWeight.w400),
                ),
                SizedBox(height: 25),
                TextField(
                  controller: _passwordController, // Password controller
                  obscureText: _isObscure, // Control visibility of the text
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    hintText: 'Enter a password',
                    prefixIcon: Icon(Icons.key),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        // Toggle password visibility
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value!;
                            });
                          },
                        ),
                        Text(
                          'Remember Me',
                          style: GoogleFonts.radley(
                              fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        // Implement forgot password functionality here
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xffF98866),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Capture email and password
                      String email = _emailController.text.trim();
                      String password = _passwordController.text.trim();

                      // Attempt to sign in using AuthService
                      dynamic result = await _auth.signInWithEmailAndPassword(
                          email, password);

                      if (result == null) {
                        // Display error if sign-in failed
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Error signing in with email and password'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else {
                        // Successful sign-in
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Successfully signed in'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // Navigate to SidebarLayout after successful sign-in
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SidebarLayout()),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Color(0xffF98866), // Button background color
                      foregroundColor: Colors.white, // Text color
                      padding:
                          EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      textStyle: GoogleFonts.publicSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text('Sign In'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
