import 'package:flutter/material.dart';
import 'package:kwc_app/screens/authenticate/authenticate.dart';
import 'package:kwc_app/sidebar/sidebar_layout.dart';
import 'package:provider/provider.dart';
import 'package:kwc_app/models/user.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<Users?>(context);

    if (user == null) {
      return Authenticate();
    } else {
      return SidebarLayout(); // Navigate to Admin Home
    }
  }
}
