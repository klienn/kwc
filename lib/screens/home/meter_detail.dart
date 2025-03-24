import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MeterDetails extends StatefulWidget {
  final String adminUid; // UID of the admin doc in Firestore
  final String meterId; // The meter's ID
  final String title; // The meter title
  final bool isOnline; // Optional initial status
  final int offlineThresholdMs;

  const MeterDetails({
    Key? key,
    required this.adminUid,
    required this.meterId,
    required this.title,
    this.isOnline = false,
    this.offlineThresholdMs = 60000,
  }) : super(key: key);

  @override
  _MeterDetailsState createState() => _MeterDetailsState();
}

class _MeterDetailsState extends State<MeterDetails> {
  bool loading = true;
  bool error = false;
  bool isOnline = false;

  double voltage = 0.0;
  double current = 0.0;
  double frequency = 0.0;
  double powerFactor = 0.0;
  double activePower = 0.0;
  double reactivePower = 0.0;
  double totalEnergy = 0.0;

  int lastTimestamp = 0;
  StreamSubscription<DatabaseEvent>? _dbSubscription;
  Timer? _offlineTimer;

  // For showing any Firestore error messages during deletion
  String? _deleteError;

  @override
  void initState() {
    super.initState();
    isOnline = widget.isOnline;
    _subscribeToMeterData();
    _startOfflineTimer();
  }

  void _subscribeToMeterData() {
    final query = FirebaseDatabase.instance
        .ref('meterData/${widget.meterId}')
        .limitToLast(1);

    _dbSubscription = query.onValue.listen((event) {
      setState(() {
        loading = false;
        error = false;
      });

      final dataSnapshot = event.snapshot.value;
      if (dataSnapshot == null) {
        setState(() {
          lastTimestamp = 0;
          isOnline = false;
          _resetFields();
        });
        return;
      }

      final dataMap = dataSnapshot as Map<Object?, Object?>;
      final lastKey = dataMap.keys.first;
      final lastRecord = dataMap[lastKey] as Map<Object?, Object?>?;

      if (lastRecord == null) {
        setState(() {
          lastTimestamp = 0;
          isOnline = false;
          _resetFields();
        });
        return;
      }

      lastTimestamp = _parseTimestamp(lastRecord['timestamp']);
      voltage = _parseDouble(lastRecord['voltage']);
      current = _parseDouble(lastRecord['current']);
      frequency = _parseDouble(lastRecord['frequency']);
      powerFactor = _parseDouble(lastRecord['powerFactor']);
      activePower = _parseDouble(lastRecord['activePower']);
      reactivePower = _parseDouble(lastRecord['reactivePower']);
      totalEnergy = _parseDouble(lastRecord['totalEnergy']);

      _checkOnlineStatus();
    }, onError: (e) {
      setState(() {
        loading = false;
        error = true;
        isOnline = false;
      });
    });
  }

  void _startOfflineTimer() {
    _offlineTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (!mounted) return;
      _checkOnlineStatus();
    });
  }

  void _checkOnlineStatus() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final diff = nowMs - lastTimestamp;
    final newStatus = diff < widget.offlineThresholdMs;
    if (newStatus != isOnline) {
      setState(() {
        isOnline = newStatus;
      });
    }
  }

  int _parseTimestamp(dynamic val) {
    if (val is int) return val;
    if (val is String) {
      return int.tryParse(val) ?? 0;
    }
    return 0;
  }

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      return double.tryParse(val) ?? 0.0;
    }
    return 0.0;
  }

  void _resetFields() {
    voltage = 0.0;
    current = 0.0;
    frequency = 0.0;
    powerFactor = 0.0;
    activePower = 0.0;
    reactivePower = 0.0;
    totalEnergy = 0.0;
  }

  @override
  void dispose() {
    _dbSubscription?.cancel();
    _offlineTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = error
        ? Colors.orange
        : (loading ? Colors.grey : (isOnline ? Colors.green : Colors.red));
    final statusText = error
        ? "Error"
        : (loading ? "Loading..." : (isOnline ? "Online" : "Offline"));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Color(0xffF98866),
        elevation: 0.0,
      ),
      body: Container(
        color: Color(0xffa7beae),
        width: double.infinity,
        height: double.infinity,
        child: loading
            ? _buildCenterMessage("Loading meter data...")
            : error
                ? _buildCenterMessage("Error reading data")
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.electrical_services,
                          size: 100,
                          color: iconColor,
                        ),
                        SizedBox(height: 20),
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Status: $statusText",
                          style: TextStyle(
                            fontSize: 18,
                            color: iconColor,
                          ),
                        ),
                        SizedBox(height: 30),
                        _buildDataRow("Voltage", "$voltage V"),
                        _buildDataRow("Current", "$current A"),
                        _buildDataRow("Frequency", "$frequency Hz"),
                        _buildDataRow("Power Factor", "$powerFactor"),
                        _buildDataRow("Active Power", "$activePower kW"),
                        _buildDataRow("Reactive Power", "$reactivePower kVAR"),
                        _buildDataRow("Total Energy", "$totalEnergy kWh"),
                        if (_deleteError != null) ...[
                          SizedBox(height: 20),
                          Text(
                            _deleteError!,
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                        SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xffF98866),
                          ),
                          child: Text("Go Back"),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _deleteMeter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                          child: Text("Delete Meter"),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildCenterMessage(String msg) {
    return Center(
      child: Text(
        msg,
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "$label:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Text(value, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  /// Remove this meter from admin's meters[] array in Firestore
  Future<void> _deleteMeter() async {
    try {
      // Retrieve the doc for adminUid
      final adminDocRef = FirebaseDatabase.instance.app ==
              null // Not relevant for Firestore, but we can do:
          ? throw Exception(
              "No Firestore initialization found") // or handle differently
          : FirebaseFirestore.instance.collection('users').doc(widget.adminUid);

      final docSnap = await adminDocRef.get();
      if (!docSnap.exists) {
        setState(() => _deleteError = "Admin doc not found.");
        return;
      }

      final data = docSnap.data() as Map<String, dynamic>;
      final meters = (data['meters'] as List<dynamic>?) ?? [];

      // Find the meter object with this meterId
      final index = meters.indexWhere(
          (m) => m is Map<String, dynamic> && m['meterId'] == widget.meterId);
      if (index == -1) {
        setState(() => _deleteError = "Meter ID not found in admin doc.");
        return;
      }

      // Remove the meter object
      meters.removeAt(index);

      // Update the doc
      await adminDocRef.update({'meters': meters});

      // Return to previous screen
      Navigator.pop(context);
    } catch (e) {
      setState(() => _deleteError = "Error deleting meter: $e");
    }
  }
}
