import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kwc_app/bloc.navigation_bloc/navigation_bloc.dart';
import 'package:kwc_app/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class Settings extends StatefulWidget implements NavigationStates {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newEmailController = TextEditingController();
  final AuthService _auth = AuthService();

  bool _isObscure = true; // For password visibility control
  final TextEditingController _passwordController =
      TextEditingController(); // Password reset controller

  User? _currentUser;

  @override
  void initState() {
    super.initState();
    // Fetch current user details when the page loads
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffa7beae),
      appBar: AppBar(
        title: Text("Settings"),
        backgroundColor: Color(0xffF98866),
        elevation: 0.0,
      ),
      body: SafeArea(
        child: Center(
          // Centering the entire content of the screen
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Center the Column content
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Align children centrally
                children: [
                  // Current Email Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Current Email: ${_currentUser?.email ?? "Not available"}',
                      style: GoogleFonts.radley(
                          fontSize: 16, fontWeight: FontWeight.w400),
                    ),
                  ),
                  SizedBox(height: 10),

                  // Last Password Change (approximated using lastSignInTime)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Last Password Change: ${_currentUser?.metadata.lastSignInTime?.toLocal() ?? "Not available"}',
                      style: GoogleFonts.radley(
                          fontSize: 16, fontWeight: FontWeight.w400),
                    ),
                  ),
                  SizedBox(height: 30),

                  // Email Change Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Change Email',
                      style: GoogleFonts.radley(
                          fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _newEmailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Enter new email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      String newEmail = _newEmailController.text.trim();

                      if (newEmail.isNotEmpty) {
                        try {
                          await _auth.updateEmail(
                              newEmail); // This now uses verifyBeforeUpdateEmail
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'A verification email has been sent to your new email address.')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error updating email: $e')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please enter a valid email')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xffF98866),
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    child: Text('Update Email'),
                  ),
                  SizedBox(height: 30),

                  // Password Reset Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Reset Password',
                      style: GoogleFonts.radley(
                          fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _passwordController,
                    obscureText: _isObscure,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Enter your current password',
                      prefixIcon: Icon(Icons.key),
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_isObscure
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _isObscure = !_isObscure;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      String currentPassword = _passwordController.text.trim();

                      if (currentPassword.isNotEmpty) {
                        try {
                          await _auth.resetPassword(
                              currentPassword); // Assuming resetPassword is in AuthService
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Password reset link sent!')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error resetting password: $e')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Please enter your current password')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xffF98866),
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    child: Text('Send Password Reset'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
