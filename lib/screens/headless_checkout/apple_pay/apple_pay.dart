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

String? orderId;
Map<String, dynamic>? applePayPaymentMethod;

class ApplePay extends StatelessWidget {
  const ApplePay({Key? key}) : super(key: key);

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
      "description": "Acme Antigravity Shoes",
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

  Future<InaiApplePayRequest> getApplePayPaymentMethod(String orderId) async {
    String authData = "${Constants.token}:${Constants.password}";
    String authString = "BASIC ${base64Encode(authData.codeUnits)}";

    String getPaymentMethodsUrl =
        "${Constants.baseUrl}/payment-method-options?order_id=$orderId&country=${Constants.country}";
    http.Response response = await http
        .get(Uri.parse(getPaymentMethodsUrl), headers: <String, String>{
      "Content-Type": "application/json; charset=UTF-8",
      "Accept": 'application/json; charset=UTF-8',
      "Authorization": authString
    });

    InaiApplePayRequest inaiApplePayRequest = InaiApplePayRequest();
    Map<String, dynamic> responseBody = jsonDecode(response.body);
    if (responseBody.containsKey("payment_method_options")) {
      var paymentMethods = responseBody["payment_method_options"];

      inaiApplePayRequest =
          await InaiCheckout.initApplePayRequest(paymentMethods);
    }

    return inaiApplePayRequest;
  }

  Future<dynamic> initData() async {
    String? generatedOrderId = await prepareOrder();

    if (generatedOrderId == null) {
      throw ("Error while preparing order");
    }

    orderId = generatedOrderId;
    dynamic applePayPaymentMethod =
        await getApplePayPaymentMethod(generatedOrderId);
    return applePayPaymentMethod;
  }

  void navigateBackToHome(BuildContext context) {
    Navigator.popUntil(context, (route) {
      return route.isFirst;
    });
  }

  void showResult(BuildContext context, InaiResult result) {
    String resultStr = result.data.toString();
    debugPrint(resultStr);
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

    // ignore: use_build_context_synchronously
    showAlert(context, resultStr, title: resultTitle, callback: () {
      //  navigateBackToHome(context);
    });
  }

  Future<void> submitApplePay(
      InaiApplePayRequest inaiApplePayRequest, BuildContext context) async {
    try {
      InaiConfig config = InaiConfig(
          token: Constants.token,
          orderId: orderId,
          countryCode: Constants.country);

      debugPrint("Init SDK");
      var inaiCheckout = InaiCheckout(config);
      InaiResult result =
          await inaiCheckout.makePaymentApplePay(inaiApplePayRequest, context);
      showResult(context, result);
    } catch (ex) {
      //  Handle configuration errors here
      showAlert(context, "Error ${ex.toString()}");
    }
  }

  String sanitizeRailCode(String railCode) {
    String cleanStr = railCode.replaceAll("_", " ");
    String capitalizedStr =
        "${cleanStr[0].toUpperCase()}${cleanStr.substring(1).toLowerCase()}";

    return capitalizedStr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Apple Pay'),
          backgroundColor: ThemeColors.bgPurple,
        ),
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: FutureBuilder(
                    future: initData(),
                    builder: (context, AsyncSnapshot snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                            child: Text(
                                style: const TextStyle(fontSize: 18),
                                "Data load error. ${snapshot.error.toString()}")); //Center
                      } else if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: ThemeColors.bgPurple));
                      } else if ((snapshot.data as InaiApplePayRequest)
                              .userCanPay ==
                          false) {
                        return const Center(
                            child: Text("Apple Pay not available.",
                                style: TextStyle(fontSize: 18)));
                      } else {
                        return Center(
                          child: TextButton(
                              style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(
                                      ThemeColors.bgPurple)),
                              onPressed: () =>
                                  {submitApplePay(snapshot.data, context)},
                              child: const Text(
                                "Pay with Apple Pay",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16.0),
                              )),
                        );
                      }
                    }))));
  }
}
