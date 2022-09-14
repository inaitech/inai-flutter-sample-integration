// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:inai_flutter_sdk/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../contants.dart';

class ThemeColors {
  static const Color bgPurple = Color(0xff7673dd);
}

void hideProgressIndicator(BuildContext context) {
  Navigator.pop(context);
}

void showProgressIndicator(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Center(
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [Center(child: CircularProgressIndicator())]),
      );
    },
  );
}

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
    return route.isFirst;
  });
}

class ProductDropIn extends StatelessWidget {
  const ProductDropIn({Key? key}) : super(key: key);

  void debugPrint(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  Future<String?> prepareOrder() async {
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
      if (savedCustomerId != null) {
        //  Save the new customer id so we can reuse it later
        String customerId = responseBody["customer_id"];
        await prefs.setString("customerId-${Constants.token}", customerId);
      }
    }

    return generatedOrderId;
  }

  Future<dynamic> inaiPresentCheckout(
      BuildContext context, String orderId) async {
    try {
      InaiConfig config = InaiConfig(
          token: Constants.token,
          orderId: orderId,
          countryCode: Constants.country);

      InaiCheckout checkout = InaiCheckout(config);

      final result = await checkout.presentCheckout(context: context);

      return result;
    } catch (ex) {
      //  Handle configuration errors here
      debugPrint("Initialization Error$ex");
    }
    return null;
  }

  void dropInCheckout(BuildContext context) async {
    showProgressIndicator(context);
    //  Generate order id only once
    //  Same order id can be reused for dropInCheckout.
    String? orderId = await prepareOrder();
    hideProgressIndicator(context);
    InaiResult result = await inaiPresentCheckout(context, orderId!);
    String resultStr = result.data.toString();
    String resultTitle = "";
    switch (result.status) {
      case InaiStatus.success:
        resultTitle = "Payment Success! ";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product'),
        backgroundColor: ThemeColors.bgPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 15.0),
              child: const Image(
                image: AssetImage('assets/inai-white.png'),
                height: 50,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 15.0),
              height: 200,
              child: const Image(
                image: AssetImage('assets/tshirt.jpeg'),
              ),
            ),
            Container(
                margin: const EdgeInsets.only(top: 15.0),
                height: 20,
                child: const Text("MANCHESTER UNITED 21/22 HOME JERSEY")),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 15.0),
                child: const SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Text('''A FAN JERSEY INSPIRED BY A LEGENDARY HOME KIT.
Youth. Courage. Success. The thee pillars of Manchester United's motto have brought the club more than a century of triumphs. With its clean red design and white ribbed crewneck, this juniors' adidas football jersey takes inspiration from the iconic kit that carried them to some of their most memorable moments. Made for fans, its soft fabric and moisture-absorbing AEROREADY keep you comfortable. A devil signoff on the back shows your pride.
This product is made with Primegreen, a series of high-performance recycled materials.'''),
                ),
              ),
            ),
            Container(
              height: 40,
              margin: const EdgeInsets.only(top: 15.0, bottom: 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: ThemeColors.bgPurple,
                  minimumSize: const Size.fromHeight(50), // NEW
                ),
                onPressed: () {
                  dropInCheckout(context);
                },
                child: const Text('Buy Now', style: TextStyle(fontSize: 18)),
              ),
            )
          ],
        )),
      ),
    );
  }
}
