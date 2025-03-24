import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterMeter extends StatefulWidget {
  final String adminUid; // We pass the user.uid from AdminHome

  const RegisterMeter({Key? key, required this.adminUid}) : super(key: key);

  @override
  _RegisterMeterState createState() => _RegisterMeterState();
}

class _RegisterMeterState extends State<RegisterMeter> {
  final TextEditingController _meterIdController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  String? _errorMessage;

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 20),
                ],
                TextField(
                  controller: _meterIdController,
                  decoration: InputDecoration(
                    labelText: "Meter ID",
                    hintText: "e.g. meterC",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: "Title",
                    hintText: "e.g. Electric Meter 3",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _addMeter,
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

  Future<void> _addMeter() async {
    final meterId = _meterIdController.text.trim();
    final title = _titleController.text.trim();
    if (meterId.isEmpty || title.isEmpty) {
      setState(() => _errorMessage = "Please fill in all fields.");
      return;
    }

    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(widget.adminUid);

    try {
      // 1. Get the current 'meters' array
      final docSnap = await userDocRef.get();
      if (!docSnap.exists) {
        setState(() => _errorMessage = "Admin doc not found.");
        return;
      }

      final data = docSnap.data() as Map<String, dynamic>;
      final meters = (data['meters'] as List<dynamic>?) ?? [];

      // 2. Check if meterId is already used
      final alreadyExists = meters
          .any((m) => (m is Map<String, dynamic>) && (m['meterId'] == meterId));
      if (alreadyExists) {
        setState(() => _errorMessage = "Meter ID '$meterId' already exists.");
        return;
      }

      // 3. Add new meter object
      final newMeter = {
        'meterId': meterId,
        'title': title,
      };
      meters.add(newMeter);

      // 4. Update the doc with the new array
      await userDocRef.update({'meters': meters});

      // Return to AdminHome
      Navigator.pop(context, newMeter);
    } catch (e) {
      setState(() => _errorMessage = "Error adding meter: $e");
    }
  }
}
