import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:kwc_app/bloc.navigation_bloc/navigation_bloc.dart';
import 'package:kwc_app/services/xendit_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart'; // Import app_links package

class Payment extends StatefulWidget implements NavigationStates {
  @override
  _PaymentState createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  final XenditService _xenditService = XenditService();
  final AppLinks _appLinks = AppLinks(); // Create an instance of AppLinks

  @override
  void initState() {
    super.initState();

    // Listen for incoming deep links (payment success or failure)
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        // Handle the deep link based on the host (payment-success or payment-failure)
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
    // You can show a success message or navigate to a success page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment was successful!')),
    );
  }

  // Handle the payment failure
  void _handlePaymentFailure(Uri uri) {
    log('Payment failed: $uri');
    // Show a failure message or navigate to a failure page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed. Please try again.')),
    );
  }

  Future<void> _handleGCashPayment(BuildContext context) async {
    try {
      // Create a GCash charge (500 PHP in cents, with a unique reference ID)
      final response =
          await _xenditService.createGCashCharge(50000, 'your-unique-id-123');

      // Retrieve the GCash payment URL from the response
      final checkoutUrl = response['actions']['desktop_web_checkout_url'];
      log(checkoutUrl);

      // Convert the URL to a Uri object
      final Uri checkoutUri = Uri.parse(checkoutUrl);

      // Launch the GCash payment URL in the user's default browser
      if (await canLaunchUrl(checkoutUri)) {
        await launchUrl(checkoutUri);
      } else {
        throw 'Could not launch GCash payment URL';
      }
    } catch (e) {
      // Handle errors (e.g., show an error message)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffa7beae),
      appBar: AppBar(
        title: Text("Payment"),
        backgroundColor: Color(0xffF98866),
        elevation: 0.0,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _handleGCashPayment(context),
          child: Text('Pay with GCash'),
        ),
      ),
    );
  }
}
