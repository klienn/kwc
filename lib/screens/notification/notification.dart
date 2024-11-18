import 'package:flutter/material.dart';
import 'package:kwc_app/bloc.navigation_bloc/navigation_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:kwc_app/models/user.dart';

class Notifications extends StatelessWidget implements NavigationStates {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<Users?>(context);

    // Check if user is logged in
    if (user == null) {
      return Scaffold(
        backgroundColor: Color(0xffa7beae),
        appBar: AppBar(
          title: Text("Notification"),
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
        title: Text("Notification"),
        backgroundColor: Color(0xffF98866),
        elevation: 0.0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          return Future.delayed(Duration(seconds: 1));
        },
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Error fetching messages"));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text("No notifications available"));
            }

            var messages = snapshot.data!.docs;

            return ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                var messageData =
                    messages[index].data() as Map<String, dynamic>;
                String title = messageData['title'] ?? 'No Title';
                String message = messageData['message'] ?? 'No Message';
                bool read = messageData['read'] ?? false;
                String referenceId =
                    messageData['referenceId'] ?? 'No Reference ID';
                String messageId = messages[index].id;

                return GestureDetector(
                  onTap: () async {
                    // Mark the message as read
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('messages')
                        .doc(messageId)
                        .update({'read': true});

                    // Display the message details directly within the Notifications page
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Color(0xffa7beae),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20.0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
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
                                    read
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
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
                        );
                      },
                    );
                  },
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    color: read ? Colors.grey[300] : Colors.white,
                    child: ListTile(
                      leading: Icon(
                        read ? Icons.notifications : Icons.notifications_active,
                        color: read ? Colors.grey : Colors.orange,
                      ),
                      title: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: read ? Colors.black54 : Colors.black,
                        ),
                      ),
                      subtitle: Text(message),
                      trailing: Icon(
                        read
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: read ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
