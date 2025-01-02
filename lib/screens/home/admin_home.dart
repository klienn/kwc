import 'package:flutter/material.dart';
import 'package:kwc_app/bloc.navigation_bloc/navigation_bloc.dart';
import 'package:kwc_app/screens/home/meter_detail.dart';
import 'package:kwc_app/screens/home/registerr_meter.dart';

class AdminHome extends StatelessWidget implements NavigationStates {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard"),
        backgroundColor: Color(0xffF98866),
        elevation: 0.0,
      ),
      body: Container(
        color: Color(0xffa7beae), // Uniform background
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              children: [
                _buildMeterBox(
                  context: context,
                  title: "Electric Meter 1",
                  isOnline: true,
                  meterId: "meter_1",
                ),
                _buildMeterBox(
                  context: context,
                  title: "Electric Meter 2",
                  isOnline: false,
                  meterId: "meter_2",
                ),
                GestureDetector(
                  onTap: () async {
                    final newMeter = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegisterMeter(),
                      ),
                    );

                    if (newMeter != null) {
                      // Add the new meter to the list dynamically
                      print("New Meter Added: $newMeter");
                      // Handle logic to update UI or state here
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMeterBox({
    required BuildContext context,
    required String title,
    required bool isOnline,
    required String meterId,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MeterDetails(
              meterId: meterId,
              title: title,
              isOnline: isOnline,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 5,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.electrical_services,
                size: 50,
                color: isOnline ? Colors.green : Colors.red,
              ),
              SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isOnline ? Icons.circle : Icons.circle_outlined,
                    color: isOnline ? Colors.green : Colors.red,
                    size: 12,
                  ),
                  SizedBox(width: 5),
                  Text(
                    isOnline ? "Online" : "Offline",
                    style: TextStyle(
                      color: isOnline ? Colors.green : Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
