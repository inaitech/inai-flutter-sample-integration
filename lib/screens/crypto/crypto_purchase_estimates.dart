import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_sample_integration/contants.dart';
import 'package:inai_flutter_sdk/inai_flutter_sdk.dart';

class ThemeColors {
  static const Color bgPurple = Color(0xff7673dd);
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

class CryptoPurchaseEstimates extends StatelessWidget {
  const CryptoPurchaseEstimates({super.key});

  void getPurchaseEstimates(BuildContext  context) async {
    try {
      InaiCryptoPurchaseDetails purchaseDetails = InaiCryptoPurchaseDetails(
          token: Constants.token,
          cryptoCurrency: Constants.cryptoCurrency,
          amount: Constants.amount,
          countryCode: Constants.country,
          currency: Constants.currency,
          paymentMethodOption: Constants.paymentMethodOption);

      final result = await InaiCrypto.getPurchaseEstimate(
          cryptoPurchaseDetails: purchaseDetails, context: context);
      String resultStr = "";
      switch (result.status) {
        case InaiStatus.success:
          resultStr = "Payment Success! ${jsonEncode(result.data)}";
          break;
        case InaiStatus.failed:
          resultStr = "Payment Failed with data: ${jsonEncode(result.data)}";
          break;
        case InaiStatus.canceled:
          resultStr = "${result.data["message"] ?? "Payment Canceled!"}";
          break;
      }

      showAlert(context, resultStr);
    } catch (ex) {
      showAlert(context, "Exception $ex.message");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          backgroundColor: ThemeColors.bgPurple,
        ),
        body: SafeArea(
            child: Align(
          alignment: Alignment.center,
          child: ElevatedButton(
            style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                backgroundColor: MaterialStateProperty.all(ThemeColors.bgPurple)),
            onPressed: () {
              getPurchaseEstimates(context);
            },
            child: const Text('Get Purchase Estimates'),
          ),
        )));
  }
}
