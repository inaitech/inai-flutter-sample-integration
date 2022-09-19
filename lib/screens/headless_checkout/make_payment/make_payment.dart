import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../contants.dart';
import 'make_payment_fields.dart';

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

class MakePayment extends StatelessWidget {
  const MakePayment({Key? key}) : super(key: key);

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

  Future<List<dynamic>> getPaymentMethods(String orderId) async {
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

    List<dynamic> paymentMethods = [];
    Map<String, dynamic> responseBody = jsonDecode(response.body);
    if (responseBody.containsKey("payment_method_options")) {
      paymentMethods = responseBody["payment_method_options"];
    }
    return paymentMethods;
  }

  Future<List<dynamic>> initData() async {
    String? generatedOrderId = await prepareOrder();

    if (generatedOrderId == null) {
      throw ("Error while preparing order");
    }

    orderId = generatedOrderId;
    List<dynamic> paymentMethods = await getPaymentMethods(generatedOrderId);
    return paymentMethods;
  }

  void openPaymentMethodFields(dynamic paymentMethod, BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => MakePaymentFields(
              paymentMethod: paymentMethod,
              orderId: orderId!,
            )));
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
          title: const Text('Payment Methods'),
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
                                      title: Text(sanitizeRailCode(
                                          snapshot.data[index]["rail_code"])),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () {
                                        openPaymentMethodFields(
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
