import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/stripe_config.dart';


class StripeService {

  static const Map<String, String> _testTokens = {
    '4040402202001536' : 'tok_visa',
    '2000055556664488' : 'tok_visa_debit',
    '1234567000033344' : 'tok_mastercard',
    '2000124445550008' : 'tok_mastercard_debit',
    '5555777779992234' : 'tok_chargeDeclined',
    '4455566772233445' : 'tok_chargeDeclinedInsufficientFunds',
  };

  static Future <Map<String, dynamic>> processPayment({
    required double amount,
    required String cardNumber,
    required String expMonth,
    required String expYear,
    required String cvc,
}) async{
    final amountInCentavos = (amount * 100).round().toString();
    final cleanCard = cardNumber.replaceAll(' ', '');
    final token = _testTokens[cleanCard];

    if (token == null) {
      return <String, dynamic> {
        'success': false,
        'error': 'unknown test card',
      };
    }

    try {
      final response = await http.post(
        Uri.parse('${StripeConfig.apiUrl}/payment_intents'),
        headers: <String, String> {
          'Authorization': 'Bearer ${StripeConfig.secreteKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },

        body: <String, String> {
          'amount': amountInCentavos,
          'currency': 'php',
          'payment_method_types[]' : 'card',
          'payment_method_data[type]' : 'card',
          'payment_method_data[card][token]': token,
          'confirm': 'true',
        }
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if(response.statusCode == 200 && data ['status'] == 'succeeded') {
        return<String, dynamic> {
          'success': true,
          'id': data['id'].toString(),
          'amount':(data['amount'] as num) / 100,
          'status': data['status'].toString(),
        };
      } else {
        final errorMsg = data['error'] is Map
            ? (data['error'] as Map) ['message']?.toString()?? 'payment failed'
            : 'payment Failed';
        return <String, dynamic> {
          'success': false,
          'error': errorMsg
        };
      }

    } catch (e) {
      return <String, dynamic> {
        'success': false,
        'error': e.toString()
      };
    }
  }
}