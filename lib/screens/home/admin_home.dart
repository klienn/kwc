import 'package:flutter/material.dart';
import 'package:kwc_app/bloc.navigation_bloc/navigation_bloc.dart';
import 'package:kwc_app/screens/home/meter_tile.dart';
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
        color: Color(0xffa7beae),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              children: [
                MeterTile(
                  meterId: 'meterA',
                  title: 'Electric Meter 1',
                  offlineThresholdMs: 60000,
                ),
                MeterTile(
                  meterId: 'meterB',
                  title: 'Electric Meter 2',
                  offlineThresholdMs: 60000,
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
                      // Add logic if needed
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
