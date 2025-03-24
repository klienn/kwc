import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kwc_app/bloc.navigation_bloc/navigation_bloc.dart';
import 'package:kwc_app/services/xendit_service.dart';
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

  // Text controller for amount input
  final TextEditingController _amountController = TextEditingController();

  PaymentMethod _selectedMethod = PaymentMethod.gcash;

  @override
  void initState() {
    super.initState();

    // Listen for deep links (payment success/failure)
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        if (uri.host == 'payment-success') {
          _handlePaymentSuccess(uri);
        } else if (uri.host == 'payment-failure') {
          _handlePaymentFailure(uri);
        }
      }
    });
  }

  // Handle the payment success
  void _handlePaymentSuccess(Uri uri) {
    log('Payment successful: $uri');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment was successful!')),
    );
  }

  // Handle the payment failure
  void _handlePaymentFailure(Uri uri) {
    log('Payment failed: $uri');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed. Please try again.')),
    );
  }

  /// Generates a random string ID for payment reference
  String _generateRandomId(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = math.Random();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)])
        .join();
  }

  // Initiates GCash payment
  Future<void> _handleGCashPayment(BuildContext context) async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter an amount.')),
      );
      return;
    }

    final parsedAmount = double.tryParse(amountText) ?? 0.0;
    if (parsedAmount <= 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a positive amount.')),
      );
      return;
    }

    // Convert to cents
    final int amountInCents = (parsedAmount * 100).round();

    // Generate a unique reference ID
    final String uniqueRefId = _generateRandomId(10);

    try {
      final response = await _xenditService.createGCashCharge(
        amountInCents,
        uniqueRefId, // e.g. "some-random-id-XYZ"
      );

      // Retrieve the GCash payment URL
      final checkoutUrl = response['actions']['desktop_web_checkout_url'];
      log(checkoutUrl);

      final Uri checkoutUri = Uri.parse(checkoutUrl);

      if (await canLaunchUrl(checkoutUri)) {
        await launchUrl(checkoutUri);
      } else {
        throw 'Could not launch GCash payment URL';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffa7beae),
      appBar: AppBar(
        title: const Text("Payment"),
        backgroundColor: const Color(0xffF98866),
        elevation: 0.0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔘 Payment method selection
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Radio<PaymentMethod>(
                    value: PaymentMethod.gcash,
                    groupValue: _selectedMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedMethod = value!;
                      });
                    },
                  ),
                  const Text('Pay with GCash'),
                  SizedBox(width: 20),
                  Radio<PaymentMethod>(
                    value: PaymentMethod.cash,
                    groupValue: _selectedMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedMethod = value!;
                      });
                    },
                  ),
                  const Text('Pay with Cash'),
                ],
              ),
              const SizedBox(height: 20),

              // 💸 Only show if GCash is selected
              if (_selectedMethod == PaymentMethod.gcash) ...[
                TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Enter Amount',
                    hintText: 'e.g. 100 for ₱100',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _handleGCashPayment(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffF98866),
                  ),
                  child: const Text('Pay with GCash'),
                ),
              ],

              if (_selectedMethod == PaymentMethod.cash)
                const Text(
                  "Cash payment selected. No further action needed.",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
