import 'package:flutter/material.dart';

class MeterDetails extends StatelessWidget {
  final String meterId;
  final String title;
  final bool isOnline;

  const MeterDetails({
    Key? key,
    required this.meterId,
    required this.title,
    required this.isOnline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Color(0xffF98866),
        elevation: 0.0,
      ),
      body: Container(
        color: Color(0xffa7beae),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.electrical_services,
                  size: 100,
                  color: isOnline ? Colors.green : Colors.red,
                ),
                SizedBox(height: 20),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Status: ${isOnline ? 'Online' : 'Offline'}",
                  style: TextStyle(
                    fontSize: 18,
                    color: isOnline ? Colors.green : Colors.red,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Meter ID: $meterId",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xffF98866),
                  ),
                  child: Text("Go Back"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
