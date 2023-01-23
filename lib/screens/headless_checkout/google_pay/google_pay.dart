import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inai_flutter_sdk/main.dart';
import 'package:pay/pay.dart';
import '../../../contants.dart';

class ThemeColors {
  static const Color bgPurple = Color(0xff7673dd);
  static const Color errorRed = Colors.red;
  static const Color normal = Colors.grey;
}

typedef AlertFinishCallback = void Function();

void showAlert(BuildContext context, String message, {String title = "Alert", AlertFinishCallback? callback}) {
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

class GooglePay extends StatelessWidget {
  GooglePay({Key? key, this.paymentMethod, required this.orderId}) : super(key: key);

  final dynamic paymentMethod;
  final String orderId;
  InaiGooglePayRequestData? googlePayRequestData;

  String sanitizeRailCode(String railCode) {
    String cleanStr = railCode.replaceAll("_", " ");
    String capitalizedStr = "${cleanStr[0].toUpperCase()}${cleanStr.substring(1).toLowerCase()}";

    return capitalizedStr;
  }

  InaiCheckout getCheckout() {
    InaiConfig config = InaiConfig(token: Constants.token, orderId: orderId, countryCode: Constants.country);

    return InaiCheckout(config);
  }

  void onGooglePayPressed(BuildContext context) async {
    final googlePayResult = await googlePayRequestData?.payClient?.showPaymentSelector(
      provider: PayProvider.google_pay,
      paymentItems: googlePayRequestData!.paymentItems,
    );
    if (googlePayResult != null) {
      var checkout = getCheckout();
      var paymentDetails = checkout.getGooglePayRequestData(googlePayResult);
      InaiResult result =
          await checkout.makePayment(paymentMethodOption: "google_pay", context: context, paymentDetails: paymentDetails);
      showResult(context, result);
    }
  }

  void showResult(BuildContext context, InaiResult result) {
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

    // ignore: use_build_context_synchronously
    showAlert(context, resultStr, title: resultTitle, callback: () {
      navigateBackToHome(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("${sanitizeRailCode(paymentMethod["rail_code"])} Payment"),
          backgroundColor: ThemeColors.bgPurple,
        ),
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    FutureBuilder<InaiGooglePayRequestData>(
                        future: getCheckout().initGooglePlay(paymentMethod, GooglePayEnvironment.TEST),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                                child: Text(
                                    style: const TextStyle(fontSize: 18), "Data load error. ${snapshot.error.toString()}"));
                          } else if (!snapshot.hasData) {
                            return Center(
                                child: Text(
                                    style: const TextStyle(fontSize: 18), "Data load error. ${snapshot.error.toString()}"));
                          } else if (!(snapshot.data?.userCanPay ?? false)) {
                            return const Center(child: Text(style: TextStyle(fontSize: 18), "Google Pay Not Available"));
                          } else {
                            googlePayRequestData = snapshot.data;
                            return TextButton(
                                style: ButtonStyle(backgroundColor: MaterialStateProperty.all(ThemeColors.bgPurple)),
                                onPressed: () => {onGooglePayPressed(context)},
                                child: const Text(
                                  "Pay with Google Pay",
                                  style: TextStyle(color: Colors.white, fontSize: 16.0),
                                ));
                          }
                        })
                  ],
                ))));
  }
}
