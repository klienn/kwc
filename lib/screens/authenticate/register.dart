import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kwc_app/services/auth.dart';
import 'package:kwc_app/sidebar/sidebar_layout.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService _auth = AuthService(); // Instance of AuthService
  final _formKey = GlobalKey<FormState>(); // Form key for validation

  // Controllers to get email and password inputs
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isObscure = true; // To control password visibility

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
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Form(
            key: _formKey, // Using form for validation
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
                  'Email',
                  style: GoogleFonts.radley(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 25),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                ),
                SizedBox(height: 30),
                Text(
                  'Password',
                  style: GoogleFonts.radley(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 25),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isObscure, // Control visibility of the text
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    hintText: 'Enter your password',
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                    ),
                  ),
                  validator: (val) =>
                      val!.length < 6 ? 'Enter a password 6+ chars long' : null,
                ),
                SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        String email = _emailController.text.trim();
                        String password = _passwordController.text.trim();

                        // Call register function
                        dynamic result = await _auth
                            .registerWithEmailAndPassword(email, password);
                        if (result == null) {
                          // If registration fails, show error
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error registering account'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else {
                          // Registration successful, show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Registration successful!'),
                              backgroundColor: Colors.green,
                            ),
                          );

                          // Navigate to SidebarLayout after successful registration
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SidebarLayout(),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xffF98866),
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      textStyle: GoogleFonts.publicSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text('Register'),
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
