// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../contants.dart';
import 'pay_with_saved_payment_method_fields.dart';

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

String? orderId;
String? customerId;

class PayWithSavedPaymentMethod extends StatelessWidget {
  const PayWithSavedPaymentMethod({Key? key}) : super(key: key);

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

      if (savedCustomerId == null) {
        //  Save the new customer id so we can reuse it later
        savedCustomerId = responseBody["customer_id"];
        await prefs.setString(
            "customerId-${Constants.token}", savedCustomerId!);
      }
      //  Update local tracker
      customerId = savedCustomerId;
    }

    return generatedOrderId;
  }

  Future<List<dynamic>> getSavedPaymentMethods() async {
    String authData = "${Constants.token}:${Constants.password}";
    String authString = "BASIC ${base64Encode(authData.codeUnits)}";

    String getPaymentMethodsUrl =
        "${Constants.baseUrl}/customers/$customerId/payment-methods";

    http.Response response = await http
        .get(Uri.parse(getPaymentMethodsUrl), headers: <String, String>{
      "Content-Type": "application/json; charset=UTF-8",
      "Accept": 'application/json; charset=UTF-8',
      "Authorization": authString
    });

    List<dynamic> paymentMethods = [];
    Map<String, dynamic> responseBody = jsonDecode(response.body);
    if (responseBody.containsKey("payment_methods")) {
      paymentMethods = responseBody["payment_methods"];
    }
    return paymentMethods;
  }

  Future<List<dynamic>> initData() async {
    String? generatedOrderId = await prepareOrder();

    if (generatedOrderId == null) {
      throw ("Error while preparing order");
    }

    orderId = generatedOrderId;
    List<dynamic> savedPaymentMethods = await getSavedPaymentMethods();
    return savedPaymentMethods;
  }

  Future<dynamic> getPaymentMethodDetails(dynamic savedPaymentMethod) async {
    String authData = "${Constants.token}:${Constants.password}";
    String authString = "BASIC ${base64Encode(authData.codeUnits)}";

    String getPaymentMethodsUrl =
        "${Constants.baseUrl}/payment-method-options?order_id=$orderId&country=${Constants.country}&saved_payment_method=true";

    http.Response response = await http
        .get(Uri.parse(getPaymentMethodsUrl), headers: <String, String>{
      "Content-Type": "application/json; charset=UTF-8",
      "Accept": 'application/json; charset=UTF-8',
      "Authorization": authString
    });

    dynamic paymentMethodDetails;
    List<dynamic> paymentMethods = [];
    Map<String, dynamic> responseBody = jsonDecode(response.body);
    if (responseBody.containsKey("payment_method_options")) {
      paymentMethods = responseBody["payment_method_options"];
      paymentMethodDetails = paymentMethods.firstWhere(
          (pm) => pm["rail_code"] == savedPaymentMethod["type"], orElse: () {
        return null;
      });

      if (paymentMethodDetails != null) {
        paymentMethodDetails["paymentMethodId"] = savedPaymentMethod["id"];
      }
    }

    return paymentMethodDetails;
  }

  void paymentMethodSelected(
      dynamic paymentMethod, BuildContext context) async {
    //  Get details about the saved payment method
    showProgressIndicator(context);
    dynamic paymentMethodDetails = await getPaymentMethodDetails(paymentMethod);
    hideProgressIndicator(context);
    if (paymentMethodDetails != null) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => PayWithSavedPaymentMethodFields(
                paymentMethod: paymentMethodDetails,
                orderId: orderId!,
              )));
    } else {
      showAlert(context,
          "An error has occurred while fetching payment method details");
    }
  }

  String sanitizePaymentMethod(Map<String, dynamic> paymentMethod) {
    String paymentMethodType = paymentMethod["type"];
    String retVal = paymentMethodType;
    if (paymentMethodType == "card" && paymentMethod.containsKey("card")) {
      Map<String, dynamic> cardDetails = paymentMethod["card"];
      String cardName = cardDetails["brand"];
      String last4 = cardDetails["last_4"];
      retVal = "$cardName - $last4";
    }
    return retVal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Saved Payment Methods'),
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
                      } else if (snapshot.data.length == 0) {
                        return const Center(
                            child: Text("No Payment Methods found.",
                                style: TextStyle(fontSize: 18)));
                      } else {
                        return ListView.builder(
                            itemCount: snapshot.data.length,
                            scrollDirection: Axis.vertical,
                            itemBuilder: (BuildContext context, int index) {
                              return Column(
                                children: [
                                  ListTile(
                                      title: Text(sanitizePaymentMethod(
                                          snapshot.data[index])),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () {
                                        paymentMethodSelected(
                                            snapshot.data[index], context);
                                      }),
                                  const Divider(
                                    height: 1,
                                    color: ThemeColors.borderColor,
                                  ), //
                                ],
                              ); // Handle your onTap here. );
                            });
                      }
                    }))));
  }
}
