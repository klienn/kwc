import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:kwc_app/screens/home/meter_detail.dart';

class MeterTile extends StatefulWidget {
  final String adminUid;
  final String meterId;
  final String title;
  final int offlineThresholdMs; // e.g. 60000 for 1 minute

  const MeterTile({
    Key? key,
    required this.adminUid,
    required this.meterId,
    required this.title,
    this.offlineThresholdMs = 60000,
  }) : super(key: key);

  @override
  _MeterTileState createState() => _MeterTileState();
}

class _MeterTileState extends State<MeterTile> {
  bool loading = true;
  bool error = false;
  bool isOnline = false;

  int lastTimestamp = 0; // The last timestamp from the DB
  StreamSubscription<DatabaseEvent>? _dbSubscription;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();

    // 1. Subscribe to the last record of /meterData/<meterId>
    final query = FirebaseDatabase.instance
        .ref('meterData/${widget.meterId}')
        .limitToLast(1);

    // Listen for updates
    _dbSubscription = query.onValue.listen((event) {
      setState(() {
        loading = false;
        error = false;
      });

      final dataSnapshot = event.snapshot.value;
      if (dataSnapshot == null) {
        // No data for this meter
        setState(() {
          isOnline = false;
          lastTimestamp = 0;
        });
        return;
      }

      // dataSnapshot might be like: { pushKeyXYZ: { timestamp: ..., ... } }
      final map = dataSnapshot as Map<Object?, Object?>;
      final lastKey = map.keys.first;
      final lastRecord = map[lastKey] as Map<Object?, Object?>?;

      if (lastRecord == null) {
        setState(() {
          isOnline = false;
          lastTimestamp = 0;
        });
        return;
      }

      // Parse the meter's timestamp from DB
      final timestampRaw = lastRecord['timestamp'];
      final parsedTs = _parseTimestamp(timestampRaw);
      setState(() {
        lastTimestamp = parsedTs;
      });

      // Immediately check online status
      _checkOnlineStatus();
    }, onError: (e) {
      setState(() {
        loading = false;
        error = true;
        isOnline = false;
      });
    });

    // 2. Periodically check if the meter has gone offline
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return; // if widget disposed, skip
      _checkOnlineStatus();
    });
  }

  @override
  void dispose() {
    _dbSubscription?.cancel();
    _checkTimer?.cancel();
    super.dispose();
  }

  /// If too long has passed since lastTimestamp, mark offline
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

  /// Convert dynamic to int
  int _parseTimestamp(dynamic ts) {
    if (ts is int) return ts;
    if (ts is String) {
      return int.tryParse(ts) ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = error
        ? Colors.orange
        : (loading ? Colors.grey : (isOnline ? Colors.green : Colors.red));
    final statusText = error
        ? "Error"
        : (loading ? "Loading..." : (isOnline ? "Online" : "Offline"));

    return GestureDetector(
      onTap: () {
        if (!loading && !error) {
          // Navigate to MeterDetails page. You can pass isOnline here if you want
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MeterDetails(
                adminUid: widget.adminUid,
                meterId: widget.meterId,
                title: widget.title,
                isOnline: isOnline,
              ),
            ),
          );
        }
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
                color: iconColor,
              ),
              SizedBox(height: 10),
              Text(
                widget.title,
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
                    error
                        ? Icons.warning
                        : (loading
                            ? Icons.hourglass_empty
                            : (isOnline
                                ? Icons.circle
                                : Icons.circle_outlined)),
                    color: iconColor,
                    size: 12,
                  ),
                  SizedBox(width: 5),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: iconColor,
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
