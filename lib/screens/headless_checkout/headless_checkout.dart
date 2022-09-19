import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'get_card_info/get_card_info.dart';
import 'save_payment_method/save_payment_method.dart';
import 'validate_fields/validate_fields.dart';
import '../product.dart';

class ThemeColors {
  static const Color bgPurple = Color(0xff7673dd);
}

// Add more flows here
const flows = {
  "MakePayment": "Make Payment",
  "SavePaymentMethod": "Save A Payment Method",
  "MakePaymentWithSavedMethod": "Pay With Saved Payment Method",
  "GetCardInfo": "Get Card Info",
  "ValidateFields": "Validate Fields"
};

class HeadlessCheckout extends StatelessWidget {
  const HeadlessCheckout({Key? key}) : super(key: key);

  void debugPrint(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Headless Checkout'),
          backgroundColor: ThemeColors.bgPurple,
        ),
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                      for (var key in flows.keys) FlowItem(flowItemKey: key)
                    ])))));
  }
}

class FlowItem extends StatelessWidget {
  const FlowItem({
    Key? key,
    required this.flowItemKey,
  }) : super(key: key);

  final String flowItemKey;

  void openFlow(String flowKey, BuildContext context) {
    switch (flowKey) {
      case "MakePayment":
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const Product(mode: "makePayment")));
        break;

      case "SavePaymentMethod":
        Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SavePaymentMethod()));
        break;

      case "MakePaymentWithSavedMethod":
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const Product(mode: "payWithSavedMethod")));
        break;

      case "GetCardInfo":
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => const GetCardInfo()));
        break;

      case "ValidateFields":
        Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ValidateFields()));
        break;
      //  Add more flows here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: ThemeColors.bgPurple,
          minimumSize: const Size.fromHeight(50), // NEW
        ),
        onPressed: () {
          openFlow(flowItemKey, context);
        },
        child: Text(
          flows[flowItemKey]!,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
