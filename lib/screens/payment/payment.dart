import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kwc_app/bloc.navigation_bloc/navigation_bloc.dart';
import 'package:kwc_app/models/user.dart';
import 'package:kwc_app/services/xendit_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';

enum PaymentMethod { gcash, cash }

class Payment extends StatefulWidget implements NavigationStates {
  @override
  _PaymentState createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  final XenditService _xenditService = XenditService();
  final AppLinks _appLinks = AppLinks();
  final TextEditingController _amountController = TextEditingController();

  PaymentMethod _selectedMethod = PaymentMethod.gcash;
  StreamSubscription<DatabaseEvent>? _cashPaymentStream;

  int _inserted = 0;
  int _target = 0;
  String _status = '';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        if (uri.host == 'payment-success') _handlePaymentSuccess(uri);
        if (uri.host == 'payment-failure') _handlePaymentFailure(uri);
      }
    });
  }

  void _handlePaymentSuccess(Uri uri) {
    log('Payment successful: $uri');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Payment was successful!')));
  }

  void _handlePaymentFailure(Uri uri) {
    log('Payment failed: $uri');
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed. Please try again.')));
  }

  String _generateRandomId(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = math.Random();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)])
        .join();
  }

  Future<void> _handleGCashPayment() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Enter a valid amount.')));
      return;
    }

    final amountInCents = (amount * 100).round();
    final uniqueRefId = _generateRandomId(10);

    try {
      final response =
          await _xenditService.createGCashCharge(amountInCents, uniqueRefId);
      final checkoutUrl = response['actions']['desktop_web_checkout_url'];
      final checkoutUri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(checkoutUri)) await launchUrl(checkoutUri);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      // Always reset loading state after attempt
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startCashPayment(String userId) async {
    final dbRef = FirebaseDatabase.instance.ref("cashPayments/activePayment");

    try {
      final snapshot = await dbRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map;
        final status = data['status'] ?? '';
        final activePaymentUserId = data['userId'] ?? '';
        if (status == 'pending' || status == 'in_progress') {
          if (activePaymentUserId.toString() == userId) {
            _listenToCashPayment();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('You have a cash payment in progress.')));
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'A cash payment from different user is already in progress.')));
          return;
        }
      }

      final amountText = _amountController.text.trim();
      final amount = double.tryParse(amountText);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Enter a valid amount.')));
        return;
      }

      final uniqueRefId = _generateRandomId(10);

      final payload = {
        'userId': userId,
        'amountTarget': amount.round(),
        'amountInserted': 0,
        'status': 'pending',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'referenceId': uniqueRefId,
      };

      await dbRef.set(payload);
      _listenToCashPayment();

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Cash payment started!')));
    } catch (e) {
      log('Cash start error: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _listenToCashPayment() {
    final dbRef = FirebaseDatabase.instance.ref("cashPayments/activePayment");
    _cashPaymentStream?.cancel();
    _cashPaymentStream = dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          _target = data['amountTarget'] ?? 0;
          _inserted = data['amountInserted'] ?? 0;
          _status = data['status'] ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _cashPaymentStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<Users?>(context);
    final userId = user?.uid ?? '';

    return Scaffold(
      backgroundColor: Color(0xffa7beae),
      appBar: AppBar(
        title: Text("Payment"),
        backgroundColor: Color(0xffF98866),
        elevation: 0.0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<PaymentMethod>(
                        value: PaymentMethod.gcash,
                        groupValue: _selectedMethod,
                        onChanged: (val) =>
                            setState(() => _selectedMethod = val!),
                      ),
                      Text('Pay with GCash'),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<PaymentMethod>(
                        value: PaymentMethod.cash,
                        groupValue: _selectedMethod,
                        onChanged: (val) =>
                            setState(() => _selectedMethod = val!),
                      ),
                      Text('Pay with Cash'),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  labelText: 'Enter Amount',
                  hintText: 'e.g. 100 for ₱100',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              if (_selectedMethod == PaymentMethod.gcash)
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleGCashPayment,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xffF98866)),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('Pay with GCash'),
                ),
              if (_selectedMethod == PaymentMethod.cash)
                ElevatedButton(
                  onPressed:
                      _isLoading ? null : () => _startCashPayment(userId),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xffF98866)),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('Start Cash Payment'),
                ),
              if (_status.isNotEmpty) ...[
                SizedBox(height: 20),
                Text("Cash Payment Status: $_status",
                    style: TextStyle(fontSize: 16)),
                Text("Inserted: ₱$_inserted / ₱$_target",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
