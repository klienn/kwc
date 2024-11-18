import 'package:flutter/material.dart';
import 'package:kwc_app/bloc.navigation_bloc/navigation_bloc.dart';

class MessageDetails extends StatelessWidget implements NavigationStates {
  final String title;
  final String message;
  final String referenceId;
  final bool read;

  MessageDetails({
    required this.title,
    required this.message,
    required this.referenceId,
    required this.read,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffa7beae),
      appBar: AppBar(
        title: Text("Message Details"),
        backgroundColor: Color(0xffF98866),
        elevation: 0.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              "Reference ID: $referenceId",
              style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.black54),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  read ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: read ? Colors.green : Colors.red,
                ),
                SizedBox(width: 10),
                Text(
                  read ? "Message Read" : "Message Unread",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: read ? Colors.green : Colors.red,
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
