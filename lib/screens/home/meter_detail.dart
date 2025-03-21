import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class MeterDetails extends StatefulWidget {
  final String meterId;
  final String title;
  final bool isOnline; // Optional initial status from the parent
  final int offlineThresholdMs; // e.g. 60000 for 1 minute

  const MeterDetails({
    Key? key,
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

  // We'll track if the meter is currently considered online
  bool isOnline = false;

  // Data fields
  double voltage = 0.0;
  double current = 0.0;
  double frequency = 0.0;
  double powerFactor = 0.0;
  double activePower = 0.0;
  double reactivePower = 0.0;
  double totalEnergy = 0.0;

  // We'll store the last timestamp from the DB
  int lastTimestamp = 0;

  // DB subscription & periodic timer
  StreamSubscription<DatabaseEvent>? _dbSubscription;
  Timer? _offlineTimer;

  @override
  void initState() {
    super.initState();
    isOnline = widget.isOnline;
    _subscribeToMeterData();
    _startOfflineTimer();
  }

  void _subscribeToMeterData() {
    // Listen to the last entry from /meterData/<meterId>
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
        // No data => mark offline & reset fields
        setState(() {
          lastTimestamp = 0;
          isOnline = false;
          _resetFields();
        });
        return;
      }

      // Example data structure:
      // {
      //   "OL59TN60WzhjW9pZWbQ": {
      //     "activePower": 0,
      //     "current": 0.002,
      //     "frequency": 0,
      //     "powerFactor": 0,
      //     "reactivePower": 0,
      //     "timestamp": 1741712647687,
      //     "totalEnergy": -0.03,
      //     "voltage": 241.7
      //   }
      // }
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

      // Extract fields (cast/parse properly)
      lastTimestamp = _parseTimestamp(lastRecord['timestamp']);
      voltage = _parseDouble(lastRecord['voltage']);
      current = _parseDouble(lastRecord['current']);
      frequency = _parseDouble(lastRecord['frequency']);
      powerFactor = _parseDouble(lastRecord['powerFactor']);
      activePower = _parseDouble(lastRecord['activePower']);
      reactivePower = _parseDouble(lastRecord['reactivePower']);
      totalEnergy = _parseDouble(lastRecord['totalEnergy']);

      // Check if we're within threshold => online
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
    // Check every 5 seconds if lastTimestamp is older than threshold
    _offlineTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (!mounted) return;
      _checkOnlineStatus();
    });
  }

  /// Compare 'now - lastTimestamp' to offlineThresholdMs
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

                        // Display the fields
                        _buildDataRow("Voltage", "$voltage V"),
                        _buildDataRow("Current", "$current A"),
                        _buildDataRow("Frequency", "$frequency Hz"),
                        _buildDataRow("Power Factor", "$powerFactor"),
                        _buildDataRow("Active Power", "$activePower kW"),
                        _buildDataRow("Reactive Power", "$reactivePower kVAR"),
                        _buildDataRow("Total Energy", "$totalEnergy kWh"),

                        SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xffF98866),
                          ),
                          child: Text("Go Back"),
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
}
