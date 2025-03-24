import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kwc_app/services/auth.dart';

class XenditService {
  final AuthService _auth = AuthService();

  final String secretKey =
      'xnd_development_xer0UZD6kyTPKM77FRAq6gOURjRERROz3tK7uXqLBMVMbB4y2JOcS7OU9AaKkI6Y';

  //'xnd_production_8jE05Ni3ZQhv8RcRjagp3skH5Sto3HhCMO2YFB4Wl79ynd4MxDDjcZblHUvhq23'; // Replace with your Xendit secret key

  // Function to create a GCash charge
  Future<Map<String, dynamic>> createGCashCharge(
      int amount, String externalId) async {
    final url = 'https://api.xendit.co/ewallets/charges';
    final user = await _auth.user.first; // Stream from AuthService

    // Ensure correct Authorization header format
    final headers = {
      'Authorization': 'Basic ${base64Encode(utf8.encode('$secretKey:'))}',
      'Content-Type': 'application/json',
      'X-Callback-URL':
          'https://kwc.onrender.com/xendit/webhook' // Add callback URL in headers
    };

    final body = jsonEncode({
      "reference_id": externalId,
      "currency": "PHP",
      "amount": amount,
      "checkout_method": "ONE_TIME_PAYMENT",
      "channel_code": "PH_GCASH",
      "channel_properties": {
        "success_redirect_url": "https://kwc.onrender.com/payment-success",
        "failure_redirect_url": "https://kwc.onrender.com/payment-failure"
      },
      "metadata": {"userId": user?.uid}
    });

    final response =
        await http.post(Uri.parse(url), headers: headers, body: body);

    print(response.statusCode);

    if (response.statusCode == 200 ||
        (response.statusCode > 200 && response.statusCode < 300)) {
      print("Success Response: ${response.body}");
      return jsonDecode(response.body);
    } else {
      print("Error Response: ${response.body}");
      throw Exception('Failed to create GCash charge: ${response.body}');
    }
  }
}
