import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:kwc_app/bloc.navigation_bloc/navigation_bloc.dart';
import 'package:kwc_app/models/user.dart';
import 'package:kwc_app/screens/home/meter_tile.dart';
import 'package:kwc_app/screens/home/registerr_meter.dart';

class AdminHome extends StatelessWidget implements NavigationStates {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<Users?>(context);

    // If user is not logged in, show a basic screen
    if (user == null) {
      return Scaffold(
        backgroundColor: Color(0xffa7beae),
        appBar: AppBar(
          title: Text("Admin Dashboard"),
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
      appBar: AppBar(
        title: Text("Admin Dashboard"),
        backgroundColor: Color(0xffF98866),
        elevation: 0.0,
      ),
      body: Container(
        color: Color(0xffa7beae),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid) // The admin user's doc
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text("Error fetching data");
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Text("Admin doc not found");
                }

                // Convert the doc data to a map
                final docData = snapshot.data!.data() as Map<String, dynamic>;
                // If you want to confirm user is truly admin:
                final role = docData['role'] ?? 'user';
                if (role != 'admin') {
                  return Text("Access denied: Not an admin.");
                }

                // Extract meters array
                final meters = docData['meters'] as List<dynamic>? ?? [];
                // Prepare a list of children for GridView
                final List<Widget> gridChildren = [];

                // Create MeterTile for each meter object
                for (final m in meters) {
                  if (m is Map<String, dynamic>) {
                    final meterId = m['meterId'] ?? 'unknown';
                    final title = m['title'] ?? 'Untitled Meter';

                    gridChildren.add(
                      MeterTile(
                        adminUid: user.uid,
                        meterId: meterId,
                        title: title,
                        offlineThresholdMs: 60000,
                      ),
                    );
                  }
                }

                // Finally, add the "Add Meter" tile
                gridChildren.add(
                  GestureDetector(
                    onTap: () async {
                      final newMeter = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RegisterMeter(adminUid: user.uid),
                        ),
                      );
                      if (newMeter != null) {
                        print("New Meter Added: $newMeter");
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 5,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.add,
                          size: 50,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                );

                final kwhRate = (docData['kwhRate'] ?? 0).toDouble();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                "kWh Rate: ",
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                "₱${kwhRate.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () async {
                              final controller = TextEditingController(
                                  text: kwhRate.toString());

                              final result = await showDialog<double>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Edit kWh Rate"),
                                  content: TextField(
                                    controller: controller,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: "₱ per kWh",
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        final newRate = double.tryParse(
                                            controller.text.trim());
                                        if (newRate != null) {
                                          Navigator.pop(context, newRate);
                                        }
                                      },
                                      child: const Text("Save"),
                                    )
                                  ],
                                ),
                              );

                              if (result != null) {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .update({'kwhRate': result});
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Center(
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          shrinkWrap: true,
                          children: gridChildren,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
