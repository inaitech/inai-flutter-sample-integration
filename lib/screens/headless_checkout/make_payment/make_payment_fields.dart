import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ThemeColors {
  static const Color bgPurple = Color(0xff7673dd);
}

class MakePaymentFields extends StatelessWidget {
  const MakePaymentFields({Key? key}) : super(key: key);

  void debugPrint(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  void showAlert(BuildContext context, String message,
      {String title = "Alert"}) {
    // set up the button
    Widget okButton = TextButton(
      child: const Text("OK"),
      onPressed: () {
        Navigator.pop(context);
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
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Payment'),
          backgroundColor: ThemeColors.bgPurple,
        ),
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary: ThemeColors.bgPurple,
                          minimumSize: const Size.fromHeight(50), // NEW
                        ),
                        onPressed: () {
                          showAlert(context, "Checkout WIP");
                        },
                        child: const Text(
                          "Checkout",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ])))));
  }
}
