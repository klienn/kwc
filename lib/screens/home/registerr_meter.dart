import 'package:flutter/material.dart';

class RegisterMeter extends StatefulWidget {
  @override
  _RegisterMeterState createState() => _RegisterMeterState();
}

class _RegisterMeterState extends State<RegisterMeter> {
  final TextEditingController _meterNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Register Meter"),
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
                TextField(
                  controller: _meterNameController,
                  decoration: InputDecoration(
                    labelText: "Meter Name",
                    hintText: "Enter Meter Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // For now, just navigate back with dummy data
                    Navigator.pop(context, {
                      'meterId': 'meter_3',
                      'title': 'Electric Meter 3',
                      'isOnline': true,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xffF98866),
                  ),
                  child: Text("Register Meter"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
