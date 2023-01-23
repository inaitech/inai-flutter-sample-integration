// ignore_for_file: use_build_context_synchronously

import 'dart:async';
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

class Debounce {
  Duration delay;
  Timer? _timer;

  Debounce(
    this.delay,
  );

  call(void Function() callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  dispose() {
    _timer?.cancel();
  }
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

class GetCardInfo extends StatefulWidget {
  const GetCardInfo({Key? key}) : super(key: key);

  @override
  State<GetCardInfo> createState() => _GetCardInfoState();
}

class _GetCardInfoState extends State<GetCardInfo> {
  final Debounce _debounce = Debounce(const Duration(milliseconds: 200));

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

  void getCardInfo(BuildContext context, {bool showResult = false}) async {
    // Only process for 6 digits or above
    if (cardNumber.length < 6) {
      return;
    }

    if (showResult) {
      showProgressIndicator(context);
    }

    //  Generate order id only once
    //  Same order id can be reused for getCardInfo
    orderId ??= await prepareOrder();

    InaiResult result = await inaiGetCardInfo(context);
    String resultStr = result.data.toString();
    String resultTitle = "";
    switch (result.status) {
      case InaiStatus.success:
        resultTitle = "Get Card Info Success";
        Map<String, dynamic> data = result.data;

        if (data.containsKey("card")) {
          Map<String, dynamic> card = data["card"];
          if (card.containsKey("brand")) {
            loadCardBrandImage(card["brand"].toString().toLowerCase());
          }
        }
        break;
      default:
        resultTitle = "Get Card Info Failed!";
        break;
    }

    if (showResult) {
      hideProgressIndicator(context);

      showAlert(context, resultStr, title: resultTitle);
    }
  }

  void loadCardBrandImage(String cardBrand) {
    cardBrand = cardBrand.replaceAll(RegExp(r'[^\w\s]+'), '');

    String cardImage = "unknown_card.png";
    if (["americanexpress", "discover", "mastercard", "visa"]
        .contains(cardBrand)) {
      cardImage = "$cardBrand.png";
    }

    setState(() {
      cardBrandLogo = Image(image: AssetImage("assets/$cardImage"));
    });
  }

  @override
  void initState() {
    cardBrandLogo = null;
    cardNumber = "";
    super.initState();
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
                  _debounce(() {
                    if (cardNumber.length >= 6) {
                      getCardInfo(context);
                    } else {
                      setState(() {
                        cardBrandLogo = null;
                      });
                    }
                  });
                },
                decoration: InputDecoration(
                    suffixIconConstraints:
                        const BoxConstraints(maxHeight: 40, maxWidth: 60),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: cardBrandLogo,
                    ),
                    contentPadding: const EdgeInsets.only(left: 10, right: 10),
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
                      primary: ThemeColors.bgPurple,
                      minimumSize: const Size.fromHeight(50), // NEW
                    ),
                    onPressed: () {
                      getCardInfo(context, showResult: true);
                    },
                    child: const Text(
                      "Get Card Info",
                      style: TextStyle(fontSize: 18),
                    ),
                  )),
            )
          ],
        ));
  }
}
