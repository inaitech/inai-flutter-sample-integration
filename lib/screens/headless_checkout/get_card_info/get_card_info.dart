// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inai_flutter_sdk/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../contants.dart';

class ThemeColors {
  static const Color bgPurple = Color(0xff7673dd);
  static const Color borderColor = Color(0xff888888);
}

void debugPrint(String message) {
  if (kDebugMode) {
    print(message);
  }
}

String? orderId;
String cardNumber = '';
Image? cardBrandLogo;

typedef AlertFinishCallback = void Function();

void showAlert(BuildContext context, String message,
    {String title = "Alert", AlertFinishCallback? callback}) {
  // set up the button
  Widget okButton = TextButton(
    child: const Text("OK"),
    onPressed: () {
      Navigator.pop(context);
      if (callback != null) {
        callback();
      }
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: SingleChildScrollView(child: Text(message)),
    actions: [
      okButton,
    ],
  );

  // show the dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

void navigateBackToHome(BuildContext context) {
  Navigator.popUntil(context, (route) {
    if (route.isFirst) {
      return true;
    }
    return false;
  });
}

class GetCardInfo extends StatelessWidget {
  const GetCardInfo({Key? key}) : super(key: key);

  prepareOrder() async {
    String authData = "${Constants.token}:${Constants.password}";
    String authString = "BASIC ${base64Encode(authData.codeUnits)}";

    Map<String, String> customer = {};

    // Obtain shared preferences.
    SharedPreferences prefs = await SharedPreferences.getInstance();

    //  Do we have a saved customer id?
    String? savedCustomerId = prefs.getString("customerId-${Constants.token}");
    if (savedCustomerId != null) {
      //  Reuse the saved customer
      customer["id"] = savedCustomerId;
    } else {
      customer = {
        "email": "test@example.com",
        "contact_number": "01010101010",
        "first_name": "Smith",
        "last_name": "Doe"
      };
    }

    Map<String, dynamic> postdataJson = <String, dynamic>{
      "amount": Constants.amount,
      "currency": Constants.currency,
      "customer": customer,
      "metadata": {"test_order_id": "1234"}
    };

    String postdata = jsonEncode(postdataJson);

    String ordersURL = "${Constants.baseUrl}/orders";
    http.Response response = await http.post(
      Uri.parse(ordersURL),
      headers: <String, String>{
        "Content-Type": "application/json; charset=UTF-8",
        "Accept": 'application/json; charset=UTF-8',
        "Authorization": authString
      },
      body: postdata,
    );

    String? generatedOrderId;
    Map<String, dynamic> responseBody = jsonDecode(response.body);
    if (responseBody.containsKey("id")) {
      generatedOrderId = responseBody["id"];
      debugPrint(generatedOrderId!);

      if (savedCustomerId != null) {
        //  Save the new customer id so we can reuse it later
        String customerId = responseBody["customer_id"];
        await prefs.setString("customerId-${Constants.token}", customerId);
      }
    }

    return generatedOrderId;
  }

  Future<dynamic> inaiGetCardInfo(BuildContext context) async {
    try {
      InaiConfig config = InaiConfig(
          token: Constants.token,
          orderId: orderId,
          countryCode: Constants.country);

      InaiCheckout checkout = InaiCheckout(config);

      final result =
          await checkout.getCardInfo(cardNumber: cardNumber, context: context);

      return result;
    } catch (ex) {
      //  Handle configuration errors here
    }
    return null;
  }

  void submitPayment(BuildContext context) async {
    orderId = await prepareOrder();
    var result = await inaiGetCardInfo(context);

    String resultStr = result.data.toString();
    String resultTitle = "";
    switch (result.status) {
      case InaiStatus.success:
        resultTitle = "Payment Success! ";
        var data = result.data;
        if (data.card && data.card.brand) {
          loadCardBrandImage(data.card.brand.toLowerCase());
        }
        break;
      case InaiStatus.failed:
        resultTitle = "Payment Failed!";
        break;

      case InaiStatus.canceled:
        resultTitle = "Payment Canceled!";
        break;
    }

    showAlert(context, resultStr, title: resultTitle, callback: () {
      navigateBackToHome(context);
    });
  }

  void loadCardBrandImage(String cardBrand) {
    switch (cardBrand) {
      case "visa":
        cardBrandLogo = const Image(image: AssetImage('assets/visa.png'));
        break;
      default:
        cardBrandLogo =
            const Image(image: AssetImage('assets/unknown_card.png'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: const Text('Get Card Info'),
            backgroundColor: ThemeColors.bgPurple),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: TextField(
                onChanged: (text) {
                  cardNumber = text;
                },
                decoration: InputDecoration(
                    suffixIcon: cardBrandLogo,
                    border: const OutlineInputBorder(),
                    hintText: 'Card number'),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeColors.bgPurple,
                      minimumSize: const Size.fromHeight(50), // NEW
                    ),
                    onPressed: () {
                      if (cardNumber.length >= 6) {
                        /// Only process for 6 digits or above
                        submitPayment(context);
                      }
                    },
                    child: const Text(
                      "Checkout",
                      style: TextStyle(fontSize: 18),
                    ),
                  )),
            )
          ],
        ));
  }
}
