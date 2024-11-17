import 'package:flutter/material.dart';
import 'package:kwc_app/bloc.navigation_bloc/navigation_bloc.dart';

class Notifications extends StatelessWidget implements NavigationStates {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffa7beae),
      appBar: AppBar(
        title: Text("Notification"),
        backgroundColor: Color(0xffF98866),
        elevation: 0.0,
      ),
    );
  }
}
